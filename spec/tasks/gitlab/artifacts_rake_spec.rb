require 'rake_helper'

describe 'gitlab:artifacts namespace rake task' do
  before :all do
    Rake.application.rake_require 'tasks/gitlab/artifacts'
  end

  describe 'migrate' do
    let(:job) { create(:ci_build, :artifacts, artifacts_file_store: store, artifacts_metadata_store: store) }

    subject { run_rake_task('gitlab:artifacts:migrate') }

    context 'when local storage is used' do
      let(:store) { ObjectStoreUploader::LOCAL_STORE }

      context 'and job does not have file store defined' do
        before do
          stub_artifacts_object_storage
          job.update(artifacts_file_store: nil)
        end

        it "migrates file to remote storage" do
          subject

          expect(job.reload.artifacts_file_store).to eq(ObjectStoreUploader::REMOTE_STORE)
          expect(job.reload.artifacts_metadata_store).to eq(ObjectStoreUploader::REMOTE_STORE)
        end
      end

      context 'and remote storage is defined' do
        before do
          stub_artifacts_object_storage
          job
        end
        
        it "migrates file to remote storage" do
          subject

          expect(job.reload.artifacts_file_store).to eq(ObjectStoreUploader::REMOTE_STORE)
          expect(job.reload.artifacts_metadata_store).to eq(ObjectStoreUploader::REMOTE_STORE)
        end
      end

      context 'and remote storage is not defined' do
        before do
          job
        end

        it "fails to migrate to remote storage" do
          subject

          expect(job.reload.artifacts_file_store).to eq(ObjectStoreUploader::LOCAL_STORE)
          expect(job.reload.artifacts_metadata_store).to eq(ObjectStoreUploader::LOCAL_STORE)
        end
      end
    end

    context 'when remote storage is used' do
      let(:store) { ObjectStoreUploader::REMOTE_STORE }

      before do
        stub_artifacts_object_storage
        job
      end

      it "file stays on remote storage" do
        subject

        expect(job.reload.artifacts_file_store).to eq(ObjectStoreUploader::REMOTE_STORE)
        expect(job.reload.artifacts_metadata_store).to eq(ObjectStoreUploader::REMOTE_STORE)
      end
    end
  end
end
