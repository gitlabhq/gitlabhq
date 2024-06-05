# frozen_string_literal: true

require 'spec_helper'

RSpec.describe StuckExportJobsWorker, feature_category: :importers do
  let(:worker) { described_class.new }

  shared_examples 'project export job detection' do
    context 'when the job has completed' do
      context 'when the export status was already updated' do
        before do
          allow(Gitlab::SidekiqStatus).to receive(:completed_jids) do
            project_export_job.start
            project_export_job.finish

            [project_export_job.jid]
          end
        end

        it 'does not mark the export as failed' do
          worker.perform

          expect(project_export_job.reload.finished?).to be true
        end
      end

      context 'when the export status was not updated' do
        before do
          allow(Gitlab::SidekiqStatus).to receive(:completed_jids) do
            project_export_job.start

            [project_export_job.jid]
          end
        end

        it 'marks the project as failed' do
          worker.perform

          expect(project_export_job.reload.failed?).to be true
        end

        context 'when export job has relation exports' do
          before do
            create(:project_relation_export, project_export_job: project_export_job)
          end

          context 'when export job updated at is less than expiration time' do
            it 'does not mark export job as failed' do
              worker.perform

              expect(project_export_job.reload.failed?).to be false
            end
          end

          context 'when export job updated at is greater than expiration time' do
            it 'marks export job as failed' do
              project_export_job.update!(created_at: 12.hours.ago)

              worker.perform

              expect(project_export_job.reload.failed?).to be true
            end
          end
        end
      end

      context 'when the job is not in queue and db record in queued state' do
        before do
          allow(Gitlab::SidekiqStatus).to receive(:completed_jids).and_return([project_export_job.jid])
        end

        it 'marks the project as failed' do
          expect(project_export_job.queued?).to be true

          worker.perform

          expect(project_export_job.reload.failed?).to be true
        end
      end
    end

    context 'when the job is running in Sidekiq' do
      before do
        allow(Gitlab::SidekiqStatus).to receive(:completed_jids).and_return([])
      end

      it 'does not mark the project export as failed' do
        expect { worker.perform }.not_to change { project_export_job.reload.status }
      end
    end
  end

  describe 'with started export status' do
    it_behaves_like 'project export job detection' do
      let(:project) { create(:project) }
      let!(:project_export_job) { create(:project_export_job, project: project, jid: '123') }
    end
  end
end
