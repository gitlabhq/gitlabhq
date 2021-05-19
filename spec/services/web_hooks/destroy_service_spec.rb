# frozen_string_literal: true

require 'spec_helper'

RSpec.describe WebHooks::DestroyService do
  let_it_be(:user) { create(:user) }

  subject { described_class.new(user) }

  shared_examples 'batched destroys' do
    it 'destroys all hooks in batches' do
      stub_const("#{described_class}::BATCH_SIZE", 1)
      expect(subject).to receive(:delete_web_hook_logs_in_batches).exactly(4).times.and_call_original

      expect do
        status = subject.execute(hook)
        expect(status[:async]).to be false
      end
        .to change { WebHook.count }.from(1).to(0)
        .and change { WebHookLog.count }.from(3).to(0)
    end

    it 'returns an error if sync destroy fails' do
      expect(hook).to receive(:destroy).and_return(false)

      result = subject.sync_destroy(hook)

      expect(result[:status]).to eq(:error)
      expect(result[:message]).to eq("Unable to destroy #{hook.model_name.human}")
    end

    it 'schedules an async delete' do
      stub_const('WebHooks::DestroyService::LOG_COUNT_THRESHOLD', 1)

      expect(WebHooks::DestroyWorker).to receive(:perform_async).with(user.id, hook.id).and_call_original

      status = subject.execute(hook)

      expect(status[:async]).to be true
    end
  end

  context 'with system hook' do
    let!(:hook) { create(:system_hook, url: "http://example.com") }
    let!(:log) { create_list(:web_hook_log, 3, web_hook: hook) }

    it_behaves_like 'batched destroys'
  end

  context 'with project hook' do
    let!(:hook) { create(:project_hook) }
    let!(:log) { create_list(:web_hook_log, 3, web_hook: hook) }

    it_behaves_like 'batched destroys'
  end
end
