# frozen_string_literal: true

require "spec_helper"

RSpec.describe Gitlab::InternalEvents, :snowplow, feature_category: :product_analytics_data_management do
  include TrackingHelpers
  include SnowplowHelpers

  before do
    allow(Gitlab::AppJsonLogger).to receive(:warn)
    allow(Gitlab::ErrorTracking).to receive(:track_and_raise_for_dev_exception)
    allow(Gitlab::UsageDataCounters::HLLRedisCounter).to receive(:track_event)
    allow(redis).to receive(:incr)
    allow(Gitlab::Redis::SharedState).to receive(:with).and_yield(redis)
    allow(Gitlab::Tracking).to receive(:tracker).and_return(fake_snowplow)
    allow(Gitlab::InternalEvents::EventDefinitions).to receive(:unique_property).and_return(unique_property)
    allow(fake_snowplow).to receive(:event)
  end

  shared_examples 'an event that logs an error' do
    it 'logs an error' do
      described_class.track_event(event_name, **event_kwargs)

      expect(Gitlab::ErrorTracking).to have_received(:track_and_raise_for_dev_exception)
        .with(described_class::InvalidPropertyTypeError,
          event_name: event_name,
          kwargs: event_kwargs
        )
    end
  end

  def expect_redis_hll_tracking
    expect(Gitlab::UsageDataCounters::HLLRedisCounter).to have_received(:track_event)
      .with(event_name, values: unique_value)
  end

  def expect_redis_tracking
    call_index = 0
    expect(redis).to have_received(:incr).twice do |redis_key|
      expect(redis_key).to end_with(redis_arguments[call_index])
      call_index += 1
    end
  end

  def expect_snowplow_tracking(expected_namespace = nil)
    service_ping_context = Gitlab::Tracking::ServicePingContext
      .new(data_source: :redis_hll, event: event_name)
      .to_context
      .to_json

    expect(SnowplowTracker::SelfDescribingJson).to have_received(:new)
      .with(service_ping_context[:schema], service_ping_context[:data]).at_least(:once)

    expect(fake_snowplow).to have_received(:event) do |category, provided_event_name, args|
      expect(category).to eq('InternalEventTracking')
      expect(provided_event_name).to eq(event_name)

      contexts = args[:context]&.map(&:to_json)

      # Verify Standard Context
      standard_context = contexts.find do |c|
        c[:schema] == Gitlab::Tracking::StandardContext::GITLAB_STANDARD_SCHEMA_URL
      end

      validate_standard_context(standard_context, expected_namespace)

      # Verify Service Ping context
      service_ping_context = contexts.find { |c| c[:schema] == Gitlab::Tracking::ServicePingContext::SCHEMA_URL }

      validate_service_ping_context(service_ping_context)
    end
  end

  def validate_standard_context(standard_context, expected_namespace)
    namespace = expected_namespace || project&.namespace
    expect(standard_context).not_to eq(nil)
    expect(standard_context[:data][:user_id]).to eq(user&.id)
    expect(standard_context[:data][:namespace_id]).to eq(namespace&.id)
    expect(standard_context[:data][:project_id]).to eq(project&.id)
  end

  def validate_service_ping_context(service_ping_context)
    expect(service_ping_context).not_to eq(nil)
    expect(service_ping_context[:data][:data_source]).to eq(:redis_hll)
    expect(service_ping_context[:data][:event_name]).to eq(event_name)
  end

  let_it_be(:user) { build(:user, id: 1) }
  let_it_be(:project_namespace) { build(:namespace, id: 2) }
  let_it_be(:project) { build(:project, id: 3, namespace: project_namespace) }

  let(:redis) { instance_double('Redis') }
  let(:fake_snowplow) { instance_double(Gitlab::Tracking::Destinations::Snowplow) }
  let(:event_name) { 'g_edit_by_web_ide' }
  let(:unique_property) { :user }
  let(:unique_value) { user.id }
  let(:redis_arguments) { [event_name, Date.today.strftime('%G-%V')] }

  context 'when only user is passed' do
    let(:project) { nil }
    let(:namespace) { nil }

    it 'updated all tracking methods' do
      described_class.track_event(event_name, user: user)

      expect_redis_tracking
      expect_redis_hll_tracking
      expect_snowplow_tracking
    end
  end

  context 'when namespace is passed' do
    let(:namespace) { build(:namespace, id: 4) }

    it 'uses id from namespace' do
      described_class.track_event(event_name, user: user, project: project, namespace: namespace)

      expect_redis_tracking
      expect_redis_hll_tracking
      expect_snowplow_tracking(namespace)
    end
  end

  context 'when namespace is not passed' do
    let(:unique_property) { :namespace }
    let(:unique_value) { project.namespace.id }

    it 'uses id from projects namespace' do
      described_class.track_event(event_name, user: user, project: project)

      expect_redis_tracking
      expect_redis_hll_tracking
      expect_snowplow_tracking(project.namespace)
    end
  end

  context 'when arguments are invalid' do
    context 'when user is not an instance of User' do
      let(:user) { 'a_string' }

      it_behaves_like 'an event that logs an error' do
        let(:event_kwargs) { { user: user, project: project.id } }
      end
    end

    context 'when project is not an instance of Project' do
      let(:project) { 42 }

      it_behaves_like 'an event that logs an error' do
        let(:event_kwargs) { { user: user.id, project: project } }
      end
    end

    context 'when namespace is not an instance of Namespace' do
      let(:namespace) { false }

      it_behaves_like 'an event that logs an error' do
        let(:event_kwargs) { { user: user.id, namespace: namespace } }
      end
    end
  end

  it 'updates Redis, RedisHLL and Snowplow', :aggregate_failures do
    described_class.track_event(event_name, user: user, project: project)

    expect_redis_tracking
    expect_redis_hll_tracking
    expect_snowplow_tracking
  end

  it 'rescues error', :aggregate_failures do
    params = { user: user, project: project }
    error = StandardError.new("something went wrong")
    allow(fake_snowplow).to receive(:event).and_raise(error)

    expect(Gitlab::ErrorTracking).to receive(:track_and_raise_for_dev_exception)
      .with(
        error,
        snowplow_category: 'InternalEventTracking',
        snowplow_action: event_name
      )

    expect { described_class.track_event(event_name, **params) }.not_to raise_error
  end

  it 'logs error on unknown event', :aggregate_failures do
    expect(Gitlab::ErrorTracking).to receive(:track_and_raise_for_dev_exception)
      .with(described_class::UnknownEventError, event_name: 'unknown_event', kwargs: {})

    expect { described_class.track_event('unknown_event') }.not_to raise_error
  end

  it 'logs warning on missing property', :aggregate_failures do
    expect { described_class.track_event(event_name, merge_request_id: 1) }.not_to raise_error

    expect_redis_tracking
    expect(Gitlab::AppJsonLogger).to have_received(:warn)
      .with(message: /should be triggered with a named parameter/)
  end

  context 'when unique property is missing' do
    before do
      allow(Gitlab::InternalEvents::EventDefinitions).to receive(:unique_property)
        .and_raise(Gitlab::InternalEvents::EventDefinitions::InvalidMetricConfiguration)
    end

    it 'logs error on missing unique property', :aggregate_failures do
      expect { described_class.track_event(event_name, merge_request_id: 1) }.not_to raise_error

      expect_redis_tracking
      expect(Gitlab::ErrorTracking).to have_received(:track_and_raise_for_dev_exception)
    end
  end

  context 'when unique key is defined' do
    let(:event_name) { 'p_ci_templates_terraform_base_latest' }
    let(:unique_value) { project.id }
    let(:property_name) { :project }

    before do
      allow(Gitlab::InternalEvents::EventDefinitions).to receive(:unique_property)
        .with(event_name)
        .and_return(property_name)
    end

    it 'is used when logging to RedisHLL', :aggregate_failures do
      described_class.track_event(event_name, user: user, project: project)

      expect_redis_tracking
      expect_redis_hll_tracking
      expect_snowplow_tracking
    end

    context 'when property is missing' do
      it 'logs error' do
        expect { described_class.track_event(event_name, merge_request_id: 1) }.not_to raise_error

        expect(Gitlab::AppJsonLogger).to have_received(:warn)
          .with(message: /should be triggered with a named parameter/)
      end
    end

    context 'when send_snowplow_event is false' do
      it 'logs to Redis and RedisHLL but not Snowplow' do
        described_class.track_event(event_name, send_snowplow_event: false, user: user, project: project)

        expect_redis_tracking
        expect_redis_hll_tracking
        expect(fake_snowplow).not_to have_received(:event)
      end
    end
  end

  context 'when unique key is not defined' do
    let(:event_name) { 'p_ci_templates_terraform_base_latest' }

    before do
      allow(Gitlab::InternalEvents::EventDefinitions).to receive(:unique_property)
        .with(event_name)
        .and_return(nil)
    end

    it 'logs to Redis and Snowplow but not RedisHLL', :aggregate_failures do
      described_class.track_event(event_name, user: user, project: project)

      expect_redis_tracking
      expect_snowplow_tracking(project.namespace)
      expect(Gitlab::UsageDataCounters::HLLRedisCounter).not_to have_received(:track_event)
    end
  end

  describe 'Product Analytics tracking' do
    let(:app_id) { 'foobar' }
    let(:url) { 'http://localhost:4000' }
    let(:sdk_client) { instance_double('GitlabSDK::Client') }
    let(:event_kwargs) { { user: user, project: project } }

    before do
      described_class.clear_memoization(:gitlab_sdk_client)

      stub_env('GITLAB_ANALYTICS_ID', app_id)
      stub_env('GITLAB_ANALYTICS_URL', url)
    end

    subject(:track_event) { described_class.track_event(event_name, **event_kwargs) }

    shared_examples 'does not send a Product Analytics event' do
      it 'does not call the Product Analytics Ruby SDK' do
        expect(GitlabSDK::Client).not_to receive(:new)

        track_event
      end
    end

    context 'when internal_events_for_product_analytics FF is enabled' do
      before do
        stub_feature_flags(internal_events_for_product_analytics: true)

        allow(GitlabSDK::Client)
          .to receive(:new)
          .with(app_id: app_id, host: url)
          .and_return(sdk_client)
      end

      it 'calls Product Analytics Ruby SDK', :aggregate_failures do
        expect(sdk_client).to receive(:identify).with(user.id)
        expect(sdk_client).to receive(:track)
          .with(event_name, { project_id: project.id, namespace_id: project.namespace.id })

        track_event
      end

      context 'when GITLAB_ANALYTICS_ID is nil' do
        let(:app_id) { nil }

        it_behaves_like 'does not send a Product Analytics event'
      end

      context 'when GITLAB_ANALYTICS_URL is nil' do
        let(:url) { nil }

        it_behaves_like 'does not send a Product Analytics event'
      end
    end

    context 'when internal_events_for_product_analytics FF is disabled' do
      let(:app_id) { 'foobar' }
      let(:url) { 'http://localhost:4000' }

      before do
        stub_feature_flags(internal_events_for_product_analytics: false)
      end

      it_behaves_like 'does not send a Product Analytics event'
    end
  end
end
