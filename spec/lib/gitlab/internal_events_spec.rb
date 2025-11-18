# frozen_string_literal: true

require "spec_helper"

RSpec.describe Gitlab::InternalEvents, :snowplow, feature_category: :product_analytics do
  include TrackingHelpers
  include SnowplowHelpers

  before do
    allow(Gitlab::AppJsonLogger).to receive(:warn)
    allow(Gitlab::ErrorTracking).to receive(:track_and_raise_for_dev_exception)
    allow(redis).to receive(:expire)
    allow(redis).to receive(:hincrby)
    allow(redis).to receive(:incr)
    allow(redis).to receive(:incrbyfloat)
    allow(redis).to receive(:multi).and_yield(redis)
    allow(redis).to receive(:pfadd)
    allow(redis).to receive(:set)
    allow(redis).to receive(:eval)
    allow(redis).to receive(:ttl).and_return(123456)
    allow(Gitlab::SidekiqMiddleware::ConcurrencyLimit::ConcurrencyLimitService).to receive(:has_jobs_in_queue?)
                                                                                     .and_return(false)
    allow(Gitlab::Redis::SharedState).to receive(:with).and_yield(redis)
    allow(Gitlab::Tracking).to receive(:tracker).and_return(fake_snowplow)
    allow(Gitlab::Tracking::EventDefinition).to receive_messages(find: event_definition, internal_event_exists?: true)
    allow_next_instance_of(Gitlab::Tracking::EventValidator) do |instance|
      allow(instance).to receive(:validate!)
    end
    allow(event_definition).to receive_messages(
      event_selection_rules: event_selection_rules,
      raw_attributes: {},
      additional_properties: additional_properties,
      extra_trackers: {}
    )
    allow(fake_snowplow).to receive(:event)
  end

  def expect_redis_hll_tracking(value_override = nil, property_name_override = nil)
    expected_value = value_override || unique_value
    expected_property_name = property_name_override || property_name

    key_expectations = satisfy do |key|
      key.include?(event_name) &&
        key.include?(expected_property_name.to_s) &&
        key.end_with?(week_suffix)
    end

    expect(redis).to have_received(:pfadd).with(key_expectations, [expected_value])
    expect(redis).to have_received(:expire).with(key_expectations, described_class::KEY_EXPIRY_LENGTH)
  end

  def expect_redis_hash_counter_tracking(value_override = nil, property_name_override = nil)
    expected_value = value_override || additional_properties[:label]
    expected_property_name = property_name_override || :label

    key_expectations = satisfy do |key|
      key.include?(event_name) &&
        key.include?(expected_property_name.to_s) &&
        key.include?('operator:total') &&
        key.end_with?(week_suffix)
    end

    expect(redis).to have_received(:hincrby).with(key_expectations, expected_value, 1)
    expect(redis).to have_received(:ttl).with(key_expectations)
  end

  def expect_no_redis_hll_tracking
    expect(redis).not_to have_received(:pfadd)
  end

  def expect_redis_tracking
    redis_arguments.each do |redis_argument|
      expect(redis).to have_received(:incr).with(a_string_ending_with(redis_argument)).once
    end
  end

  def expect_redis_sum_tracking(value)
    redis_arguments.each do |redis_argument|
      expect(redis).to have_received(:incrbyfloat).with(a_string_including(redis_argument), value).once
    end
  end

  def expect_snowplow_tracking(expected_namespace = nil, expected_additional_properties = {}, extra: {})
    service_ping_context = Gitlab::Tracking::ServicePingContext
      .new(data_source: :redis_hll, event: event_name)
      .to_context
      .to_json

    expect(SnowplowTracker::SelfDescribingJson).to have_received(:new)
      .with(service_ping_context[:schema], service_ping_context[:data]).at_least(:once)

    expect(fake_snowplow).to have_received(:event) do |provided_category, provided_event_name, args|
      expect(provided_category).to eq(category)
      expect(provided_event_name).to eq(event_name)

      expect(args).to include(expected_additional_properties)
      contexts = args[:context]&.map(&:to_json)

      # Verify Standard Context
      standard_context = contexts.find do |c|
        c[:schema] == Gitlab::Tracking::StandardContext::GITLAB_STANDARD_SCHEMA_URL
      end

      validate_standard_context(standard_context, expected_namespace, extra)

      # Verify Service Ping context
      service_ping_context = contexts.find { |c| c[:schema] == Gitlab::Tracking::ServicePingContext::SCHEMA_URL }

      validate_service_ping_context(service_ping_context)
    end
  end

  def validate_standard_context(standard_context, expected_namespace, extra)
    namespace = expected_namespace || project&.namespace
    expect(standard_context).not_to eq(nil)
    expect(standard_context[:data][:user_id]).to eq(Gitlab::CryptoHelper.sha256(user&.id)) if user
    expect(standard_context[:data][:namespace_id]).to eq(namespace&.id)
    expect(standard_context[:data][:project_id]).to eq(project&.id)
    expect(standard_context[:data][:extra]).to eq(extra)
  end

  def validate_service_ping_context(service_ping_context)
    expect(service_ping_context).not_to eq(nil)
    expect(service_ping_context[:data][:data_source]).to eq(:redis_hll)
    expect(service_ping_context[:data][:event_name]).to eq(event_name)
  end

  let_it_be(:user) { build(:user, id: 1) }
  let_it_be(:project_namespace) { build(:namespace, id: 2) }
  let_it_be(:project) { build(:project, id: 3, namespace: project_namespace) }
  let_it_be(:additional_properties) { {} }

  let(:redis) { instance_double('Redis') }
  let(:event_definition) { instance_double(Gitlab::Tracking::EventDefinition) }
  let(:event_selection_rules) do
    [
      Gitlab::Usage::EventSelectionRule.new(name: event_name, time_framed: false),
      Gitlab::Usage::EventSelectionRule.new(name: event_name, time_framed: true),
      Gitlab::Usage::EventSelectionRule.new(name: event_name, time_framed: true, unique_identifier_name: :user),
      Gitlab::Usage::EventSelectionRule.new(name: event_name, time_framed: true, operator: 'sum(value)')
    ]
  end

  let(:fake_snowplow) { instance_double(Gitlab::Tracking::Destinations::Snowplow) }
  let(:event_name) { 'an_event' }
  let(:category) { 'InternalEventTracking' }
  let(:unique_value) { user.id }
  let(:property_name) { :user }
  let(:week_suffix) { Date.today.strftime('%G-%V') }
  let(:redis_arguments) { [event_name, week_suffix] }

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
    it 'uses id from projects namespace' do
      described_class.track_event(event_name, user: user, project: project)

      expect_redis_tracking
      expect_redis_hll_tracking
      expect_snowplow_tracking(project.namespace)
    end
  end

  context 'when category is passed' do
    let(:category) { 'SomeCategory' }

    it 'is sent to Snowplow' do
      described_class.track_event(event_name, category: category, user: user, project: project)

      expect_snowplow_tracking
    end
  end

  context 'when additional properties are passed' do
    let(:additional_properties) do
      {
        label: 'label_name',
        property: 'property_name',
        value: 16.17
      }
    end

    let(:properties) { additional_properties }

    subject(:track_event) do
      described_class.track_event(
        event_name,
        additional_properties: properties,
        user: user,
        project: project
      )
    end

    it 'is sent to Snowplow' do
      track_event

      expect_snowplow_tracking(nil, additional_properties)
    end

    it 'updates sums' do
      track_event

      expect_redis_sum_tracking(16.17)
    end

    context 'with a custom property' do
      let(:properties) do
        additional_properties.merge(custom: 'custom_property')
      end

      before do
        allow(event_definition).to receive(:additional_properties).and_return(properties)
      end

      it 'is sent to Snowplow' do
        track_event

        expect_snowplow_tracking(nil, additional_properties, extra: { custom: 'custom_property' })
      end
    end

    context 'when a filter is defined' do
      let(:time_framed) { true }
      let(:event_selection_rules) do
        [
          Gitlab::Usage::EventSelectionRule.new(name: event_name, time_framed: time_framed),
          Gitlab::Usage::EventSelectionRule.new(
            name: event_name,
            time_framed: time_framed,
            filter: { label: 'label_name' }
          ),
          Gitlab::Usage::EventSelectionRule.new(
            name: event_name,
            time_framed: time_framed,
            filter: { label: 'another_label_value' }
          ),
          Gitlab::Usage::EventSelectionRule.new(
            name: event_name,
            time_framed: time_framed,
            filter: { label: 'label_name', value: 16.17 }
          ),
          Gitlab::Usage::EventSelectionRule.new(
            name: event_name,
            time_framed: time_framed,
            filter: { custom: 'custom_property' }
          )
        ]
      end

      context 'when event selection rule is time framed' do
        let(:redis_arguments) do
          [
            "filter:[label:label_name]-#{week_suffix}",
            "filter:[label:label_name,value:16.17]-#{week_suffix}",
            "#{event_name}-#{week_suffix}"
          ]
        end

        it 'updates the correct redis keys' do
          described_class.track_event(
            event_name,
            additional_properties: additional_properties,
            user: user,
            project: project
          )

          expect_redis_tracking
        end
      end

      context 'when event selection rule has a filter on a custom property' do
        let(:custom_properties) { { custom: 'custom_property' } }
        let(:redis_arguments) do
          [
            "filter:[custom:custom_property]-#{week_suffix}",
            "#{event_name}-#{week_suffix}"
          ]
        end

        before do
          allow(event_definition).to receive(:additional_properties)
                                       .and_return(additional_properties.merge(custom_properties))
        end

        it 'updates the correct redis keys' do
          described_class.track_event(
            event_name,
            additional_properties: custom_properties,
            user: user,
            project: project
          )

          expect_redis_tracking
        end
      end

      context 'when redis key is overridden in total_counter_redis_key_overrides.yml' do
        let(:time_framed) { false }
        let(:redis_arguments) { %w[SOME_LEGACY_KEY ANOTHER_LEGACY_KEY A_THIRD_LEGACY_KEY] }

        let(:override_yaml) do
          <<~YAML
            '{event_counters}_#{event_name}-filter:[label:label_name]': #{redis_arguments[0]}
            '{event_counters}_#{event_name}-filter:[label:label_name,value:16.17]': #{redis_arguments[1]}
            '{event_counters}_#{event_name}': #{redis_arguments[2]}
          YAML
        end

        before do
          described_class.clear_memoization(:key_overrides)
          allow(File).to receive(:read).and_call_original
          allow(File).to receive(:read)
            .with(Gitlab::UsageDataCounters::RedisCounter::KEY_OVERRIDES_PATH)
            .and_return(override_yaml)
        end

        after do
          described_class.clear_memoization(:key_overrides)
        end

        it 'updates the matching redis keys' do
          described_class.track_event(
            event_name,
            additional_properties: additional_properties,
            user: user,
            project: project
          )

          expect_redis_tracking
        end
      end

      context 'when event selection rule is not time framed' do
        let(:time_framed) { false }
        let(:redis_arguments) do
          [
            "filter:[label:label_name]",
            "filter:[label:label_name,value:16.17]",
            event_name.to_s
          ]
        end

        context 'when a matching event is tracked' do
          it 'updates the matching redis keys' do
            described_class.track_event(
              event_name,
              additional_properties: additional_properties,
              user: user,
              project: project
            )

            expect_redis_tracking
          end
        end

        context 'when a non-matching event is tracked' do
          let(:additional_properties) { { label: 'unrelated_string' } }
          let(:redis_arguments) { [event_name.to_s] }

          it 'updates only the matching redis keys' do
            described_class.track_event(
              event_name,
              additional_properties: additional_properties,
              user: user,
              project: project
            )

            expect_redis_tracking
          end
        end
      end
    end

    context 'when additional properties are not defined in the event definition' do
      let(:properties) { additional_properties.merge(unknown: 'unknown') }

      it 'does not send the additional properties to Snowplow' do
        track_event

        expect_snowplow_tracking(nil, additional_properties, extra: {})
      end
    end
  end

  context 'when feature_enabled_by_namespace_ids is passed' do
    let(:feature_enabled_by_namespace_ids) { [1, 2, 3] }

    it 'is sent to Snowplow' do
      described_class.track_event(
        event_name,
        user: user,
        project: project,
        feature_enabled_by_namespace_ids: feature_enabled_by_namespace_ids
      )

      expect(fake_snowplow).to have_received(:event) do |_, _, args|
        contexts = args[:context]&.map(&:to_json)

        standard_context = contexts.find do |c|
          c[:schema] == Gitlab::Tracking::StandardContext::GITLAB_STANDARD_SCHEMA_URL
        end

        expect(standard_context[:data][:feature_enabled_by_namespace_ids]).to eq(feature_enabled_by_namespace_ids)
      end
    end
  end

  it 'calls the event validator' do
    fake_validator = instance_double(Gitlab::Tracking::EventValidator, validate!: nil)
    additional_properties = { label: 'label_name', value: 16.17, property: "lang" }
    kwargs = { user: user, project: project }

    expect(Gitlab::Tracking::EventValidator)
      .to receive(:new)
      .with(event_name, additional_properties, kwargs)
      .and_return(fake_validator)
    expect(fake_validator).to receive(:validate!)

    described_class.track_event(event_name, additional_properties: additional_properties, **kwargs)
  end

  it 'updates Redis, RedisHLL and Snowplow', :aggregate_failures do
    described_class.track_event(event_name, user: user, project: project)

    expect_redis_tracking
    expect_redis_hll_tracking
    expect_snowplow_tracking
  end

  describe 'errors handling' do
    let(:params) { { user: user, project: project } }
    let(:error) { StandardError.new("something went wrong") }

    it 'rescues error from tracking', :aggregate_failures do
      allow(fake_snowplow).to receive(:event).and_raise(error)

      expect(Gitlab::ErrorTracking).to receive(:track_and_raise_for_dev_exception)
        .with(
          error,
          snowplow_category: 'InternalEventTracking',
          snowplow_action: event_name
        )

      expect { described_class.track_event(event_name, **params) }.not_to raise_error
    end

    it 'rescues error from validator' do
      allow_next_instance_of(Gitlab::Tracking::EventValidator) do |instance|
        allow(instance).to receive(:validate!).and_raise(error)
      end

      expect { described_class.track_event(event_name, **params) }.not_to raise_error
    end

    context 'when error occurs in track_event' do
      let(:error) { StandardError.new("tracking failed") }

      before do
        allow_next_instance_of(Gitlab::Tracking::EventValidator) do |instance|
          allow(instance).to receive(:validate!).and_raise(error)
        end
      end

      context 'on GitLab.com' do
        before do
          allow(Gitlab).to receive_messages(com?: true, dev_or_test_env?: false)
        end

        it 'raises exception via ErrorTracking' do
          expect(Gitlab::ErrorTracking).to receive(:track_and_raise_for_dev_exception)
            .with(
              error,
              hash_including(
                server_version: Gitlab::VERSION,
                event_name: event_name,
                additional_properties: {},
                kwargs: hash_including(user: user.id, project: project.id)
              )
            )

          described_class.track_event(event_name, **params)
        end
      end

      context 'in dev/test environment' do
        before do
          allow(Gitlab).to receive_messages(com?: false, dev_or_test_env?: true)
        end

        it 'raises exception via ErrorTracking' do
          expect(Gitlab::ErrorTracking).to receive(:track_and_raise_for_dev_exception)
            .with(
              error,
              hash_including(
                server_version: Gitlab::VERSION,
                event_name: event_name
              )
            )

          described_class.track_event(event_name, **params)
        end
      end

      context 'on self-managed instance' do
        before do
          allow(Gitlab).to receive_messages(com?: false, dev_or_test_env?: false)
        end

        it 'logs warning without raising exception' do
          expect(Gitlab::AppLogger).to receive(:warn)
            .with(
              error,
              hash_including(
                server_version: Gitlab::VERSION,
                event_name: event_name,
                additional_properties: {},
                kwargs: hash_including(user: user.id, project: project.id)
              )
            )

          expect(Gitlab::ErrorTracking).not_to receive(:track_and_raise_for_dev_exception)

          described_class.track_event(event_name, **params)
        end
      end
    end
  end

  it 'logs warning on missing property', :aggregate_failures do
    expect { described_class.track_event(event_name, merge_request_id: 1) }.not_to raise_error

    expect_redis_tracking
    expect(Gitlab::AppJsonLogger).to have_received(:warn)
      .with(message: /should be triggered with a named parameter/)
  end

  it 'logs warning on nil property', :aggregate_failures do
    expect { described_class.track_event(event_name, user: nil) }.not_to raise_error

    expect_redis_tracking
    expect(Gitlab::AppJsonLogger).to have_received(:warn)
      .with(message: /should be triggered with a named parameter/)
  end

  context 'when unique key is defined' do
    it 'is used when logging to RedisHLL', :aggregate_failures do
      described_class.track_event(event_name, user: user, project: project)

      expect_redis_tracking
      expect_redis_hll_tracking
      expect_snowplow_tracking
    end

    context 'when property is missing' do
      let(:unique_value) { user.id }
      let(:property_name) { :user }
      let(:user) { nil }
      let(:project) { nil }
      let(:namespace) { nil }

      it 'logs error' do
        expect { described_class.track_event(event_name, merge_request_id: 1) }.not_to raise_error

        expect(Gitlab::AppJsonLogger).to have_received(:warn)
          .with(message: /should be triggered with a named parameter/)
      end

      it 'updates Redis and snowplow but not RedisHLL' do
        described_class.track_event(event_name, merge_request_id: 1)

        expect_redis_tracking
        expect_no_redis_hll_tracking
        expect_snowplow_tracking
      end
    end

    context 'when there are multiple unique keys' do
      let(:event_selection_rules) do
        [
          Gitlab::Usage::EventSelectionRule.new(name: event_name, time_framed: false),
          Gitlab::Usage::EventSelectionRule.new(name: event_name, time_framed: true),
          Gitlab::Usage::EventSelectionRule.new(name: event_name, time_framed: true, unique_identifier_name: :user),
          Gitlab::Usage::EventSelectionRule.new(name: event_name, time_framed: true, unique_identifier_name: :project)
        ]
      end

      it 'all of them are used when logging to RedisHLL', :aggregate_failures do
        described_class.track_event(event_name, user: user, project: project)

        expect_redis_tracking
        expect_redis_hll_tracking(user.id, :user)
        expect_redis_hll_tracking(project.id, :project)
        expect_snowplow_tracking
      end
    end

    context 'when unique key is an additional property' do
      let(:event_selection_rules) do
        [
          Gitlab::Usage::EventSelectionRule.new(name: event_name, time_framed: false),
          Gitlab::Usage::EventSelectionRule.new(name: event_name, time_framed: true),
          Gitlab::Usage::EventSelectionRule.new(name: event_name, time_framed: true, unique_identifier_name: :label)
        ]
      end

      it 'is used when logging to RedisHLL', :aggregate_failures do
        described_class.track_event(event_name, user: user, project: project, label: 'label')

        expect_redis_tracking
        expect_redis_hll_tracking('label'.hash, :label)
        expect_snowplow_tracking
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
    let(:event_selection_rules) do
      [
        Gitlab::Usage::EventSelectionRule.new(name: event_name, time_framed: false),
        Gitlab::Usage::EventSelectionRule.new(name: event_name, time_framed: true)
      ]
    end

    it 'logs to Redis and Snowplow but not RedisHLL', :aggregate_failures do
      described_class.track_event(event_name, user: user, project: project)

      expect_redis_tracking
      expect_no_redis_hll_tracking
      expect_snowplow_tracking(project.namespace)
    end
  end

  describe 'custom tracking classes' do
    let(:extra_properties) { { private_property: 'private_prop' } }
    let(:event_kwargs) do
      additional_properties.merge(extra_properties).merge({ user: user, project: project })
    end

    let(:custom_tracking_class) do
      Class.new do
        def self.track_event(event_name, **kwargs); end
      end
    end

    context 'when custom classes are defined' do
      before do
        custom_tracking = { custom_tracking_class => { extra_properties: [:private_property] } }
        allow(event_definition).to receive(:extra_trackers).and_return(custom_tracking)
      end

      context 'when event is not defined' do
        let(:event_name) { 'an_event_that_does_not_exist' }

        before do
          allow(Gitlab::Tracking::EventDefinition).to receive(:find).with(event_name).and_return(nil)
        end

        it 'does not call custom classes' do
          expect(custom_tracking_class).not_to receive(:track_event)

          described_class.track_event(event_name, user: user, project: project)
        end
      end

      it 'calls the custom classes with extra tracking properties' do
        expect(custom_tracking_class).to receive(:track_event).with(event_name, **event_kwargs)

        # expected_kwags= event_kwargs.merge(private_property: 'private_prop')
        described_class.track_event(event_name, **event_kwargs)
      end
    end
  end

  context 'when unique total counter is defined' do
    let(:event_selection_rules) do
      [
        Gitlab::Usage::EventSelectionRule.new(name: event_name, time_framed: false),
        Gitlab::Usage::EventSelectionRule.new(name: event_name, time_framed: true),
        Gitlab::Usage::EventSelectionRule.new(
          name: event_name,
          time_framed: true,
          unique_identifier_name: :label,
          operator: 'total'
        )
      ]
    end

    let(:additional_properties) { { label: 'label_value' } }

    it 'updates Redis hash counter, standard Redis counter and Snowplow', :aggregate_failures do
      described_class.track_event(
        event_name,
        additional_properties: additional_properties,
        user: user,
        project: project
      )

      expect_redis_tracking
      expect_redis_hash_counter_tracking
      expect_snowplow_tracking(project.namespace, additional_properties)
    end

    context 'when no expiry is needed' do
      let(:event_selection_rules) do
        [
          Gitlab::Usage::EventSelectionRule.new(
            name: event_name,
            time_framed: false,
            unique_identifier_name: :label,
            operator: 'total'
          )
        ]
      end

      it 'does not set expiry' do
        described_class.track_event(
          event_name,
          additional_properties: additional_properties,
          user: user,
          project: project
        )

        expect(redis).to have_received(:hincrby).with(a_string_including(event_name), 'label_value', 1)
        expect(redis).not_to have_received(:ttl)
        expect(redis).not_to have_received(:expire)
      end
    end

    context 'when property is missing' do
      let(:additional_properties) { {} }

      it 'does not update Redis hash counter' do
        described_class.track_event(
          event_name,
          additional_properties: additional_properties,
          user: user,
          project: project
        )

        expect(redis).not_to have_received(:hincrby)
      end
    end

    context 'with a filter defined' do
      let(:event_selection_rules) do
        [
          Gitlab::Usage::EventSelectionRule.new(
            name: event_name,
            time_framed: true,
            unique_identifier_name: :label,
            operator: 'total',
            filter: { category: 'package' }
          )
        ]
      end

      context 'when event matches the filter' do
        let(:additional_properties) do
          {
            label: 'label_value',
            category: 'package'
          }
        end

        it 'updates Redis hash counter' do
          described_class.track_event(
            event_name,
            additional_properties: additional_properties,
            user: user,
            project: project
          )

          expect(redis).to have_received(:hincrby)
        end
      end

      context 'when event does not match the filter' do
        let(:additional_properties) do
          {
            label: 'label_value',
            category: 'not_package'
          }
        end

        it 'does not update Redis hash counter' do
          described_class.track_event(
            event_name,
            additional_properties: additional_properties,
            user: user,
            project: project
          )

          expect(redis).not_to have_received(:hincrby)
        end
      end
    end

    context 'when existing TTL is present' do
      before do
        allow(redis).to receive(:ttl).and_return(1)
      end

      it 'does not override the existing expiry' do
        described_class.track_event(
          event_name,
          additional_properties: additional_properties,
          user: user,
          project: project
        )

        expect(redis).to have_received(:hincrby)
        expect(redis).not_to have_received(:expire)
      end
    end
  end

  describe 'dynamic additional_properties extraction' do
    let(:user) { build(:user) }
    let(:project) { build(:project) }

    before do
      allow(event_definition).to receive(:additional_properties).and_return({
        label: {},
        property: {},
        value: {}
      })
    end

    context 'when additional_properties is empty and kwargs contain matching keys' do
      it 'extracts base properties from kwargs into additional_properties for snowplow tracking' do
        described_class.track_event(
          event_name,
          user: user,
          project: project,
          label: 'test_label',
          property: 'test_property',
          value: 42
        )

        expect_snowplow_tracking(
          project.namespace,
          {
            label: 'test_label',
            property: 'test_property',
            value: 42
          }
        )
      end

      it 'does not extract properties when additional_properties is already provided' do
        described_class.track_event(
          event_name,
          additional_properties: { label: 'existing_label' },
          user: user,
          project: project,
          label: 'test_label',
          property: 'test_property'
        )

        expect_snowplow_tracking(
          project.namespace,
          { label: 'existing_label' }
        )
      end

      it 'only extracts properties that exist in event definition' do
        allow(event_definition).to receive(:additional_properties).and_return({
          label: {}
        })

        described_class.track_event(
          event_name,
          user: user,
          project: project,
          label: 'test_label',
          property: 'test_property',
          unknown_key: 'unknown_value'
        )

        expect_snowplow_tracking(
          project.namespace,
          { label: 'test_label' }
        )
      end

      it 'extracts custom additional properties defined in event definition' do
        allow(event_definition).to receive(:additional_properties).and_return({
          label: {},
          property: {},
          custom_property: {}
        })

        described_class.track_event(
          event_name,
          user: user,
          project: project,
          label: 'test_label',
          property: 'test_property',
          custom_property: 'custom_value',
          unknown_key: 'unknown_value'
        )

        expect_snowplow_tracking(
          project.namespace,
          {
            label: 'test_label',
            property: 'test_property'
          },
          extra: { custom_property: 'custom_value' }
        )
      end

      it 'validates extracted properties and logs validation errors' do
        allow(event_definition).to receive(:additional_properties).and_return({ value: {} })

        # Override the validator mock to allow real validation
        allow_next_instance_of(Gitlab::Tracking::EventValidator) do |instance|
          allow(instance).to receive(:validate!).and_call_original
        end

        expect(Gitlab::ErrorTracking).to receive(:track_and_raise_for_dev_exception).with(
          an_instance_of(Gitlab::Tracking::EventValidator::InvalidPropertyTypeError),
          hash_including(
            event_name: event_name,
            additional_properties: { value: 'invalid_string' }
          )
        )

        described_class.track_event(
          event_name,
          user: user,
          project: project,
          value: 'invalid_string'
        )
      end
    end
  end
end
