require 'rake_helper'

describe 'gitlab:artifacts namespace rake task' do
  before(:context) do
    Rake.application.rake_require 'tasks/gitlab/artifacts'
  end

  subject { run_rake_task('gitlab:artifacts:migrate') }

  context 'legacy artifacts' do
    describe 'migrate' do
      let(:build) { create(:ci_build, artifacts_file_store: store, artifacts_metadata_store: store) }

      before do
        # Mock the legacy way of artifacts
        path = Rails.root.join('shared/artifacts',
                               build.created_at.utc.strftime('%Y_%m'),
                               build.project_id.to_s,
                               build.id.to_s)

        FileUtils.mkdir_p(path)
        FileUtils.copy(
          Rails.root.join('spec/fixtures/ci_build_artifacts.zip'),
          File.join(path, "ci_build_artifacts.zip"))

        FileUtils.copy(
          Rails.root.join('spec/fixtures/ci_build_artifacts_metadata.gz'),
          File.join(path, "ci_build_artifacts_metadata.gz"))

        build.update_columns(
          artifacts_file: 'ci_build_artifacts.zip',
          artifacts_metadata: 'ci_build_artifacts_metadata.gz')
      end

      context 'when local storage is used' do
        let(:store) { ObjectStoreUploader::LOCAL_STORE }

        context 'and job does not have file store defined' do
          before do
            build.update(artifacts_file_store: nil)
          end

          it "migrates file to remote storage" do
            stub_artifacts_object_storage

            subject

            expect(build.reload.artifacts_file_store).to eq(ObjectStoreUploader::REMOTE_STORE)
            expect(build.reload.artifacts_metadata_store).to eq(ObjectStoreUploader::REMOTE_STORE)
          end
        end

        context 'and remote storage is defined' do
          it "migrates file to remote storage" do
            stub_artifacts_object_storage

            subject

            expect(build.reload.artifacts_file_store).to eq(ObjectStoreUploader::REMOTE_STORE)
            expect(build.reload.artifacts_metadata_store).to eq(ObjectStoreUploader::REMOTE_STORE)
          end
        end

        context 'and remote storage is not defined' do
          it "fails to migrate to remote storage" do
            subject

            expect(build.reload.artifacts_file_store).to eq(ObjectStoreUploader::LOCAL_STORE)
            expect(build.reload.artifacts_metadata_store).to eq(ObjectStoreUploader::LOCAL_STORE)
          end
        end
      end

      context 'when remote storage is used' do
        let(:store) { ObjectStoreUploader::REMOTE_STORE }

        it "file stays on remote storage" do
          stub_artifacts_object_storage

          subject

          expect(build.reload.artifacts_file_store).to eq(ObjectStoreUploader::REMOTE_STORE)
          expect(build.reload.artifacts_metadata_store).to eq(ObjectStoreUploader::REMOTE_STORE)
        end
      end
    end
  end

  context 'job artifacts' do
    let(:artifact) { create(:ci_job_artifact, file_store: store) }

    context 'when local storage is used' do
      let(:store) { ObjectStoreUploader::LOCAL_STORE }

      context 'and job does not have file store defined' do
        before do
          artifact.update(file_store: nil)
        end

        it "migrates file to remote storage" do
          stub_artifacts_object_storage

          subject

          expect(artifact.reload.file_store).to eq(ObjectStoreUploader::REMOTE_STORE)
        end
      end

      context 'and remote storage is defined' do
        it "migrates file to remote storage" do
          stub_artifacts_object_storage

          subject

          expect(artifact.reload.file_store).to eq(ObjectStoreUploader::REMOTE_STORE)
        end
      end

      context 'and remote storage is not defined' do
        it "fails to migrate to remote storage" do
          subject

          expect(artifact.reload.file_store).to eq(ObjectStoreUploader::LOCAL_STORE)
        end
      end
    end

    context 'when remote storage is used' do
      let(:store) { ObjectStoreUploader::REMOTE_STORE }

      it "file stays on remote storage" do
        stub_artifacts_object_storage

        subject

        expect(artifact.reload.file_store).to eq(ObjectStoreUploader::REMOTE_STORE)
      end
    end
  end
end
