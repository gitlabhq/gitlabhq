# frozen_string_literal: true

require 'spec_helper'

RSpec.describe WebHooks::LogExecutionService, feature_category: :webhooks do
  include ExclusiveLeaseHelpers
  using RSpec::Parameterized::TableSyntax

  describe '#execute', :freeze_time do
    let_it_be_with_reload(:project_hook) { create(:project_hook) }

    let(:idempotency_key) { SecureRandom.uuid }
    let(:response_category) { :ok }
    let(:request_headers) { { 'Header' => 'header value', 'Idempotency-Key' => idempotency_key } }
    let(:data) do
      {
        trigger: 'trigger_name',
        url: 'https://example.com',
        request_headers: request_headers,
        request_data: { 'Request Data' => 'request data value' },
        response_body: 'Response body',
        response_status: '200',
        execution_duration: 1.2,
        internal_error_message: 'error message'
      }
    end

    subject(:service) { described_class.new(hook: project_hook, log_data: data, response_category: response_category) }

    it 'logs the data' do
      expect { service.execute }.to change(::WebHookLog, :count).by(1)

      expect(WebHookLog.recent.first).to have_attributes(data)
    end

    context 'when data contains unsafe YAML properties' do
      before do
        data[:request_data] = { data: described_class }
      end

      it 'casts to safe properties and logs the data' do
        expect { service.execute }.to change(::WebHookLog, :count).by(1)

        expect(WebHookLog.recent.first).to have_attributes('request_data' => { 'data' => described_class.to_s })
      end
    end

    it 'updates the last failure' do
      # Avoid pruning AR caches in `update_hook_failure_state` so the following expectation works.
      allow(project_hook).to receive(:reset)
      expect(project_hook.parent).to receive(:update_last_webhook_failure).with(project_hook)

      service.execute
    end

    context 'obtaining an exclusive lease' do
      let(:lease_key) { "web_hooks:update_hook_failure_state:#{project_hook.id}" }
      let(:response_category) { :error }

      it 'updates failure state using a lease that ensures fresh state is written' do
        lease = stub_exclusive_lease(lease_key, timeout: described_class::LOCK_TTL)

        expect(lease).to receive(:try_obtain)
        expect(lease).to receive(:cancel)
        expect { service.execute }.to change { WebHook.find(project_hook.id).recent_failures }.to(1)
      end

      context 'when a lease cannot be obtained' do
        where(:response_category, :executable, :needs_updating) do
          :ok     | true  | false
          :ok     | false | true
          :failed | true  | true
          :failed | false | false
          :error  | true  | true
          :error  | false | false
        end

        with_them do
          subject(:service) { described_class.new(hook: project_hook, log_data: data, response_category: response_category) }

          before do
            # stub LOCK_RETRY to be 0 in order for tests to run quicker
            stub_const("#{described_class.name}::LOCK_RETRY", 0)
            stub_exclusive_lease_taken(lease_key, timeout: described_class::LOCK_TTL)
            allow(project_hook).to receive(:executable?).and_return(executable)
          end

          it 'raises an error if the hook needs to be updated' do
            if needs_updating
              expect { service.execute }.to raise_error(Gitlab::ExclusiveLeaseHelpers::FailedToObtainLockError)
            else
              expect { service.execute }.not_to raise_error
            end
          end
        end
      end
    end

    context 'when response_category is :ok' do
      it 'does not increment the failure count' do
        expect { service.execute }.not_to change(project_hook, :recent_failures)
      end

      it 'does not change the disabled_until attribute' do
        expect { service.execute }.not_to change(project_hook, :disabled_until)
      end

      context 'when the hook had previously failed' do
        before do
          project_hook.update!(recent_failures: 2)
        end

        it 'resets the failure count' do
          expect { service.execute }.to change(project_hook, :recent_failures).to(0)
        end
      end
    end

    context 'when response_category is :failed' do
      let(:response_category) { :failed }

      before do
        data[:response_status] = '400'
      end

      it 'increments the failure count' do
        expect { service.execute }.to change(project_hook, :recent_failures).by(1)
      end

      it 'does not change the disabled_until attribute' do
        expect { service.execute }.not_to change(project_hook, :disabled_until)
      end

      it 'does not allow the failure count to overflow' do
        project_hook.update!(recent_failures: 32767)

        expect { service.execute }.not_to change(project_hook, :recent_failures)
      end
    end

    context 'when response_category is :error' do
      let(:response_category) { :error }

      before do
        data[:response_status] = '500'
      end

      it 'backs off' do
        expect(project_hook).to receive(:backoff!)

        service.execute
      end
    end

    context 'with url_variables' do
      before do
        project_hook.update!(
          url: 'http://example1.test/{foo}-{bar}',
          url_variables: { 'foo' => 'supers3cret', 'bar' => 'token' }
        )
      end

      let(:data) { super().merge(response_headers: { 'X-Token-Id' => 'supers3cret-token', 'X-Request' => 'PUBLIC-token' }) }
      let(:expected_headers) { { 'X-Token-Id' => '{foo}-{bar}', 'X-Request' => 'PUBLIC-{bar}' } }

      it 'logs the data and masks response headers' do
        expect { service.execute }.to change(::WebHookLog, :count).by(1)

        expect(WebHookLog.recent.first.response_headers).to eq(expected_headers)
      end
    end

    context 'with X-Gitlab-Token' do
      let(:request_headers) { { 'X-Gitlab-Token' => 'secret_token' } }

      it 'redacts the token' do
        service.execute

        expect(WebHookLog.recent.first.request_headers).to include('X-Gitlab-Token' => '[REDACTED]')
      end
    end
  end
end
