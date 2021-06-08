# frozen_string_literal: true

require 'rake_helper'

RSpec.describe 'gitlab:artifacts namespace rake task', :silence_stdout do
  before(:context) do
    Rake.application.rake_require 'tasks/gitlab/artifacts/migrate'
  end

  let(:object_storage_enabled) { false }

  before do
    stub_artifacts_object_storage(enabled: object_storage_enabled)
  end

  describe 'gitlab:artifacts:migrate' do
    subject { run_rake_task('gitlab:artifacts:migrate') }

    let!(:artifact) { create(:ci_job_artifact, :archive, file_store: store) }
    let!(:job_trace) { create(:ci_job_artifact, :trace, file_store: store) }

    context 'when local storage is used' do
      let(:store) { ObjectStorage::Store::LOCAL }

      context 'and remote storage is defined' do
        let(:object_storage_enabled) { true }

        it "migrates file to remote storage" do
          subject

          expect(artifact.reload.file_store).to eq(ObjectStorage::Store::REMOTE)
          expect(job_trace.reload.file_store).to eq(ObjectStorage::Store::REMOTE)
        end
      end

      context 'and remote storage is not defined' do
        it "fails to migrate to remote storage" do
          subject

          expect(artifact.reload.file_store).to eq(ObjectStorage::Store::LOCAL)
          expect(job_trace.reload.file_store).to eq(ObjectStorage::Store::LOCAL)
        end
      end
    end

    context 'when remote storage is used' do
      let(:object_storage_enabled) { true }
      let(:store) { ObjectStorage::Store::REMOTE }

      it "file stays on remote storage" do
        subject

        expect(artifact.reload.file_store).to eq(ObjectStorage::Store::REMOTE)
        expect(job_trace.reload.file_store).to eq(ObjectStorage::Store::REMOTE)
      end
    end
  end

  describe 'gitlab:artifacts:migrate_to_local' do
    let(:object_storage_enabled) { true }

    subject { run_rake_task('gitlab:artifacts:migrate_to_local') }

    let!(:artifact) { create(:ci_job_artifact, :archive, file_store: store) }
    let!(:job_trace) { create(:ci_job_artifact, :trace, file_store: store) }

    context 'when remote storage is used' do
      let(:store) { ObjectStorage::Store::REMOTE }

      context 'and job has remote file store defined' do
        it "migrates file to local storage" do
          subject

          expect(artifact.reload.file_store).to eq(ObjectStorage::Store::LOCAL)
          expect(job_trace.reload.file_store).to eq(ObjectStorage::Store::LOCAL)
        end
      end
    end

    context 'when local storage is used' do
      let(:store) { ObjectStorage::Store::LOCAL }

      it 'file stays on local storage' do
        subject

        expect(artifact.reload.file_store).to eq(ObjectStorage::Store::LOCAL)
        expect(job_trace.reload.file_store).to eq(ObjectStorage::Store::LOCAL)
      end
    end
  end
end
