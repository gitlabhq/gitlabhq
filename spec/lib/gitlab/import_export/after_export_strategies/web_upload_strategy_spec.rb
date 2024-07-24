# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::ImportExport::AfterExportStrategies::WebUploadStrategy do
  include StubRequests

  before do
    allow_next_instance_of(ProjectExportWorker) do |job|
      allow(job).to receive(:jid).and_return(SecureRandom.hex(8))
    end
    stub_uploads_object_storage(FileUploader, enabled: false)
  end

  let(:example_url) { 'http://www.example.com' }
  let(:strategy) { subject.new(url: example_url, http_method: 'post') }
  let(:user) { build(:user) }
  let(:project) { create(:project, creator: user) }
  let!(:import_export_upload) do
    create(
      :import_export_upload,
      project: project,
      user: user,
      export_file: fixture_file_upload('spec/fixtures/gitlab/import_export/lightweight_project_export.tar.gz')
    )
  end

  subject { described_class }

  describe 'validations' do
    it 'only POST and PUT method allowed' do
      %w[POST post PUT put].each do |method|
        expect(subject.new(url: example_url, http_method: method)).to be_valid
      end

      expect(subject.new(url: example_url, http_method: 'whatever')).not_to be_valid
    end

    it 'only allow urls as upload urls' do
      expect(subject.new(url: example_url)).to be_valid
      expect(subject.new(url: 'whatever')).not_to be_valid
    end
  end

  describe '#execute' do
    context 'when upload succeeds' do
      before do
        stub_full_request(example_url, method: :post).to_return(status: 200)
      end

      it 'does not remove the exported project file after the upload', :aggregate_failures do
        expect(project).not_to receive(:remove_exports_for_user)

        expect { strategy.execute(user, project) }.not_to change { project.export_status(user) }

        expect(project.export_status(user)).to eq(:finished)
      end

      it 'logs when upload starts and finishes' do
        export_size = import_export_upload.export_file.size

        expect_next_instance_of(Gitlab::Export::Logger) do |logger|
          expect(logger).to receive(:info).ordered.with(
            {
              message: "Started uploading project",
              project_id: project.id,
              project_name: project.name,
              export_size: export_size
            }
          )

          expect(logger).to receive(:info).ordered.with(
            {
              message: "Finished uploading project",
              project_id: project.id,
              project_name: project.name,
              export_size: export_size,
              upload_duration: anything
            }
          )
        end

        strategy.execute(user, project)
      end
    end

    context 'when upload fails' do
      it 'stores the export error' do
        stub_full_request(example_url, method: :post).to_return(status: [404, 'Page not found'])

        strategy.execute(user, project)

        errors = project.import_export_shared.errors
        expect(errors).not_to be_empty
        expect(errors.first).to eq "Error uploading the project. Code 404: Page not found"
      end
    end

    context 'when object store is disabled' do
      it 'reads file from disk and uploads to external url' do
        stub_request(:post, example_url).to_return(status: 200)
        expect(Gitlab::ImportExport::RemoteStreamUpload).not_to receive(:new)
        expect(Gitlab::HttpIO).not_to receive(:new)

        strategy.execute(user, project)

        expect(a_request(:post, example_url)).to have_been_made
      end
    end

    context 'when object store is enabled' do
      let(:object_store_url) { 'http://object-storage/project.tar.gz' }

      before do
        stub_uploads_object_storage(FileUploader)

        export_file = import_export_upload.export_file
        allow(project).to receive(:export_file).with(user).and_return(export_file)
        allow(export_file).to receive(:url).and_return(object_store_url)
        allow(export_file).to receive(:file_storage?).and_return(false)
      end

      it 'uploads file as a remote stream' do
        arguments = {
          download_url: object_store_url,
          upload_url: example_url,
          options: {
            upload_method: :post,
            upload_content_type: 'application/gzip'
          }
        }

        expect_next_instance_of(Gitlab::ImportExport::RemoteStreamUpload, arguments) do |remote_stream_upload|
          expect(remote_stream_upload).to receive(:execute)
        end
        expect(Gitlab::HttpIO).not_to receive(:new)

        strategy.execute(user, project)
      end

      context 'when upload as remote stream raises an exception' do
        before do
          allow_next_instance_of(Gitlab::ImportExport::RemoteStreamUpload) do |remote_stream_upload|
            allow(remote_stream_upload).to receive(:execute).and_raise(
              Gitlab::ImportExport::RemoteStreamUpload::StreamError.new('Exception error message', 'Response body')
            )
          end
        end

        it 'logs the exception and stores the error message' do
          expect_next_instance_of(Gitlab::Export::Logger) do |logger|
            expect(logger).to receive(:error).ordered.with(
              {
                project_id: project.id,
                project_name: project.name,
                message: 'Exception error message',
                response_body: 'Response body'
              }
            )

            expect(logger).to receive(:error).ordered.with(
              {
                project_id: project.id,
                project_name: project.name,
                message: 'After export strategy failed',
                'exception.class' => 'Gitlab::ImportExport::RemoteStreamUpload::StreamError',
                'exception.message' => 'Exception error message',
                'exception.backtrace' => anything
              }
            )
          end

          strategy.execute(user, project)

          expect(project.import_export_shared.errors.first).to eq('Exception error message')
        end
      end
    end
  end
end
