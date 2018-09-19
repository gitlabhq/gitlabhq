require 'rake_helper'

describe 'gitlab:traces rake tasks' do
  before do
    Rake.application.rake_require 'tasks/gitlab/traces'
  end

  describe 'gitlab:traces:archive' do
    shared_examples 'passes the job id to worker' do
      it do
        expect(ArchiveTraceWorker).to receive(:bulk_perform_async).with([[job.id]])

        run_rake_task('gitlab:traces:archive')
      end
    end

    shared_examples 'does not pass the job id to worker' do
      it do
        expect(ArchiveTraceWorker).not_to receive(:bulk_perform_async)

        run_rake_task('gitlab:traces:archive')
      end
    end

    context 'when trace file stored in default path' do
      let!(:job) { create(:ci_build, :success, :trace_live) }

      it_behaves_like 'passes the job id to worker'
    end

    context 'when trace is stored in database' do
      let!(:job) { create(:ci_build, :success) }

      before do
        job.update_column(:trace, 'trace in db')
      end

      it_behaves_like 'passes the job id to worker'
    end

    context 'when job has trace artifact' do
      let!(:job) { create(:ci_build, :success) }

      before do
        create(:ci_job_artifact, :trace, job: job)
      end

      it_behaves_like 'does not pass the job id to worker'
    end

    context 'when job is not finished yet' do
      let!(:build) { create(:ci_build, :running, :trace_live) }

      it_behaves_like 'does not pass the job id to worker'
    end
  end

  describe 'gitlab:traces:migrate' do
    let(:object_storage_enabled) { false }

    before do
      stub_artifacts_object_storage(enabled: object_storage_enabled)
    end

    subject { run_rake_task('gitlab:traces:migrate') }

    let!(:job_trace) { create(:ci_job_artifact, :trace, file_store: store) }

    context 'when local storage is used' do
      let(:store) { ObjectStorage::Store::LOCAL }

      context 'and job does not have file store defined' do
        let(:object_storage_enabled) { true }
        let(:store) { nil }

        it "migrates file to remote storage" do
          subject

          expect(job_trace.reload.file_store).to eq(ObjectStorage::Store::REMOTE)
        end
      end

      context 'and remote storage is defined' do
        let(:object_storage_enabled) { true }

        it "migrates file to remote storage" do
          subject

          expect(job_trace.reload.file_store).to eq(ObjectStorage::Store::REMOTE)
        end
      end

      context 'and remote storage is not defined' do
        it "fails to migrate to remote storage" do
          subject

          expect(job_trace.reload.file_store).to eq(ObjectStorage::Store::LOCAL)
        end
      end
    end

    context 'when remote storage is used' do
      let(:object_storage_enabled) { true }
      let(:store) { ObjectStorage::Store::REMOTE }

      it "file stays on remote storage" do
        subject

        expect(job_trace.reload.file_store).to eq(ObjectStorage::Store::REMOTE)
      end
    end
  end
end
