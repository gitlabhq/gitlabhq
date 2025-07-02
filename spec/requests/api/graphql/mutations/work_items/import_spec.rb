# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Import work items', feature_category: :team_planning do
  include GraphqlHelpers
  include WorkhorseHelpers

  let_it_be(:project) { create(:project) }
  let_it_be(:reporter) { create(:user, reporter_of: project) }
  let_it_be(:guest) { create(:user, guest_of: project) }

  let(:file) { fixture_file_upload('spec/fixtures/work_items_valid.csv') }
  let(:input) { { 'projectPath' => project.full_path, 'file' => file } }
  let(:mutation) { graphql_mutation(:workItemsCsvImport, input) }
  let(:mutation_response) { graphql_mutation_response(:work_items_csv_import) }

  context 'when user is not allowed to import work items' do
    let(:current_user) { guest }

    it 'returns access denied error' do
      post_graphql_mutation_with_uploads(mutation, current_user: current_user)

      expect(graphql_errors).to be_present
      error_messages = graphql_errors.pluck('message')
      expect(error_messages).to include(
        match(/The resource that you are attempting to access does not exist or you don't have permission/)
      )
    end

    context 'when import_export_work_items_csv feature flag is disabled' do
      let(:current_user) { reporter }

      before do
        stub_feature_flags(import_export_work_items_csv: false)
      end

      it 'returns feature flag disabled error' do
        post_graphql_mutation_with_uploads(mutation, current_user: current_user)

        expect(graphql_errors).to be_present
        error_messages = graphql_errors.pluck('message')
        expect(error_messages).to include(
          match(/import_export_work_items_csv.*feature flag is disabled/)
        )
      end
    end
  end

  context 'when user has permissions to import work items' do
    let(:current_user) { reporter }

    context 'with valid CSV file' do
      it 'schedules import job with success message and correct parameters', :aggregate_failures do
        expect(WorkItems::PrepareImportCsvService).to receive(:new) do |received_project, received_user, options|
          expect(received_project).to eq(project)
          expect(received_user).to eq(reporter)

          uploaded_file = options[:file]
          expect(uploaded_file).to be_present
          expect(uploaded_file).to respond_to(:original_filename)
          expect(uploaded_file.original_filename).to eq('work_items_valid.csv')

          instance_double(WorkItems::PrepareImportCsvService).tap do |service_double|
            allow(service_double).to receive(:execute).and_return(ServiceResponse.success(message: 'Import started'))
          end
        end

        post_graphql_mutation_with_uploads(mutation, current_user: current_user)

        expect(mutation_response['message']).to eq('Import started')
        expect(mutation_response['errors']).to be_empty
      end
    end

    context 'with file validation' do
      shared_examples 'rejects invalid file with error message' do
        it 'rejects file with proper error message' do
          post_graphql_mutation_with_uploads(mutation, current_user: current_user)

          expect(mutation_response['message']).to be_nil
          expect(mutation_response['errors']).to eq(
            ['The uploaded file was invalid. Supported file extensions are .csv.']
          )
        end

        it 'does not call the import service' do
          expect(WorkItems::PrepareImportCsvService).not_to receive(:new)
          post_graphql_mutation_with_uploads(mutation, current_user: current_user)
        end
      end

      context 'with image file' do
        let(:file) { fixture_file_upload('spec/fixtures/dk.png') }

        it_behaves_like 'rejects invalid file with error message'
      end

      context 'with PDF file' do
        let(:file) { fixture_file_upload('spec/fixtures/sample.pdf') }

        it_behaves_like 'rejects invalid file with error message'
      end

      context 'with JSON file' do
        let(:file) { fixture_file_upload('spec/fixtures/service_account.json') }

        it_behaves_like 'rejects invalid file with error message'
      end

      context 'with XML file' do
        let(:file) { fixture_file_upload('spec/fixtures/unsafe_javascript.xml') }

        it_behaves_like 'rejects invalid file with error message'
      end

      context 'with markdown file' do
        let(:file) { fixture_file_upload('spec/fixtures/sample_doc.md') }

        it_behaves_like 'rejects invalid file with error message'
      end
    end

    context 'when import service returns error' do
      it 'returns error message and verifies service parameters', :aggregate_failures do
        expect(WorkItems::PrepareImportCsvService).to receive(:new) do |received_project, received_user, options|
          expect(received_project).to eq(project)
          expect(received_user).to eq(reporter)

          # Verify the file is passed and has the correct properties
          uploaded_file = options[:file]
          expect(uploaded_file).to be_present
          expect(uploaded_file).to respond_to(:original_filename)
          expect(uploaded_file.original_filename).to eq('work_items_valid.csv')

          # Create a double that returns an error response
          instance_double(WorkItems::PrepareImportCsvService).tap do |service_double|
            allow(service_double).to receive(:execute).and_return(ServiceResponse.error(message: 'Invalid file format'))
          end
        end

        post_graphql_mutation_with_uploads(mutation, current_user: current_user)

        expect(mutation_response['message']).to be_nil
        expect(mutation_response['errors']).to eq(['Invalid file format'])
      end
    end

    context 'when verifying file content is processed' do
      it 'ensures the uploaded file is accessible to the service' do
        expect(File.exist?('spec/fixtures/work_items_valid.csv')).to be true
        file_content = File.read('spec/fixtures/work_items_valid.csv')
        expect(file_content).to include('title,type')
        expect(file_content).to include('Issue')

        expect(WorkItems::PrepareImportCsvService).to receive(:new) do |_received_project, _received_user, options|
          uploaded_file = options[:file]
          expect(uploaded_file).to be_present
          expect(uploaded_file.original_filename).to eq('work_items_valid.csv')

          file_content = if uploaded_file.respond_to?(:tempfile)
                           uploaded_file.tempfile.rewind
                           uploaded_file.tempfile.read
                         else
                           uploaded_file.read
                         end

          expect(file_content).to include('title,type')
          expect(file_content).to include('Issue')

          instance_double(WorkItems::PrepareImportCsvService).tap do |service_double|
            allow(service_double).to receive(:execute).and_return(ServiceResponse.success(message: 'Import started'))
          end
        end

        post_graphql_mutation_with_uploads(mutation, current_user: current_user)

        expect(mutation_response['message']).to eq('Import started')
        expect(mutation_response['errors']).to be_empty
      end
    end
  end
end
