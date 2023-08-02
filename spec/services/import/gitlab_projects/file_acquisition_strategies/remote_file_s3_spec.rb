# frozen_string_literal: true

require 'spec_helper'

RSpec.describe ::Import::GitlabProjects::FileAcquisitionStrategies::RemoteFileS3, :aggregate_failures, feature_category: :importers do
  let(:region_name) { 'region_name' }
  let(:bucket_name) { 'bucket_name' }
  let(:file_key) { 'file_key' }
  let(:access_key_id) { 'access_key_id' }
  let(:secret_access_key) { 'secret_access_key' }
  let(:file_exists) { true }
  let(:content_type) { 'application/x-tar' }
  let(:content_length) { 10.megabytes }
  let(:presigned_url) { 'https://external.file.path/file.tar.gz?PRESIGNED=true&TOKEN=some-token' }

  let(:s3_double) do
    instance_double(
      Aws::S3::Object,
      exists?: file_exists,
      content_type: content_type,
      content_length: content_length,
      presigned_url: presigned_url
    )
  end

  let(:params) do
    {
      region: region_name,
      bucket_name: bucket_name,
      file_key: file_key,
      access_key_id: access_key_id,
      secret_access_key: secret_access_key
    }
  end

  subject { described_class.new(params: params) }

  before do
    # Avoid network requests
    expect(Aws::S3::Client).to receive(:new).and_return(double)
    expect(Aws::S3::Object).to receive(:new).and_return(s3_double)

    stub_application_setting(max_import_remote_file_size: 10)
  end

  describe 'validation' do
    it { expect(subject).to be_valid }

    %i[region bucket_name file_key access_key_id secret_access_key].each do |key|
      context "#{key} validation" do
        before do
          params[key] = nil
        end

        it "validates presence of #{key}" do
          expect(subject).not_to be_valid
          expect(subject.errors.full_messages)
            .to include("#{key.to_s.humanize} can't be blank")
        end
      end
    end

    context 'content-length validation' do
      let(:content_length) { 11.megabytes }

      it 'validates the remote content-length' do
        expect(subject).not_to be_valid
        expect(subject.errors.full_messages)
          .to include('Content length is too big (should be at most 10 MiB)')
      end
    end

    context 'content-type validation' do
      let(:content_type) { 'unknown' }

      it 'validates the remote content-type' do
        expect(subject).not_to be_valid
        expect(subject.errors.full_messages)
          .to include("Content type 'unknown' not allowed. (Allowed: application/gzip, application/x-tar, application/x-gzip)")
      end
    end

    context 'file_url validation' do
      let(:presigned_url) { 'ftp://invalid.url/file.tar.gz' }

      it 'validates the file_url scheme' do
        expect(subject).not_to be_valid
        expect(subject.errors.full_messages)
          .to include("File url is blocked: Only allowed schemes are https")
      end

      context 'when localhost urls are not allowed' do
        let(:presigned_url) { 'https://localhost:3000/file.tar.gz' }

        it 'validates the file_url' do
          stub_application_setting(allow_local_requests_from_web_hooks_and_services: false)

          expect(subject).not_to be_valid
          expect(subject.errors.full_messages)
            .to include("File url is blocked: Requests to localhost are not allowed")
        end
      end
    end

    context 'when the remote file does not exist' do
      it 'foo' do
        expect(s3_double).to receive(:exists?).and_return(false)

        expect(subject).not_to be_valid
        expect(subject.errors.full_messages)
          .to include("File not found 'file_key' in 'bucket_name'")
      end
    end

    context 'when it fails to build the s3 object' do
      it 'foo' do
        expect(s3_double).to receive(:exists?).and_raise(StandardError, "some error")

        expect(subject).not_to be_valid
        expect(subject.errors.full_messages)
          .to include("Failed to open 'file_key' in 'bucket_name': some error")
      end
    end
  end

  describe '#project_params' do
    it 'returns import_export_upload in the params' do
      subject = described_class.new(params: { remote_import_url: presigned_url })

      expect(subject.project_params).to match(
        import_export_upload: an_instance_of(::ImportExportUpload)
      )
      expect(subject.project_params[:import_export_upload]).to have_attributes(
        remote_import_url: presigned_url
      )
    end
  end
end
