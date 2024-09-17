# frozen_string_literal: true

require 'spec_helper'

RSpec.describe WebHooks::Events::ResendService, feature_category: :webhooks do
  include StubRequests
  let_it_be(:hook) { create(:project_hook) }
  let_it_be(:user) { create(:user) }
  let_it_be_with_reload(:log) { create(:web_hook_log, web_hook: hook) }

  subject(:service) { described_class.new(log, current_user: user) }

  describe '#execute' do
    context 'when user is authorized' do
      before do
        hook.project.add_owner(user)
      end

      context 'when the hook URL has changed' do
        before do
          allow(log).to receive(:url_current?).and_return(false)
        end

        it 'returns error' do
          service_result = service.execute

          expect(service_result).to be_error
          expect(service_result.message).to eq("The hook URL has changed, and this log entry cannot be retried")
        end
      end

      context 'when the hook URL has not changed' do
        before do
          allow(log).to receive(:url_current?).and_return(true)
        end

        it 'executes successfully' do
          stub_full_request(log.web_hook.url, method: :post)

          expect(log.web_hook).to receive(:execute).with(log.request_data, log.trigger,
            { idempotency_key: log.idempotency_key }).and_call_original

          expect(service.execute).to be_success
        end
      end
    end

    context 'when user is unauthorized' do
      before do
        hook.project.add_developer(user)
      end

      it 'returns error' do
        service_result = service.execute

        expect(service_result).to be_error
        expect(service_result.message).to eq("The current user is not authorized to resend a hook event")
      end
    end
  end
end
