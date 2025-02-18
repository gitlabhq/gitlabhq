# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Lfs::FinalizeUploadService, feature_category: :source_code_management do
  using RSpec::Parameterized::TableSyntax
  include GitHttpHelpers

  let_it_be(:project) { create(:project, :public) }
  let_it_be(:user) { create(:user) }
  let_it_be(:pat) { create(:personal_access_token, user: user, scopes: ['write_repository']) }

  let(:lfs_enabled) { true }

  let(:params) do
    {
      repository_path: "#{project.full_path}.git",
      oid: '6b9765d3888aaec789e8c309eb05b05c3a87895d6ad70d2264bd7270fff665ac',
      size: 6725030
    }
  end

  let(:uploaded_file) { temp_file }

  before do
    stub_config(lfs: { enabled: lfs_enabled })

    if uploaded_file
      allow_next_instance_of(ActionController::Parameters) do |params|
        allow(params).to receive(:[]).and_call_original
        allow(params).to receive(:[]).with(:file).and_return(uploaded_file)
      end
    end
  end

  after do
    FileUtils.rm_r(temp_file) if temp_file
  end

  subject(:service) do
    described_class.new(
      oid: params[:oid],
      size: params[:size],
      uploaded_file: uploaded_file,
      project: project,
      repository_type: :project
    ).execute
  end

  describe '#execute' do
    context 'with at least developer role' do
      before_all do
        project.add_developer(user)
      end

      it 'creates the objects' do
        expect do
          service

          expect(service).to be_a(ServiceResponse)
          expect(service).to be_success
        end
          .to change { LfsObject.count }.by(1)
          .and change { LfsObjectsProject.count }.by(1)
      end

      context 'without file' do
        let(:uploaded_file) { nil }

        it 'returns an error response' do
          service

          expect(service).to be_a(ServiceResponse)
          expect(service).not_to be_success
          expect(service.message).to eq('Unprocessable entity')
        end
      end

      context 'when uploaded_file is not a valid instance of UploadedFile' do
        let(:uploaded_file) { 'test' }

        it 'returns an error response' do
          service

          expect(service).to be_a(ServiceResponse)
          expect(service).not_to be_success
          expect(service.message).to eq('Invalid path')
        end
      end

      context 'when size and oid does not match' do
        let(:uploaded_file) { instance_double(UploadedFile, size: 1234, sha256: 'incorrect_sha', is_a?: true) }

        it 'returns an error response' do
          service

          expect(service).to be_a(ServiceResponse)
          expect(service).not_to be_success
          expect(service.message).to eq('SHA256 or size mismatch')
        end
      end

      context 'when an expected error' do
        [
          [ActiveRecord::RecordInvalid, :invalid_record],
          [ObjectStorage::RemoteStoreError, :remote_store_error]
        ].each do |exception_class, expected_reason|
          context "when #{exception_class} raised" do
            it 'renders lfs forbidden' do
              expect(LfsObjectsProject).to receive(:safe_find_or_create_by!).and_raise(exception_class)

              service

              expect(service).to be_a(ServiceResponse)
              expect(service.reason).to eq(expected_reason)
            end
          end
        end
      end

      context 'when existing file has been deleted' do
        let(:lfs_object) { create(:lfs_object, :with_file, size: params[:size], oid: params[:oid]) }

        before do
          FileUtils.rm(lfs_object.file.path)
        end

        it 'replaces the file' do
          expect(Gitlab::AppJsonLogger).to receive(:info).with(message: 'LFS file replaced because it did not exist',
            oid: lfs_object.oid, size: lfs_object.size)

          service

          expect(service).to be_success
          expect(lfs_object.reload.file).to exist
        end
      end
    end

    def temp_file
      upload_path = LfsObjectUploader.workhorse_local_upload_path
      file_path = "#{upload_path}/lfs"

      FileUtils.mkdir_p(upload_path)
      File.write(file_path, 'test')
      File.truncate(file_path, params[:size].to_i)

      UploadedFile.new(file_path, filename: File.basename(file_path), sha256: params[:oid])
    end
  end
end
