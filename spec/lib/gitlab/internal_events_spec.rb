# frozen_string_literal: true

require "spec_helper"

RSpec.describe Gitlab::InternalEvents, :snowplow, feature_category: :product_analytics do
  include TrackingHelpers
  include SnowplowHelpers

  before do
    allow(Gitlab::AppJsonLogger).to receive(:warn)
    allow(Gitlab::ErrorTracking).to receive(:track_and_raise_for_dev_exception)
    allow(redis).to receive(:expire)
    allow(redis).to receive(:incr)
    allow(redis).to receive(:incrbyfloat)
    allow(redis).to receive(:multi).and_yield(redis)
    allow(redis).to receive(:pfadd)
    allow(redis).to receive(:set)
    allow(redis).to receive(:eval)
    allow(redis).to receive(:ttl).and_return(123456)
    allow(Gitlab::Redis::SharedState).to receive(:with).and_yield(redis)
    allow(Gitlab::Tracking).to receive(:tracker).and_return(fake_snowplow)
    allow(Gitlab::Tracking::EventDefinition).to receive_messages(find: event_definition, internal_event_exists?: true)
    allow_next_instance_of(Gitlab::Tracking::EventValidator) do |instance|
      allow(instance).to receive(:validate!)
    end
    allow(event_definition).to receive_messages(event_selection_rules: event_selection_rules, raw_attributes: {})
    allow(event_definition).to receive(:extra_tracking_classes).and_return([])
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
    expect(standard_context[:data][:user_id]).to eq(user&.id)
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

  context 'when event is not defined' do
    let(:event_name) { 'an_event_that_does_not_exist' }

    before do
      allow(Gitlab::Tracking::EventDefinition).to receive(:internal_event_exists?).with(event_name).and_return(false)
    end

    it 'logs a warning' do
      expect(Gitlab::AppJsonLogger).to receive(:warn)
        .with("InternalEvents.track_event called with undefined event: an_event_that_does_not_exist")

      described_class.track_event(event_name)
    end
  end

  describe 'Product Analytics tracking' do
    let(:app_id) { 'foobar' }
    let(:url) { 'http://localhost:4000' }
    let(:sdk_client) { instance_double('GitlabSDK::Client', identify: true) }
    let(:event_kwargs) { { user: user, project: project, send_snowplow_event: send_snowplow_event } }
    let(:additional_properties) { {} }
    let(:send_snowplow_event) { true }

    before do
      described_class.clear_memoization(:gitlab_sdk_client)

      stub_env('GITLAB_ANALYTICS_ID', app_id)
      stub_env('GITLAB_ANALYTICS_URL', url)

      stub_feature_flags(internal_events_batching: true)

      allow(GitlabSDK::Client)
        .to receive(:new)
        .with(app_id: app_id, host: url, buffer_size: described_class::SNOWPLOW_EMITTER_BUFFER_SIZE)
        .and_return(sdk_client)
    end

    after do
      described_class.clear_memoization(:gitlab_sdk_client)
    end

    subject(:track_event) do
      described_class.track_event(event_name, additional_properties: additional_properties, **event_kwargs)
    end

    shared_examples 'does not send a Product Analytics event' do
      it 'does not call the Product Analytics Ruby SDK' do
        expect(GitlabSDK::Client).not_to receive(:new)

        track_event
      end
    end

    it 'calls Product Analytics Ruby SDK', :aggregate_failures do
      expect(sdk_client).to receive(:identify).with(user.id)
      expect(sdk_client).to receive(:track)
        .with(event_name, { project_id: project.id, namespace_id: project.namespace.id })

      track_event
    end

    context 'when additional properties are passed' do
      let(:additional_properties) do
        {
          label: 'label_name',
          property: 'property_name',
          value: 16.17
        }
      end

      let(:tracked_attributes) do
        {
          project_id: project.id,
          namespace_id: project.namespace.id,
          additional_properties: additional_properties
        }
      end

      it 'passes additional_properties to Product Analytics Ruby SDK', :aggregate_failures do
        expect(sdk_client).to receive(:identify).with(user.id)
        expect(sdk_client).to receive(:track).with(event_name, tracked_attributes)

        track_event
      end
    end

    context 'when GITLAB_ANALYTICS_ID is nil' do
      let(:app_id) { nil }

      it_behaves_like 'does not send a Product Analytics event'
    end

    context 'when GITLAB_ANALYTICS_URL is nil' do
      let(:url) { nil }

      it_behaves_like 'does not send a Product Analytics event'
    end

    context 'when send_snowplow_event is false' do
      let(:send_snowplow_event) { false }

      it_behaves_like 'does not send a Product Analytics event'
    end

    context 'with internal_events_batching FF off' do
      before do
        stub_feature_flags(internal_events_batching: false)
      end

      it 'passes buffer_size 1 to SDK client' do
        expect(GitlabSDK::Client)
          .to receive(:new)
                .with(app_id: app_id, host: url, buffer_size: described_class::DEFAULT_BUFFER_SIZE)

        track_event
      end
    end

    context 'with early access program tracking' do
      let(:namespace_participating) { false }
      let(:namespace) do
        settings = create(:namespace_settings, early_access_program_participant: namespace_participating)
        create(:namespace, namespace_settings: settings)
      end

      let(:event_kwargs) do
        { user: user, project: project, send_snowplow_event: send_snowplow_event, namespace: namespace }
      end

      shared_examples 'does not create early access program tracking event' do
        it do
          track_event

          expect(user&.early_access_program_tracking_events).to be_blank
        end
      end

      before do
        allow(sdk_client).to receive(:track)
          .with(event_name, { project_id: project&.id, namespace_id: namespace&.id })
      end

      context 'when early_access_program FF is enabled' do
        before do
          stub_feature_flags(early_access_program: true)
        end

        context 'without user' do
          let(:user) { nil }

          it_behaves_like 'does not create early access program tracking event'
        end

        context 'without namespace' do
          let(:project) { nil }
          let(:namespace) { nil }

          it_behaves_like 'does not create early access program tracking event'
        end

        context 'with user' do
          context 'when namespace is not early access program participant' do
            it_behaves_like 'does not create early access program tracking event'
          end

          context 'when namespace is early access program participant' do
            let(:namespace_participating) { true }
            let(:event_name) { 'g_edit_by_snippet_ide' }
            let(:additional_properties) { { label: 'label_name' } }
            let(:user) { create(:user) }

            before do
              allow(sdk_client).to receive(:track)
                .with(
                  event_name,
                  {
                    project_id: project.id,
                    namespace_id: namespace.id,
                    additional_properties: additional_properties
                  }
                )
            end

            it 'creates user early access program event' do
              described_class.track_event(
                event_name, category: category, additional_properties: additional_properties, **event_kwargs
              )

              expect(user.early_access_program_tracking_events.size).to eq 1
              expect(user.early_access_program_tracking_events.first)
                .to have_attributes(
                  event_name: 'g_edit_by_snippet_ide', event_label: 'label_name', category: 'InternalEventTracking'
                )
            end
          end
        end
      end

      context 'when early_access_program FF is disabled' do
        before do
          stub_feature_flags(early_access_program: false)
        end

        it_behaves_like 'does not create early access program tracking event'
      end
    end
  end

  describe 'custom tracking classes' do
    let(:event_kwargs) { { additional_properties: additional_properties, user: user, project: project } }
    let(:custom_tracking_class) do
      Class.new do
        def self.track_event(event_name, **kwargs); end
      end
    end

    context 'when custom classes are defined' do
      before do
        allow(event_definition).to receive(:extra_tracking_classes).and_return([custom_tracking_class])
      end

      it 'calls the custom classes' do
        expect(custom_tracking_class).to receive(:track_event).with(event_name, **event_kwargs)

        described_class.track_event(event_name, additional_properties: additional_properties, **event_kwargs)
      end
    end
  end
end
