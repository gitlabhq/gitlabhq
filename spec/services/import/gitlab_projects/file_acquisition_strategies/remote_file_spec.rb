# frozen_string_literal: true

require 'spec_helper'

RSpec.describe ::Import::GitlabProjects::FileAcquisitionStrategies::RemoteFile, :aggregate_failures, feature_category: :importers do
  let(:remote_url) { 'https://external.file.path/file.tar.gz' }
  let(:params) { { remote_import_url: remote_url } }

  subject { described_class.new(params: params) }

  before do
    stub_application_setting(max_import_remote_file_size: 10)

    stub_headers_for(remote_url, {
      'content-length' => 10.megabytes,
      'content-type' => 'application/gzip'
    })
  end

  describe 'validation' do
    it { expect(subject).to be_valid }

    context 'file_url validation' do
      let(:remote_url) { 'ftp://invalid.url/file.tar.gz' }

      it 'validates the file_url scheme' do
        expect(subject).not_to be_valid
        expect(subject.errors.full_messages)
          .to include("File url is blocked: Only allowed schemes are https")
      end

      context 'when localhost urls are not allowed' do
        let(:remote_url) { 'https://localhost:3000/file.tar.gz' }

        it 'validates the file_url' do
          stub_application_setting(allow_local_requests_from_web_hooks_and_services: false)

          expect(subject).not_to be_valid
          expect(subject.errors.full_messages)
            .to include("File url is blocked: Requests to localhost are not allowed")
        end
      end
    end

    context 'when the HTTP request fails to recover the headers' do
      it 'adds the error message' do
        expect(Gitlab::HTTP)
          .to receive(:head)
          .and_raise(StandardError, 'request invalid')

        expect(subject).not_to be_valid
        expect(subject.errors.full_messages)
          .to include('Failed to retrive headers: request invalid')
      end
    end

    context 'when request is not from an S3 server' do
      it 'validates the remote content-length' do
        stub_application_setting(max_import_remote_file_size: 1)

        expect(subject).not_to be_valid
        expect(subject.errors.full_messages)
          .to include('Content length is too big (should be at most 1 MiB)')
      end

      it 'validates the remote content-type' do
        stub_headers_for(remote_url, { 'content-type' => 'unknown' })

        expect(subject).not_to be_valid
        expect(subject.errors.full_messages)
          .to include("Content type 'unknown' not allowed. (Allowed: application/gzip, application/x-tar, application/x-gzip)")
      end
    end

    context 'when request is from an S3 server' do
      it 'does not validate the remote content-length or content-type' do
        stub_headers_for(
          remote_url,
          'Server' => 'AmazonS3',
          'x-amz-request-id' => 'some-id',
          'content-length' => 11.gigabytes,
          'content-type' => 'unknown'
        )

        expect(subject).to be_valid
      end
    end
  end

  describe '#project_params' do
    it 'returns import_export_upload in the params' do
      subject = described_class.new(params: { remote_import_url: remote_url })

      expect(subject.project_params).to match(
        import_export_upload: an_instance_of(::ImportExportUpload)
      )
      expect(subject.project_params[:import_export_upload]).to have_attributes(
        remote_import_url: remote_url
      )
    end
  end

  def stub_headers_for(url, headers = {})
    allow(Gitlab::HTTP)
      .to receive(:head)
      .with(remote_url, timeout: 1.second)
      .and_return(double(headers: headers)) # rubocop: disable RSpec/VerifiedDoubles
  end
end
