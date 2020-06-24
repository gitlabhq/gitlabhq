# frozen_string_literal: true

RSpec.shared_examples 'stuck import job detection' do
  context 'when the job has completed' do
    context 'when the import status was already updated' do
      before do
        allow(Gitlab::SidekiqStatus).to receive(:completed_jids) do
          import_state.start
          import_state.finish

          [import_state.jid]
        end
      end

      it 'does not mark the import as failed' do
        worker.perform

        expect(import_state.reload.status).to eq('finished')
      end
    end

    context 'when the import status was not updated' do
      before do
        allow(Gitlab::SidekiqStatus).to receive(:completed_jids).and_return([import_state.jid])
      end

      it 'marks the import as failed' do
        worker.perform

        expect(import_state.reload.status).to eq('failed')
      end
    end
  end

  context 'when the job is still in Sidekiq' do
    before do
      allow(Gitlab::SidekiqStatus).to receive(:completed_jids).and_return([])
    end

    it 'does not mark the import as failed' do
      expect { worker.perform }.not_to change { import_state.reload.status }
    end
  end
end
