require 'spec_helper'

describe StuckImportJobsWorker do
  let(:worker) { described_class.new }

  shared_examples 'project import job detection' do
    context 'when the job has completed' do
      context 'when the import status was already updated' do
        before do
          allow(Gitlab::SidekiqStatus).to receive(:completed_jids) do
            project.import_start
            project.import_finish

            [project.import_jid]
          end
        end

        it 'does not mark the project as failed' do
          worker.perform

          expect(project.reload.import_status).to eq('finished')
        end
      end

      context 'when the import status was not updated' do
        before do
          allow(Gitlab::SidekiqStatus).to receive(:completed_jids).and_return([project.import_jid])
        end

        it 'marks the project as failed' do
          worker.perform

          expect(project.reload.import_status).to eq('failed')
        end
      end
    end

    context 'when the job is still in Sidekiq' do
      before do
        allow(Gitlab::SidekiqStatus).to receive(:completed_jids).and_return([])
      end

      it 'does not mark the project as failed' do
        expect { worker.perform }.not_to change { project.reload.import_status }
      end
    end
  end

  describe 'with scheduled import_status' do
    it_behaves_like 'project import job detection' do
      let(:project) { create(:project, :import_scheduled, import_jid: '123') }
    end
  end

  describe 'with started import_status' do
    it_behaves_like 'project import job detection' do
      let(:project) { create(:project, :import_started, import_jid: '123') }
    end
  end
end
