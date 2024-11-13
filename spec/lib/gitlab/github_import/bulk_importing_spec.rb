# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::GithubImport::BulkImporting, feature_category: :importers do
  let_it_be(:project) { create(:project, :with_import_url) }
  let(:importer) { MyImporter.new(project, double) }
  let(:importer_class) do
    Class.new do
      include Gitlab::GithubImport::BulkImporting

      def object_type
        :object_type
      end

      private

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
    context 'without validation errors' do
      let(:object) { double(:object, title: 'Foo') }

      it 'returns an array containing the rows to insert' do
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

        expect(Gitlab::GithubImport::Logger)
          .to receive(:info)
          .with(
            project_id: project.id,
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
        expect(importer)
          .not_to receive(:build_attributes)

        expect(importer)
          .to receive(:already_imported?)
          .with(object)
          .and_return(true)

        expect(Gitlab::GithubImport::Logger)
          .to receive(:info)
          .with(
            project_id: project.id,
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

    context 'with validation errors' do
      let(:object) { double(:object, id: 12345, title: 'bug,bug') }

      before do
        allow(importer)
          .to receive(:already_imported?)
          .with(object)
          .and_return(false)

        allow(importer)
          .to receive(:build_attributes)
          .with(object)
          .and_return({ title: 'bug,bug' })
      end

      context 'without implemented github_identifiers method' do
        it 'raises NotImplementedError' do
          enum = [[object, 1]].to_enum

          expect { importer.build_database_rows(enum) }.to raise_error(NotImplementedError)
        end
      end

      context 'with implemented github_identifiers method' do
        it 'returns an array containing the validation errors and logs them' do
          expect(importer)
            .to receive(:github_identifiers)
            .with(object)
            .and_return(
              {
                id: object.id,
                title: object.title,
                object_type: importer.object_type
              }
            )

          expect(Gitlab::GithubImport::Logger)
            .to receive(:error)
            .with(
              project_id: project.id,
              importer: 'MyImporter',
              message: ['Title is invalid'],
              external_identifiers: { id: 12345, title: 'bug,bug', object_type: :object_type }
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
          expect(errors).not_to be_empty

          expect(errors[0][:validation_errors].full_messages).to match_array(['Title is invalid'])
          expect(errors[0][:external_identifiers]).to eq({ id: 12345, title: 'bug,bug', object_type: :object_type })
        end
      end
    end
  end

  describe '#bulk_insert' do
    context 'when user mapping is enabled' do
      before do
        project.build_or_assign_import_data(data: { user_contribution_mapping_enabled: true })
      end

      it 'bulk inserts rows into the database' do
        rows = [{ title: 'Foo' }] * 10

        expect(Gitlab::GithubImport::Logger)
          .to receive(:info)
          .twice
          .with(
            project_id: project.id,
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
          .with('labels', rows.first(5), return_ids: true)
          .and_return([1, 2, 3])

        expect(ApplicationRecord)
          .to receive(:legacy_bulk_insert)
          .ordered
          .with('labels', rows.last(5), return_ids: true)
          .and_return([4, 5, 6])

        importer.bulk_insert(rows, batch_size: 5)
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
            created_at: anything,
            external_identifiers: { id: 123456 }
          }]
        end

        it 'bulk inserts validation errors into import_failures' do
          error = ActiveModel::Errors.new(label)
          error.add(:base, 'Title invalid')

          expect(project).to receive(:import_failures).and_return(import_failures)
          expect(import_failures).to receive(:insert_all).with(formatted_errors)
          expect(Labkit::Correlation::CorrelationId).to receive(:current_or_new_id).and_return('cid')

          importer.bulk_insert_failures([{
            validation_errors: error,
            external_identifiers: { id: 123456 }
          }])
        end
      end
    end

    context 'when user mapping is disabled' do
      before do
        project.build_or_assign_import_data(data: { user_contribution_mapping_enabled: false })
      end

      it 'bulk inserts rows into the database' do
        rows = [{ title: 'Foo' }] * 10

        expect(Gitlab::GithubImport::Logger)
          .to receive(:info)
          .twice
          .with(
            project_id: project.id,
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
          .with('labels', rows.first(5), return_ids: true)
          .and_return([1, 2, 3])

        expect(ApplicationRecord)
          .to receive(:legacy_bulk_insert)
          .ordered
          .with('labels', rows.last(5), return_ids: true)
          .and_return([4, 5, 6])

        importer.bulk_insert(rows, batch_size: 5)
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
            created_at: Time.zone.now,
            external_identifiers: { id: 123456 }
          }]
        end

        it 'bulk inserts validation errors into import_failures' do
          error = ActiveModel::Errors.new(label)
          error.add(:base, 'Title invalid')

          freeze_time do
            expect(project).to receive(:import_failures).and_return(import_failures)
            expect(import_failures).to receive(:insert_all).with(formatted_errors)
            expect(Labkit::Correlation::CorrelationId).to receive(:current_or_new_id).and_return('cid')

            importer.bulk_insert_failures([{
              validation_errors: error,
              external_identifiers: { id: 123456 }
            }])
          end
        end
      end
    end
  end

  describe '#object_type' do
    let(:importer_class) do
      Class.new do
        include Gitlab::GithubImport::BulkImporting
      end
    end

    it 'raises NotImplementedError' do
      expect { importer.object_type }.to raise_error(NotImplementedError)
    end
  end
end
