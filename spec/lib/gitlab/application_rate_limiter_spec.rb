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

  subject { described_class }

  before do
    allow(described_class).to receive(:rate_limits).and_return(rate_limits)
  end

  describe '.throttled?' do
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

    context 'when the key is valid' do
      it 'records the checked key in request storage', :request_store do
        subject.throttled?(:test_action, scope: [user])

        expect(::Gitlab::Instrumentation::RateLimitingGates.payload)
          .to eq(::Gitlab::Instrumentation::RateLimitingGates::GATES => [:test_action])

        subject.throttled?(:another_action, scope: [user], peek: true)

        expect(::Gitlab::Instrumentation::RateLimitingGates.payload)
          .to eq(::Gitlab::Instrumentation::RateLimitingGates::GATES => [:test_action, :another_action])
      end
    end

    describe 'counting actions once per unique resource' do
      let(:scope) { [user, project] }

      let(:start_time) { Time.current.beginning_of_hour }
      let(:project1) { instance_double(Project, id: '1') }
      let(:project2) { instance_double(Project, id: '2') }

      before do
        if described_class.instance_variable_defined?(:@application_rate_limiter_histogram)
          described_class.remove_instance_variable(:@application_rate_limiter_histogram)
        end
      end

      it 'returns true when unique actioned resources count exceeds threshold' do
        travel_to(start_time) do
          expect(subject.throttled?(:test_action, scope: scope, resource: project1)).to eq(false)
        end

        travel_to(start_time + 1.minute) do
          expect(subject.throttled?(:test_action, scope: scope, resource: project2)).to eq(true)
        end
      end

      it 'returns false when unique actioned resource count does not exceed threshold' do
        travel_to(start_time) do
          expect(subject.throttled?(:test_action, scope: scope, resource: project1)).to eq(false)
        end

        travel_to(start_time + 1.minute) do
          expect(subject.throttled?(:test_action, scope: scope, resource: project1)).to eq(false)
        end
      end

      it 'returns false when interval has elapsed' do
        travel_to(start_time) do
          expect(subject.throttled?(:test_action, scope: scope, resource: project1)).to eq(false)
        end

        travel_to(start_time + 2.minutes) do
          expect(subject.throttled?(:test_action, scope: scope, resource: project2)).to eq(false)
        end
      end
    end

    describe 'emitting metrics for throttling utilization' do
      let(:histogram_double) { instance_double(Prometheus::Client::Histogram) }

      around do |example|
        # check if defined
        if described_class.instance_variable_defined?(:@application_rate_limiter_histogram)
          described_class.remove_instance_variable(:@application_rate_limiter_histogram)
        end

        example.run

        described_class.remove_instance_variable(:@application_rate_limiter_histogram)
      end

      it 'observe histogram metrics using a memoized histogram instance' do
        expect(Gitlab::Metrics).to receive(:histogram)
          .once
          .with(
            :gitlab_application_rate_limiter_throttle_utilization_ratio,
            "The utilization-ratio of a throttle.",
            { peek: nil, throttle_key: nil, feature_category: nil },
            described_class::LIMIT_USAGE_BUCKET
          )
          .and_return(histogram_double)
        expect(histogram_double).to receive(:observe).twice

        subject.throttled?(:test_action, scope: [], threshold: 1)
        subject.throttled?(:test_action, scope: [], threshold: 1)
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

      it 'returns false when interval has elapsed', :aggregate_failures do
        travel_to(start_time) do
          expect(
            subject.throttled?(
              :test_action, scope: scope, threshold: threshold, interval: interval
            )
          ).to eq(false)

          # another_action has a threshold of 2 so we simulate 2 requests
          expect(subject.throttled?(:another_action, scope: scope)).to eq(false)
          expect(subject.throttled?(:another_action, scope: scope)).to eq(false)
        end

        travel_to(start_time + 2.minutes) do
          expect(
            subject.throttled?(
              :test_action, scope: scope, threshold: threshold, interval: interval
            )
          ).to eq(false)

          # Assert that another_action has its own interval that hasn't elapsed
          expect(subject.throttled?(:another_action, scope: scope)).to eq(true)
        end
      end

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
    let(:resource_key) { 'throttled_resource_duration' }
    let(:resource_key_2) { 'another_throttled_resource_duration' }

    let(:threshold) { 100 }
    let(:interval) { 60 }

    before do
      Gitlab::SafeRequestStore.begin!
      Gitlab::SafeRequestStore[resource_key] = threshold
      Gitlab::SafeRequestStore[resource_key_2] = threshold
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

      it 'returns false when interval has elapsed' do
        travel_to(start_time) do
          expect(
            subject.resource_usage_throttled?(
              :test_action, scope: scope, resource_key: resource_key, threshold: threshold, interval: interval
            )
          ).to eq(false)
        end

        travel_to(start_time + 2.minutes) do
          expect(
            subject.resource_usage_throttled?(
              :test_action, scope: scope, resource_key: resource_key, threshold: threshold, interval: interval
            )
          ).to eq(false)
        end
      end
    end

    context 'when tracking resource usage throttles' do
      let(:histogram_double) { instance_double(Prometheus::Client::Histogram) }

      around do |example|
        # check if defined
        if described_class.instance_variable_defined?(:@application_rate_limiter_histogram)
          described_class.remove_instance_variable(:@application_rate_limiter_histogram)
        end

        example.run

        described_class.remove_instance_variable(:@application_rate_limiter_histogram)
      end

      it 'observe histogram metrics using a memoized histogram instance' do
        expect(Gitlab::Metrics).to receive(:histogram)
          .once
          .with(
            :gitlab_application_rate_limiter_throttle_utilization_ratio,
            "The utilization-ratio of a throttle.",
            { peek: nil, throttle_key: nil, feature_category: nil },
            described_class::LIMIT_USAGE_BUCKET
          )
          .and_return(histogram_double)
        expect(histogram_double).to receive(:observe).twice

        subject.resource_usage_throttled?(
          :test_action, scope: [], resource_key: resource_key, threshold: threshold, interval: interval)
        subject.resource_usage_throttled?(
          :test_action, scope: [], resource_key: resource_key, threshold: threshold, interval: interval)
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

      it 'returns false when interval has elapsed', :aggregate_failures do
        travel_to(start_time) do
          expect(
            subject.resource_usage_throttled?(
              :test_action, scope: scope, resource_key: resource_key, threshold: threshold, interval: interval
            )
          ).to eq(false)

          # another_action has a threshold of 2 so we simulate 2 requests
          expect(
            subject.resource_usage_throttled?(
              :another_action, scope: scope, resource_key: resource_key_2, threshold: threshold * 2, interval: interval
            )
          ).to eq(false)
          expect(
            subject.resource_usage_throttled?(
              :another_action, scope: scope, resource_key: resource_key_2, threshold: threshold * 2, interval: interval
            )
          ).to eq(false)
        end

        travel_to(start_time + 2.minutes) do
          expect(
            subject.resource_usage_throttled?(
              :test_action, scope: scope, resource_key: resource_key, threshold: threshold, interval: interval
            )
          ).to eq(false)

          # Assert that another_action has its own interval that hasn't elapsed
          expect(
            subject.resource_usage_throttled?(
              :test_action, scope: scope, resource_key: resource_key, threshold: threshold, interval: interval
            )
          ).to eq(true)
        end
      end
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
        remote_ip: request.ip,
        request_method: 'GET',
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
    let(:rate_limits) { { test_action: { threshold: 1, interval: 0 } } }
    let(:scope) { user }
    let(:start_time) { Time.current.beginning_of_hour }

    it_behaves_like 'returns false'
  end

  context 'when threshold is 0' do
    let(:rate_limits) { { test_action: { threshold: 0, interval: 1 } } }
    let(:scope) { user }
    let(:start_time) { Time.current.beginning_of_hour }

    before do
      if described_class.instance_variable_defined?(:@application_rate_limiter_histogram)
        described_class.remove_instance_variable(:@application_rate_limiter_histogram)
      end
    end

    it_behaves_like 'returns false'

    it 'does not observe any histogram metrics' do
      expect(Gitlab::Metrics).not_to receive(:histogram)

      subject.throttled?(:test_action, scope: [])
    end
  end
end
