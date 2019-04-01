# frozen_string_literal: true

require 'spec_helper'

describe StuckImportJobsWorker do
  let(:worker) { described_class.new }

  shared_examples 'project import job detection' do
    context 'when the job has completed' do
      context 'when the import status was already updated' do
        before do
          allow(Gitlab::SidekiqStatus).to receive(:completed_jids) do
            import_state.start
            import_state.finish

            [import_state.jid]
          end
        end

        it 'does not mark the project as failed' do
          worker.perform

          expect(import_state.reload.status).to eq('finished')
        end
      end

      context 'when the import status was not updated' do
        before do
          allow(Gitlab::SidekiqStatus).to receive(:completed_jids).and_return([import_state.jid])
        end

        it 'marks the project as failed' do
          worker.perform

          expect(import_state.reload.status).to eq('failed')
        end
      end
    end

    context 'when the job is still in Sidekiq' do
      before do
        allow(Gitlab::SidekiqStatus).to receive(:completed_jids).and_return([])
      end

      it 'does not mark the project as failed' do
        expect { worker.perform }.not_to change { import_state.reload.status }
      end
    end
  end

  describe 'with scheduled import_status' do
    it_behaves_like 'project import job detection' do
      let(:import_state) { create(:project, :import_scheduled).import_state }

      before do
        import_state.update(jid: '123')
      end
    end
  end

  describe 'with started import_status' do
    it_behaves_like 'project import job detection' do
      let(:import_state) { create(:project, :import_started).import_state }

      before do
        import_state.update(jid: '123')
      end
    end
  end
end
