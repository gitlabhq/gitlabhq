# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::GithubImport::BulkImporting do
  let(:project) { instance_double(Project, id: 1) }
  let(:importer) { MyImporter.new(project, double) }
  let(:importer_class) do
    Class.new do
      include Gitlab::GithubImport::BulkImporting

      def object_type
        :object_type
      end
    end
  end

  before do
    stub_const 'MyImporter', importer_class
  end

  describe '#build_database_rows' do
    it 'returns an Array containing the rows to insert' do
      object = double(:object, title: 'Foo')

      expect(importer)
        .to receive(:build)
        .with(object)
        .and_return({ title: 'Foo' })

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

      expect(importer.build_database_rows(enum)).to eq([{ title: 'Foo' }])
    end

    it 'does not import objects that have already been imported' do
      object = double(:object, title: 'Foo')

      expect(importer)
        .not_to receive(:build)

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

      expect(importer.build_database_rows(enum)).to be_empty
    end
  end

  describe '#bulk_insert' do
    it 'bulk inserts rows into the database' do
      rows = [{ title: 'Foo' }] * 10
      model = double(:model, table_name: 'kittens')

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

      expect(Gitlab::Database.main)
        .to receive(:bulk_insert)
        .ordered
        .with('kittens', rows.first(5))

      expect(Gitlab::Database.main)
        .to receive(:bulk_insert)
        .ordered
        .with('kittens', rows.last(5))

      importer.bulk_insert(model, rows, batch_size: 5)
    end
  end
end
