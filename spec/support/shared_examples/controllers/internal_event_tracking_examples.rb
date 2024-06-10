# frozen_string_literal: true

# Requires a context containing:
# - subject
# - event
# Optionally, the context can contain:
# - user
# - project
# - namespace
# - category
# - label
# - property
# - value

RSpec.shared_examples 'internal event tracking' do
  let(:all_metrics) do
    Gitlab::Usage::MetricDefinition.all.filter_map do |definition|
      definition.key if definition.events.include?(event)
    end
  end

  it 'logs to Snowplow, Redis, and product analytics tooling', :clean_gitlab_redis_shared_state, :aggregate_failures do
    expect { subject }
      .to trigger_internal_events(event)
      .with(
        project: try(:project),
        user: try(:user),
        namespace: try(:namespace) || try(:project)&.namespace,
        category: try(:category) || 'InternalEventTracking',
        feature_enabled_by_namespace_ids: try(:feature_enabled_by_namespace_ids),
        **{
          label: try(:label),
          property: try(:property),
          value: try(:value)
        }.compact
      ).and increment_usage_metrics(*all_metrics)
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
