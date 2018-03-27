require 'rake_helper'

describe 'gitlab:artifacts namespace rake task' do
  before(:context) do
    Rake.application.rake_require 'tasks/gitlab/artifacts/migrate'
  end

  let(:object_storage_enabled) { false }

  before do
    stub_artifacts_object_storage(enabled: object_storage_enabled)
  end

  subject { run_rake_task('gitlab:artifacts:migrate') }

  context 'legacy artifacts' do
    describe 'migrate' do
      let!(:build) { create(:ci_build, :legacy_artifacts, artifacts_file_store: store, artifacts_metadata_store: store) }

      context 'when local storage is used' do
        let(:store) { ObjectStorage::Store::LOCAL }

        context 'and job does not have file store defined' do
          let(:object_storage_enabled) { true }
          let(:store) { nil }

          it "migrates file to remote storage" do
            subject

            expect(build.reload.artifacts_file_store).to eq(ObjectStorage::Store::REMOTE)
            expect(build.reload.artifacts_metadata_store).to eq(ObjectStorage::Store::REMOTE)
          end
        end

        context 'and remote storage is defined' do
          let(:object_storage_enabled) { true }

          it "migrates file to remote storage" do
            subject

            expect(build.reload.artifacts_file_store).to eq(ObjectStorage::Store::REMOTE)
            expect(build.reload.artifacts_metadata_store).to eq(ObjectStorage::Store::REMOTE)
          end
        end

        context 'and remote storage is not defined' do
          it "fails to migrate to remote storage" do
            subject

            expect(build.reload.artifacts_file_store).to eq(ObjectStorage::Store::LOCAL)
            expect(build.reload.artifacts_metadata_store).to eq(ObjectStorage::Store::LOCAL)
          end
        end
      end

      context 'when remote storage is used' do
        let(:object_storage_enabled) { true }

        let(:store) { ObjectStorage::Store::REMOTE }

        it "file stays on remote storage" do
          subject

          expect(build.reload.artifacts_file_store).to eq(ObjectStorage::Store::REMOTE)
          expect(build.reload.artifacts_metadata_store).to eq(ObjectStorage::Store::REMOTE)
        end
      end
    end
  end

  context 'job artifacts' do
    let!(:artifact) { create(:ci_job_artifact, :archive, file_store: store) }

    context 'when local storage is used' do
      let(:store) { ObjectStorage::Store::LOCAL }

      context 'and job does not have file store defined' do
        let(:object_storage_enabled) { true }
        let(:store) { nil }

        it "migrates file to remote storage" do
          subject

          expect(artifact.reload.file_store).to eq(ObjectStorage::Store::REMOTE)
        end
      end

      context 'and remote storage is defined' do
        let(:object_storage_enabled) { true }

        it "migrates file to remote storage" do
          subject

          expect(artifact.reload.file_store).to eq(ObjectStorage::Store::REMOTE)
        end
      end

      context 'and remote storage is not defined' do
        it "fails to migrate to remote storage" do
          subject

          expect(artifact.reload.file_store).to eq(ObjectStorage::Store::LOCAL)
        end
      end
    end

    context 'when remote storage is used' do
      let(:object_storage_enabled) { true }
      let(:store) { ObjectStorage::Store::REMOTE }

      it "file stays on remote storage" do
        subject

        expect(artifact.reload.file_store).to eq(ObjectStorage::Store::REMOTE)
      end
    end
  end
end
