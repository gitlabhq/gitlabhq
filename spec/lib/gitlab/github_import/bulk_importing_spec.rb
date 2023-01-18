# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::GithubImport::BulkImporting, feature_category: :importers do
  let(:project) { instance_double(Project, id: 1) }
  let(:importer) { MyImporter.new(project, double) }
  let(:importer_class) do
    Class.new do
      include Gitlab::GithubImport::BulkImporting

      def object_type
        :object_type
      end

      def model
        Label
      end
    end
  end

  let(:label) { instance_double('Label', invalid?: false) }

  before do
    stub_const 'MyImporter', importer_class
  end

  describe '#build_database_rows' do
    it 'returns an Array containing the rows to insert and validation errors if object invalid' do
      object = double(:object, title: 'Foo')

      expect(importer)
        .to receive(:build_attributes)
        .with(object)
        .and_return({ title: 'Foo' })

      expect(Label)
        .to receive(:new)
        .with({ title: 'Foo' })
        .and_return(label)

      expect(importer)
        .to receive(:already_imported?)
        .with(object)
        .and_return(false)

      expect(Gitlab::Import::Logger)
        .to receive(:info)
        .with(
          import_type: :github,
          project_id: 1,
          importer: 'MyImporter',
          message: '1 object_types fetched'
        )

      expect(Gitlab::GithubImport::ObjectCounter)
        .to receive(:increment)
        .with(
          project,
          :object_type,
          :fetched,
          value: 1
        )

      enum = [[object, 1]].to_enum

      rows, errors = importer.build_database_rows(enum)

      expect(rows).to match_array([{ title: 'Foo' }])
      expect(errors).to be_empty
    end

    it 'does not import objects that have already been imported' do
      object = double(:object, title: 'Foo')

      expect(importer)
        .not_to receive(:build_attributes)

      expect(importer)
        .to receive(:already_imported?)
        .with(object)
        .and_return(true)

      expect(Gitlab::Import::Logger)
        .to receive(:info)
        .with(
          import_type: :github,
          project_id: 1,
          importer: 'MyImporter',
          message: '0 object_types fetched'
        )

      expect(Gitlab::GithubImport::ObjectCounter)
        .to receive(:increment)
        .with(
          project,
          :object_type,
          :fetched,
          value: 0
        )

      enum = [[object, 1]].to_enum

      rows, errors = importer.build_database_rows(enum)

      expect(rows).to be_empty
      expect(errors).to be_empty
    end
  end

  describe '#bulk_insert' do
    it 'bulk inserts rows into the database' do
      rows = [{ title: 'Foo' }] * 10

      expect(Gitlab::Import::Logger)
        .to receive(:info)
        .twice
        .with(
          import_type: :github,
          project_id: 1,
          importer: 'MyImporter',
          message: '5 object_types imported'
        )

      expect(Gitlab::GithubImport::ObjectCounter)
        .to receive(:increment)
        .twice
        .with(
          project,
          :object_type,
          :imported,
          value: 5
        )

      expect(ApplicationRecord)
        .to receive(:legacy_bulk_insert)
        .ordered
        .with('labels', rows.first(5))

      expect(ApplicationRecord)
        .to receive(:legacy_bulk_insert)
        .ordered
        .with('labels', rows.last(5))

      importer.bulk_insert(rows, batch_size: 5)
    end
  end

  describe '#bulk_insert_failures', :timecop do
    let(:import_failures) { instance_double('ImportFailure::ActiveRecord_Associations_CollectionProxy') }
    let(:label) { Label.new(title: 'invalid,title') }
    let(:validation_errors) { ActiveModel::Errors.new(label) }
    let(:formatted_errors) do
      [{
        source: 'MyImporter',
        exception_class: 'ActiveRecord::RecordInvalid',
        exception_message: 'Title invalid',
        correlation_id_value: 'cid',
        retry_count: nil,
        created_at: Time.zone.now
      }]
    end

    it 'bulk inserts validation errors into import_failures' do
      error = ActiveModel::Errors.new(label)
      error.add(:base, 'Title invalid')

      freeze_time do
        expect(project).to receive(:import_failures).and_return(import_failures)
        expect(import_failures).to receive(:insert_all).with(formatted_errors)
        expect(Labkit::Correlation::CorrelationId).to receive(:current_or_new_id).and_return('cid')

        importer.bulk_insert_failures([error])
      end
    end
  end
end
