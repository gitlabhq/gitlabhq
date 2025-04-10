# frozen_string_literal: true

# Requires a context containing:
# - subject
# - event
# Optionally, the context can contain:
# - user
# - project
# - namespace
# - category
# - additional_properties
# - event_attribute_overrides - is used when its necessary to override the attributes available in parent context.
#
# [Legacy] If present in the context, the following will be respected by the shared example but are discouraged:
# - label
# - property
# - value
# [Recommended] Prefer including these attributes via additional_properties instead.
#   ex) let(:additional_properties) { { label: "label_name" } }

RSpec.shared_examples 'internal event tracking' do
  let(:all_metrics) do
    Gitlab::Usage::MetricDefinition.all.filter_map do |definition|
      matching_rules = definition.event_selection_rules.select do |event_selection_rule|
        next unless event_selection_rule.name == event

        # Only include unique metrics if the unique_identifier_name is present in the spec
        next if event_selection_rule.unique_identifier_name && !try(event_selection_rule.unique_identifier_name)

        next true if event_selection_rule.filter.blank?

        raise <<~MESSAGE
          Event '#{event}' has metrics that use filters.
          Testing such events with the 'internal event tracking' examples group is not supported.

          To test it, use composable matchers:
          https://docs.gitlab.com/development/internal_analytics/internal_event_instrumentation/quick_start/#composable-matchers
        MESSAGE
      end

      definition.key if matching_rules.flatten.any?
    end
  end

  it 'logs to Snowplow, Redis, and product analytics tooling', :clean_gitlab_redis_shared_state, :aggregate_failures do
    expected_attributes = {
      project: try(:project),
      user: try(:user),
      namespace: try(:namespace) || try(:project)&.namespace,
      category: try(:category) || 'InternalEventTracking',
      feature_enabled_by_namespace_ids: try(:feature_enabled_by_namespace_ids),
      additional_properties: {
        **(try(:additional_properties) || {}),
        **{
          label: try(:label),
          property: try(:property),
          value: try(:value)
        }.compact
      }
    }.merge(try(:event_attribute_overrides) || {})

    expect { subject }
      .to trigger_internal_events(event)
      .with(expected_attributes)
      .and increment_usage_metrics(*all_metrics)
  end
end

# Requires everything required by `internal event tracking`
# Additionally, requires:
# - migrated_metrics - an array of metrics' key_paths
# - previous_event_name
# - previous_event_value - the value that the previous event used for the HLLRedisCounter call. Usually user's id

RSpec.shared_examples 'migrated internal event' do
  it_behaves_like 'internal event tracking'

  describe "event migration" do
    around do |example|
      reference_time = Time.utc(2020, 6, 1)
      # use reference time to make the Redis key suffix always consistent
      travel_to(reference_time) { example.run }
    end

    let(:redis_key_prefix) { "{#{Gitlab::UsageDataCounters::HLLRedisCounter::REDIS_SLOT}}_#{previous_event_name}-" }
    let(:redis_key) { "#{redis_key_prefix}2020-23" }

    it "saves the migrated event correctly" do
      expect(Gitlab::Redis::HLL).to receive(:add).with(
        key: redis_key,
        value: previous_event_value,
        expiry: Gitlab::UsageDataCounters::HLLRedisCounter::KEY_EXPIRY_LENGTH
      )

      subject
    end

    it "reads the migrated event's value using the old Redis key" do
      migrated_metrics.each do |metric_key_path|
        expect(Gitlab::Redis::HLL).to receive(:count) do |args|
          expect(args[:keys]).to all(start_with(redis_key_prefix))
        end

        metric_definition = Gitlab::Usage::MetricDefinition.definitions[metric_key_path]
        Gitlab::Usage::Metric.new(metric_definition).with_value
      end
    end

    it "increments the migrated metrics" do
      expect { subject }.to increment_usage_metrics(*migrated_metrics)
    end
  end
end

# Requires a context containing:
# - subject
# Optionally, the context can contain:
# - event

RSpec.shared_examples 'internal event not tracked' do
  it 'does not record an internal event' do
    if defined?(event)
      expect(Gitlab::InternalEvents).not_to receive(:track_event).with(event, any_args)
    else
      expect(Gitlab::InternalEvents).not_to receive(:track_event)
    end

    subject
  end
end
