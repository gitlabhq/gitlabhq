# frozen_string_literal: true

RSpec.shared_examples 'export worker' do
  describe '#perform' do
    let!(:user) { create(:user) }
    let!(:project) { create(:project) }

    before do
      allow_next_instance_of(described_class) do |job|
        allow(job).to receive(:jid).and_return(SecureRandom.hex(8))
      end
    end

    context 'when it succeeds' do
      it 'calls the ExportService' do
        params = { 'description' => 'An overridden description' }

        expect_next_instance_of(::Projects::ImportExport::ExportService, project, user, params.symbolize_keys!) do |service|
          expect(service).to receive(:execute)
        end

        subject.perform(user.id, project.id, { 'klass' => 'Gitlab::ImportExport::AfterExportStrategies::DownloadNotificationStrategy' }, params)
      end

      context 'export job' do
        before do
          allow_next_instance_of(::Projects::ImportExport::ExportService) do |service|
            allow(service).to receive(:execute)
          end
        end

        it 'creates an export job record for the project' do
          expect { subject.perform(user.id, project.id, {}) }.to change { project.export_jobs.count }.from(0).to(1)
        end

        it 'sets the export job status to started' do
          expect_next_instance_of(ProjectExportJob) do |job|
            expect(job).to receive(:start)
          end

          subject.perform(user.id, project.id, {})
        end

        it 'sets the export job status to finished' do
          expect_next_instance_of(ProjectExportJob) do |job|
            expect(job).to receive(:finish)
          end

          subject.perform(user.id, project.id, {})
        end
      end
    end

    context 'when it fails' do
      it 'does not raise an exception when strategy is invalid' do
        expect(::Projects::ImportExport::ExportService).not_to receive(:new)

        expect_next_instance_of(ProjectExportJob) do |job|
          expect(job).to receive(:finish)
        end

        expect { subject.perform(user.id, project.id, { 'klass' => 'Whatever' }) }.not_to raise_error
      end

      it 'does not raise error when project cannot be found' do
        expect { subject.perform(user.id, non_existing_record_id, {}) }.not_to raise_error
      end

      it 'does not raise error when user cannot be found' do
        expect { subject.perform(non_existing_record_id, project.id, {}) }.not_to raise_error
      end

      it 'fails the export job status' do
        expect_next_instance_of(::Projects::ImportExport::ExportService) do |service|
          expect(service).to receive(:execute).and_raise(Gitlab::ImportExport::Error)
        end

        expect_next_instance_of(ProjectExportJob) do |job|
          expect(job).to receive(:fail_op)
        end

        expect { subject.perform(user.id, project.id, {}) }.to raise_error(Gitlab::ImportExport::Error)
      end
    end
  end

  describe 'sidekiq options' do
    it 'disables retry' do
      expect(described_class.sidekiq_options['retry']).to eq(false)
    end

    it 'disables dead' do
      expect(described_class.sidekiq_options['dead']).to eq(false)
    end

    it 'sets default status expiration' do
      expect(described_class.sidekiq_options['status_expiration']).to eq(StuckExportJobsWorker::EXPORT_JOBS_EXPIRATION)
    end
  end
end
