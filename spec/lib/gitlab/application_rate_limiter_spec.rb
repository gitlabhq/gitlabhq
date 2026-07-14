# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::ApplicationRateLimiter, :clean_gitlab_redis_rate_limiting, feature_category: :system_access do
  include StubRequests

  let_it_be(:user) { create(:user) }
  let_it_be(:project) { create(:project) }

  let(:rate_limits) do
    {
      test_action: {
        threshold: 1,
        interval: 2.minutes
      },
      another_action: {
        threshold: -> { 2 },
        interval: -> { 3.minutes }
      }
    }
  end

  # The labkit adapter is the sole rate-limiting path, so the synthetic keys
  # used throughout these examples must be registered for the adapter to handle
  # them. INCR-mode entries here; the resource-usage describe overrides this
  # with cost-mode entries.
  let(:labkit_registry) do
    {
      test_action: {
        limiter_name: 'applimiter_test_action',
        rule_name: 'limit_test_action',
        characteristics: %i[user project],
        limit: 1,
        period: 2.minutes,
        action: :block
      },
      another_action: {
        limiter_name: 'applimiter_another_action',
        rule_name: 'limit_another_action',
        characteristics: %i[user project],
        limit: -> { 2 },
        period: -> { 3.minutes },
        action: :block
      }
    }
  end

  subject { described_class }

  before do
    allow(described_class).to receive(:rate_limits).and_return(rate_limits)
    allow(Gitlab::ApplicationRateLimiter::LabkitAdapter::SupportedRateLimits)
      .to receive(:all).and_return(labkit_registry)
  end

  describe '.throttled?' do
    context 'when redis is unavailable' do
      before do
        broken_redis = Redis.new(
          url: 'redis://127.0.0.0:0',
          custom: { instrumentation_class: Gitlab::Redis::RateLimiting.instrumentation_class }
        )
        allow(Gitlab::Redis::RateLimiting).to receive(:with).and_yield(broken_redis)
        allow(Gitlab::ErrorTracking).to receive(:track_and_raise_for_dev_exception)
      end

      it 'returns false' do
        expect(subject.throttled?(:test_action, scope: [user])).to eq(false)
      end
    end

    context 'when the key is invalid' do
      context 'is provided as a Symbol' do
        context 'but is not defined in the rate_limits Hash' do
          it 'raises an InvalidKeyError exception' do
            key = :key_not_in_rate_limits_hash

            expect { subject.throttled?(key, scope: [user]) }.to raise_error(Gitlab::ApplicationRateLimiter::InvalidKeyError)
          end
        end
      end

      context 'is provided as a String' do
        context 'and is a String representation of an existing key in rate_limits Hash' do
          it 'raises an InvalidKeyError exception' do
            key = rate_limits.keys[0].to_s

            expect { subject.throttled?(key, scope: [user]) }.to raise_error(Gitlab::ApplicationRateLimiter::InvalidKeyError)
          end
        end

        context 'but is not defined in any form in the rate_limits Hash' do
          it 'raises an InvalidKeyError exception' do
            key = 'key_not_in_rate_limits_hash'

            expect { subject.throttled?(key, scope: [user]) }.to raise_error(Gitlab::ApplicationRateLimiter::InvalidKeyError)
          end
        end
      end
    end

    context 'when the scope is invalid' do
      it 'raises an InvalidScopeError exception when scope is nil' do
        expect { subject.throttled?(:test_action, scope: nil) }
          .to raise_error(
            Gitlab::ApplicationRateLimiter::InvalidScopeError,
            "scope cannot be nil. Use :global for global rate limits."
          )
      end

      it 'logs a warning when scope is nil' do
        expect(Gitlab::AuthLogger).to receive(:warn).with(
          message: 'Application_Rate_Limiter_Request_Without_Scope',
          env: :test_action_request_limit
        )

        expect { subject.throttled?(:test_action, scope: nil) }
          .to raise_error(Gitlab::ApplicationRateLimiter::InvalidScopeError)
      end
    end

    context 'when the key is valid' do
      it 'records the checked key in request storage', :request_store do
        subject.throttled?(:test_action, scope: [user])

        expect(::Gitlab::Instrumentation::RateLimitingGates.payload)
          .to eq(::Gitlab::Instrumentation::RateLimitingGates::GATES => [:test_action])
      end
    end

    shared_examples 'throttles based on key and scope' do
      let(:start_time) { Time.current.beginning_of_hour }

      let(:threshold) { nil }
      let(:interval) { nil }

      it 'returns true when threshold is exceeded', :aggregate_failures do
        travel_to(start_time) do
          expect(
            subject.throttled?(
              :test_action, scope: scope, threshold: threshold, interval: interval
            )
          ).to eq(false)
        end

        travel_to(start_time + 1.minute) do
          expect(
            subject.throttled?(
              :test_action, scope: scope, threshold: threshold, interval: interval
            )
          ).to eq(true)

          # Assert that it does not affect other actions or scope
          expect(subject.throttled?(:another_action, scope: scope)).to eq(false)

          expect(
            subject.throttled?(
              :test_action, scope: [user], threshold: threshold, interval: interval
            )
          ).to eq(false)
        end
      end

      # Window expiry (counter reset once the interval elapses) is labkit's
      # behaviour: its bucket is a Redis-side TTL that travel_to cannot move,
      # so it is covered by labkit's own specs rather than re-asserted here.

      it 'allows peeking at the current state without changing its value', :aggregate_failures do
        travel_to(start_time) do
          expect(
            subject.throttled?(
              :test_action, scope: scope, threshold: threshold, interval: interval
            )
          ).to eq(false)

          2.times do
            expect(
              subject.throttled?(
                :test_action, scope: scope, threshold: threshold, interval: interval, peek: true
              )
            ).to eq(false)
          end

          expect(
            subject.throttled?(
              :test_action, scope: scope, threshold: threshold, interval: interval
            )
          ).to eq(true)

          expect(
            subject.throttled?(
              :test_action, scope: scope, peek: true, threshold: threshold, interval: interval
            )
          ).to eq(true)
        end
      end
    end

    context 'when using ActiveRecord models as scope' do
      let(:scope) { [user, project] }

      it_behaves_like 'throttles based on key and scope'
    end

    context 'when using a user allow list' do
      let(:scope) { user }
      let(:start_time) { Time.current.beginning_of_hour }

      before do
        # Hit the rate limit before running examples
        travel_to(start_time) { subject.throttled?(:test_action, scope: scope) }
      end

      context 'when the user is in the allow list' do
        let(:allowlist) { [user.username.titlecase] } # titlecase to test that case sensitivity is ignored

        it 'is not throttled' do
          travel_to(start_time + 1.minute) do
            expect(subject.throttled?(:test_action, scope: scope, users_allowlist: allowlist)).to eq(false)
          end
        end
      end

      context 'when the user is not in the allow list' do
        let(:allowlist) { ['DifferentUsername'] }

        it 'is throttled' do
          travel_to(start_time + 1.minute) do
            expect(subject.throttled?(:test_action, scope: scope, users_allowlist: allowlist)).to eq(true)
          end
        end
      end
    end

    context 'when using ActiveRecord models and strings as scope' do
      let(:scope) { [project, 'app/controllers/groups_controller.rb'] }

      it_behaves_like 'throttles based on key and scope'
    end

    context 'when threshold and interval get overwritten from rate_limits' do
      let(:rate_limits) do
        {
          test_action: {
            threshold: 0,
            interval: 0
          },
          another_action: {
            threshold: -> { 2 },
            interval: -> { 3.minutes }
          }
        }
      end

      let(:scope) { [user, project] }

      it_behaves_like 'throttles based on key and scope' do
        let(:threshold) { 1 }
        let(:interval) { 2.minutes }
      end
    end
  end

  describe '.resource_usage_throttled?', :request_store do
    let(:resource_key) { :throttled_resource_duration }
    let(:resource_key_2) { :another_throttled_resource_duration }

    let(:threshold) { 100 }
    let(:interval) { 60 }

    # resource_usage_throttled? builds an IncrementResourceUsagePerAction
    # strategy, which the adapter only dispatches for cost-mode entries.
    let(:labkit_registry) do
      {
        test_action: {
          limiter_name: 'applimiter_test_action',
          rule_name: 'limit_test_action',
          characteristics: %i[user project],
          action: :block,
          cost_mode: true
        },
        another_action: {
          limiter_name: 'applimiter_another_action',
          rule_name: 'limit_another_action',
          characteristics: %i[user project],
          action: :block,
          cost_mode: true
        }
      }
    end

    before do
      Gitlab::SafeRequestStore.begin!
      Gitlab::SafeRequestStore[resource_key] = threshold
      Gitlab::SafeRequestStore[resource_key_2] = threshold
    end

    context 'when the scope is invalid' do
      it 'raises an InvalidScopeError exception when scope is nil' do
        expect { subject.resource_usage_throttled?(:test_action, scope: nil, resource_key: resource_key, threshold: threshold, interval: interval) }
          .to raise_error(
            Gitlab::ApplicationRateLimiter::InvalidScopeError,
            "scope cannot be nil. Use :global for global rate limits."
          )
      end

      it 'logs a warning when scope is nil' do
        expect(Gitlab::AuthLogger).to receive(:warn).with(
          message: 'Application_Rate_Limiter_Request_Without_Scope',
          env: :test_action_request_limit
        )

        expect { subject.resource_usage_throttled?(:test_action, scope: nil, resource_key: resource_key, threshold: threshold, interval: interval) }
          .to raise_error(Gitlab::ApplicationRateLimiter::InvalidScopeError)
      end
    end

    it 'records the checked key in request storage' do
      subject.resource_usage_throttled?(:test_action, scope: [user], resource_key: resource_key, threshold: threshold, interval: interval)

      expect(::Gitlab::Instrumentation::RateLimitingGates.payload)
        .to eq(::Gitlab::Instrumentation::RateLimitingGates::GATES => [:test_action])

      subject.resource_usage_throttled?(:another_action, scope: [user], resource_key: resource_key, threshold: threshold, interval: interval)

      expect(::Gitlab::Instrumentation::RateLimitingGates.payload)
        .to eq(::Gitlab::Instrumentation::RateLimitingGates::GATES => [:test_action, :another_action])
    end

    describe 'incrementing resource usage once per unique resource' do
      let(:scope) { [user, project] }

      let(:start_time) { Time.current.beginning_of_hour }
      let_it_be(:project2) { create(:project) }

      let(:interval) { 90 }

      it 'returns true when unique actioned resources count exceeds threshold' do
        travel_to(start_time) do
          expect(
            subject.resource_usage_throttled?(
              :test_action, scope: scope, resource_key: resource_key, threshold: threshold, interval: interval
            )
          ).to eq(false)
        end

        travel_to(start_time + 1.minute) do
          expect(
            subject.resource_usage_throttled?(
              :test_action, scope: scope, resource_key: resource_key, threshold: threshold, interval: interval
            )
          ).to eq(true)
        end
      end

      it 'returns false when unique actioned resource count does not exceed threshold' do
        travel_to(start_time) do
          expect(
            subject.resource_usage_throttled?(
              :test_action, scope: scope, resource_key: resource_key, threshold: threshold, interval: interval
            )
          ).to eq(false)
        end

        travel_to(start_time + 1.minute) do
          expect(
            described_class.resource_usage_throttled?(
              :test_action, scope: [user, project2], resource_key: resource_key, threshold: threshold, interval: interval
            )
          ).to eq(false)
        end
      end

      # Window expiry once the interval elapses is labkit's behaviour (a
      # Redis-side TTL that travel_to cannot move); see labkit's own specs.
    end

    context 'with peek' do
      let(:scope) { [user, project] }
      let(:start_time) { Time.current.beginning_of_hour }
      let(:kwargs) { { scope: scope, resource_key: resource_key, threshold: threshold, interval: interval } }

      it 'allows peeking at the current resource usage without changing its value' do
        travel_to(start_time) do
          # increment usage up to threshold
          expect(subject.resource_usage_throttled?(:test_action, **kwargs)).to eq(false)

          # peeking at current usage returns false because the value is still the same as threshold
          expect(subject.resource_usage_throttled?(:test_action, peek: true, **kwargs)).to eq(false)

          # increment again, current usage is now > threshold
          expect(subject.resource_usage_throttled?(:test_action, **kwargs)).to eq(true)

          # peeking again
          expect(subject.resource_usage_throttled?(:test_action, peek: true, **kwargs)).to eq(true)
        end
      end
    end

    shared_examples 'throttles resource usage based on key and scope' do
      let(:start_time) { Time.current.beginning_of_hour }

      it 'returns true when threshold is exceeded', :aggregate_failures do
        travel_to(start_time) do
          expect(
            subject.resource_usage_throttled?(
              :test_action, scope: scope, resource_key: resource_key, threshold: threshold, interval: interval
            )
          ).to eq(false)
        end

        travel_to(start_time + 59.seconds) do
          expect(
            subject.resource_usage_throttled?(
              :test_action, scope: scope, resource_key: resource_key, threshold: threshold, interval: interval
            )
          ).to eq(true)

          # Assert that it does not affect other actions or scope
          expect(subject.resource_usage_throttled?(:another_action, scope: scope, resource_key: resource_key, threshold: threshold, interval: interval)).to eq(false)

          expect(
            subject.resource_usage_throttled?(
              :test_action, scope: [user], resource_key: resource_key, threshold: threshold, interval: interval
            )
          ).to eq(false)
        end
      end

      # Window expiry once the interval elapses is labkit's behaviour (a
      # Redis-side TTL that travel_to cannot move); see labkit's own specs.
    end

    context 'when using ActiveRecord models as scope' do
      let(:scope) { [user, project] }

      it_behaves_like 'throttles resource usage based on key and scope'
    end

    context 'when using ActiveRecord models and strings as scope' do
      let(:scope) { [project, 'app/controllers/groups_controller.rb'] }

      it_behaves_like 'throttles resource usage based on key and scope'
    end
  end

  describe '.throttled_request?', :freeze_time do
    let(:request) { instance_double('Rack::Request') }

    context 'when request is not over the limit' do
      it 'returns false and does not log the request' do
        expect(subject).not_to receive(:log_request)

        expect(subject.throttled_request?(request, user, :test_action, scope: [user])).to eq(false)
      end
    end

    context 'when request is over the limit' do
      before do
        subject.throttled?(:test_action, scope: [user])
      end

      it 'returns true and logs the request' do
        expect(subject).to receive(:log_request).with(request, :test_action_request_limit, user)

        expect(subject.throttled_request?(request, user, :test_action, scope: [user])).to eq(true)
      end

      context 'when the bypass header is set' do
        before do
          allow(Gitlab::Throttle).to receive(:bypass_header).and_return('SOME_HEADER')
        end

        it 'skips rate limit if set to "1"' do
          allow(request).to receive(:get_header).with(Gitlab::Throttle.bypass_header).and_return('1')

          expect(subject).not_to receive(:log_request)

          expect(subject.throttled_request?(request, user, :test_action, scope: [user])).to eq(false)
        end

        it 'does not skip rate limit if set to something else than "1"' do
          allow(request).to receive(:get_header).with(Gitlab::Throttle.bypass_header).and_return('0')

          expect(subject).to receive(:log_request).with(request, :test_action_request_limit, user)

          expect(subject.throttled_request?(request, user, :test_action, scope: [user])).to eq(true)
        end
      end
    end
  end

  describe '.peek' do
    it 'peeks at the current state without changing its value' do
      freeze_time do
        expect(subject.peek(:test_action, scope: [user])).to eq(false)
        expect(subject.throttled?(:test_action, scope: [user])).to eq(false)
        2.times do
          expect(subject.peek(:test_action, scope: [user])).to eq(false)
        end
        expect(subject.throttled?(:test_action, scope: [user])).to eq(true)
        expect(subject.peek(:test_action, scope: [user])).to eq(true)
      end
    end
  end

  describe '.log_request' do
    let(:token_prefix) { Gitlab::ApplicationSettingFetcher.current_application_settings.personal_access_token_prefix }
    let(:token_string) { "#{token_prefix}PAT1234" }
    let(:relative_url) { "/#{project.full_path}/raw/?private_token=#{token_string}" }

    let(:type) { :raw_blob_request_limit }
    let(:request) { request_for_url(relative_url) }

    let(:base_attributes) do
      {
        message: 'Application_Rate_Limiter_Request',
        env: type,
        method: 'GET',
        remote_ip: request.ip,
        path: request.filtered_path
      }
    end

    context 'without a current user' do
      let(:current_user) { nil }

      it 'logs filtered information to auth.log' do
        expect(Gitlab::AuthLogger).to receive(:error).with(base_attributes).once

        subject.log_request(request, type, current_user)
      end
    end

    context 'with a current_user' do
      let(:current_user) { user }

      let(:attributes) do
        base_attributes.merge({
          user_id: current_user.id,
          username: current_user.username
        })
      end

      it 'logs filtered information to auth.log' do
        expect(Gitlab::AuthLogger).to receive(:error).with(attributes).once

        subject.log_request(request, type, current_user)
      end
    end
  end

  shared_examples 'returns false' do
    it 'returns false' do
      travel_to(start_time) do
        expect(subject.throttled?(:test_action, scope: scope)).to eq(false)
      end

      travel_to(start_time + 1.minute) do
        expect(subject.throttled?(:test_action, scope: scope)).to eq(false)
      end
    end
  end

  context 'when interval is 0' do
    let(:scope) { user }
    let(:start_time) { Time.current.beginning_of_hour }

    before do
      # Stub the resolved interval (the stable seam) so the zero-disable check
      # is exercised regardless of the resolve-from-registry flag state.
      allow(described_class).to receive(:interval).and_call_original
      allow(described_class).to receive(:interval).with(:test_action).and_return(0)
    end

    it_behaves_like 'returns false'
  end

  context 'when threshold is 0' do
    let(:scope) { user }
    let(:start_time) { Time.current.beginning_of_hour }

    before do
      allow(described_class).to receive(:threshold).and_call_original
      allow(described_class).to receive(:threshold).with(:test_action).and_return(0)
    end

    it_behaves_like 'returns false'
  end

  describe 'limit/period source selection (.threshold / .interval)' do
    # rate_limits and the registry are stubbed to deliberately different values
    # so it is unambiguous which source the flag selects.
    let(:rate_limits) { { test_action: { threshold: 11, interval: 22 } } }
    let(:labkit_registry) do
      {
        test_action: {
          limiter_name: 'applimiter_test_action',
          rule_name: 'limit_test_action',
          characteristics: %i[user],
          limit: 99,
          period: 88,
          action: :block
        }
      }
    end

    context 'when rate_limiter_resolve_limits_from_registry is enabled' do
      it 'resolves threshold and interval from the registry', :aggregate_failures do
        expect(described_class.threshold(:test_action)).to eq(99)
        expect(described_class.interval(:test_action)).to eq(88)
      end
    end

    context 'when rate_limiter_resolve_limits_from_registry is disabled' do
      before do
        stub_feature_flags(rate_limiter_resolve_limits_from_registry: false)
      end

      it 'resolves threshold and interval from the rate_limits hash', :aggregate_failures do
        expect(described_class.threshold(:test_action)).to eq(11)
        expect(described_class.interval(:test_action)).to eq(22)
      end
    end
  end

  describe 'labkit adapter dispatch from _throttled?', :clean_gitlab_redis_rate_limiting do
    # These examples exercise the real registry and keys, so the synthetic
    # registry stub from the top-level before is reverted here.
    before do
      allow(described_class).to receive(:rate_limits).and_call_original
      allow(Gitlab::ApplicationRateLimiter::LabkitAdapter::SupportedRateLimits)
        .to receive(:all).and_call_original
      allow(Gitlab::CurrentSettings.current_application_settings)
        .to receive(:users_get_by_id_limit).and_return(1)
    end

    it 'preserves the throttled? parameter signature' do
      expect(described_class.method(:throttled?).parameters).to eq(
        [[:req, :key],
          [:keyreq, :scope],
          [:key, :resource],
          [:key, :threshold],
          [:key, :interval],
          [:key, :users_allowlist],
          [:key, :peek]]
      )
    end

    it 'returns a Boolean from throttled?' do
      result = described_class.throttled?(:users_get_by_id, scope: user)
      expect(result).to be(true).or be(false)
    end

    context 'when the strategy does not match the labkit rule mode' do
      it 'does not dispatch when a resource is provided for an INCR-mode key' do
        expect(Gitlab::ApplicationRateLimiter::LabkitAdapter).not_to receive(:run!)

        expect(described_class.throttled?(:users_get_by_id, scope: user, resource: user)).to be(false)
      end
    end

    context 'with an IncrementPerActionedResource strategy on a count_distinct key' do
      let_it_be(:project) { create(:project) }
      let(:count_distinct_spec) do
        {
          limiter_name: 'applimiter_distinct',
          rule_name: 'limit_distinct_by_user',
          characteristics: %i[user],
          count_distinct: :project_id,
          action: :block
        }
      end

      before do
        allow(Gitlab::ApplicationRateLimiter::LabkitAdapter::SupportedRateLimits).to receive(:all)
          .and_return(users_get_by_id: count_distinct_spec)
      end

      it 'dispatches to the labkit adapter and forwards the resource id and overrides' do
        expect(Gitlab::ApplicationRateLimiter::LabkitAdapter).to receive(:run!)
          .with(:users_get_by_id, scope: user,
            context: { resource_id: project.id, threshold: 5, interval: 60 }, cost: nil).and_return(false)

        described_class.throttled?(:users_get_by_id, scope: user, resource: project,
          threshold: 5, interval: 60)
      end
    end

    context 'with a cost-mode key via resource_usage_throttled?', :request_store do
      let(:resource_key) { :main_db_duration_s }

      before do
        Gitlab::SafeRequestStore.begin!
        Gitlab::SafeRequestStore[resource_key] = 5.0
      end

      it 'dispatches to the adapter forwarding the resolved threshold, interval and cost' do
        expect(Gitlab::ApplicationRateLimiter::LabkitAdapter).to receive(:run!)
          .with(:main_db_duration_limit_per_worker, scope: 'SomeWorker',
            context: hash_including(threshold: 1234, interval: 77), cost: 5.0).and_return(false)

        described_class.resource_usage_throttled?(:main_db_duration_limit_per_worker,
          scope: 'SomeWorker', resource_key: resource_key, threshold: 1234, interval: 77)
      end
    end

    context 'in peek mode' do
      let_it_be(:namespace) { create(:namespace) }

      before do
        allow(Gitlab::CurrentSettings.current_application_settings)
          .to receive(:update_namespace_name_rate_limit).and_return(2)
      end

      it 'dispatches peek checks to the labkit adapter without incrementing' do
        expect(Gitlab::ApplicationRateLimiter::LabkitAdapter).to receive(:run_peek!)
          .with(:update_namespace_name, scope: namespace, context: { resource_id: nil, threshold: nil, interval: nil })
          .and_return(false)
        expect(Gitlab::ApplicationRateLimiter::LabkitAdapter).not_to receive(:run!)

        expect(described_class.peek(:update_namespace_name, scope: namespace)).to be(false)
      end

      it 'returns the labkit peek decision' do
        expect(Gitlab::ApplicationRateLimiter::LabkitAdapter).to receive(:run_peek!)
          .with(:update_namespace_name, scope: namespace, context: { resource_id: nil, threshold: nil, interval: nil })
          .and_return(true)

        expect(described_class.peek(:update_namespace_name, scope: namespace)).to be(true)
      end
    end
  end

  describe '.rate_limits' do
    before do
      allow(described_class).to receive(:rate_limits).and_call_original
    end

    describe 'ci_lint' do
      it 'derives its threshold from the ci_lint_limit_per_user application setting', :aggregate_failures do
        stub_application_setting(ci_lint_limit_per_user: 30)

        values = described_class.rate_limits[:ci_lint]

        expect(values[:threshold].call).to eq(30)
        expect(values[:interval]).to eq(1.minute)
      end
    end
  end
end
