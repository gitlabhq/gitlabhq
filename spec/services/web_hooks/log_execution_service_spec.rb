# frozen_string_literal: true

require 'spec_helper'

RSpec.describe WebHooks::LogExecutionService do
  include ExclusiveLeaseHelpers
  using RSpec::Parameterized::TableSyntax

  describe '#execute' do
    around do |example|
      travel_to(Time.current) { example.run }
    end

    let_it_be_with_reload(:project_hook) { create(:project_hook) }

    let(:response_category) { :ok }
    let(:data) do
      {
        trigger: 'trigger_name',
        url: 'https://example.com',
        request_headers: { 'Header' => 'header value' },
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

    it 'updates the last failure' do
      expect(project_hook).to receive(:update_last_failure)

      service.execute
    end

    context 'obtaining an exclusive lease' do
      let(:lease_key) { "web_hooks:update_hook_failure_state:#{project_hook.id}" }

      it 'updates failure state using a lease that ensures fresh state is written' do
        service = described_class.new(hook: project_hook, log_data: data, response_category: :error)
        WebHook.find(project_hook.id).update!(backoff_count: 1)

        lease = stub_exclusive_lease(lease_key, timeout: described_class::LOCK_TTL)

        expect(lease).to receive(:try_obtain)
        expect(lease).to receive(:cancel)
        expect { service.execute }.to change { WebHook.find(project_hook.id).backoff_count }.to(2)
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

        it 'sends a message to AuthLogger if the hook as not previously enabled' do
          project_hook.update!(recent_failures: ::WebHook::FAILURE_THRESHOLD + 1)

          expect(Gitlab::AuthLogger).to receive(:info).with include(
            message: 'WebHook change active_state',
            # identification
            hook_id: project_hook.id,
            hook_type: project_hook.type,
            project_id: project_hook.project_id,
            group_id: nil,
            # relevant data
            prev_state: :permanently_disabled,
            new_state: :enabled,
            duration: 1.2,
            response_status: '200',
            recent_hook_failures: 0
          )

          service.execute
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

      context 'when the web_hooks_disable_failed FF is disabled' do
        before do
          # Hook will only be executed if the flag is disabled.
          stub_feature_flags(web_hooks_disable_failed: false)
        end

        it 'does not allow the failure count to overflow' do
          project_hook.update!(recent_failures: 32767)

          expect { service.execute }.not_to change(project_hook, :recent_failures)
        end
      end

      it 'sends a message to AuthLogger if the state would change' do
        project_hook.update!(recent_failures: ::WebHook::FAILURE_THRESHOLD)

        expect(Gitlab::AuthLogger).to receive(:info).with include(
          message: 'WebHook change active_state',
          # identification
          hook_id: project_hook.id,
          hook_type: project_hook.type,
          project_id: project_hook.project_id,
          group_id: nil,
          # relevant data
          prev_state: :enabled,
          new_state: :permanently_disabled,
          duration: (be > 0),
          response_status: data[:response_status],
          recent_hook_failures: ::WebHook::FAILURE_THRESHOLD + 1
        )

        service.execute
      end
    end

    context 'when response_category is :error' do
      let(:response_category) { :error }

      before do
        data[:response_status] = '500'
      end

      it 'does not increment the failure count' do
        expect { service.execute }.not_to change(project_hook, :recent_failures)
      end

      it 'backs off' do
        expect { service.execute }.to change(project_hook, :disabled_until)
      end

      it 'increases the backoff count' do
        expect { service.execute }.to change(project_hook, :backoff_count).by(1)
      end

      it 'sends a message to AuthLogger if the state would change' do
        expect(Gitlab::AuthLogger).to receive(:info).with include(
          message: 'WebHook change active_state',
          # identification
          hook_id: project_hook.id,
          hook_type: project_hook.type,
          project_id: project_hook.project_id,
          group_id: nil,
          # relevant data
          prev_state: :enabled,
          new_state: :temporarily_disabled,
          duration: (be > 0),
          response_status: data[:response_status],
          recent_hook_failures: 0
        )

        service.execute
      end

      context 'when the previous cool-off was near the maximum' do
        before do
          project_hook.update!(disabled_until: 5.minutes.ago, backoff_count: 8)
        end

        it 'sets the disabled_until attribute' do
          expect { service.execute }.to change(project_hook, :disabled_until).to(1.day.from_now)
        end
      end

      context 'when we have backed-off many many times' do
        before do
          project_hook.update!(disabled_until: 5.minutes.ago, backoff_count: 365)
        end

        it 'sets the disabled_until attribute' do
          expect { service.execute }.to change(project_hook, :disabled_until).to(1.day.from_now)
        end
      end
    end
  end
end
