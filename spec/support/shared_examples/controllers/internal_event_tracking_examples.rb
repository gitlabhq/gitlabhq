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
# These legacy options are now deprecated:
# - label
# - property
# - value
# Prefer using additional_properties instead.

RSpec.shared_examples 'internal event tracking' do
  let(:all_metrics) do
    additional_properties = try(:additional_properties) || {}
    base_additional_properties = Gitlab::Tracking::EventValidator::BASE_ADDITIONAL_PROPERTIES.to_h do |key, _val|
      [key, try(key)]
    end

    Gitlab::Usage::MetricDefinition.all.filter_map do |definition|
      matching_rules = definition.event_selection_rules.map do |event_selection_rule|
        next unless event_selection_rule.name == event

        # Only include unique metrics if the unique_identifier_name is present in the spec
        next if event_selection_rule.unique_identifier_name && !try(event_selection_rule.unique_identifier_name)

        properties = additional_properties.merge(base_additional_properties)
        event_selection_rule.matches?(properties)
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
