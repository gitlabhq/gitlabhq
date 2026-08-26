# frozen_string_literal: true

# Reads the frontend and backend Snowplow payloads collected in Gitlab::Testing::SnowplowEvents.
# Every captured event is queryable, experiment or not. Enabled by the :capture_snowplow_events
# tag, see spec/support/capture_snowplow_events.rb.
module SnowplowCaptureHelpers
  include WaitHelpers

  GITLAB_EXPERIMENT_SCHEMA = 'iglu:com.gitlab/gitlab_experiment/jsonschema'

  SnowplowEvent = Struct.new(
    :event_type, :category, :action, :label, :property, :platform, :experiment_context,
    keyword_init: true
  )

  def captured_snowplow_events
    Gitlab::Testing::SnowplowEvents.all.map { |payload| build_snowplow_event(payload) }
  end

  def find_snowplow_event(**attributes)
    captured_snowplow_events.find do |event|
      # Case equality so a spec can match with `include(...)` or a regex, not just a literal.
      attributes.all? { |attribute, value| value === event[attribute] }
    end
  end

  # Waits for every event a journey's contract declares. A contract that names an experiment
  # additionally requires each of its events to carry that experiment's context, for the
  # variant under test.
  def expect_snowplow_tracking_journey(name, variant: nil)
    journey = SnowplowTrackingJourney.load(name, variant: variant)

    raise ArgumentError, "#{name} declares no events to assert" if journey.events.empty?

    context = expected_experiment_context(journey.experiment, variant)

    journey.events.each do |declared|
      expected = declared.symbolize_keys
      expected[:experiment_context] = context if context

      wait_for_snowplow_event(**expected)
    end
  end

  # Frontend events are POSTed to the collector asynchronously and leave no visible trace on
  # the page, so there is no UI outcome to synchronize on instead.
  def wait_for_snowplow_event(**attributes)
    wait_for("snowplow event matching #{attributes}") do
      find_snowplow_event(**attributes)
    end
  rescue RuntimeError => error
    raise error, "#{error.message}\n\nCaptured events:\n#{captured_events_summary}"
  end

  private

  def expected_experiment_context(experiment, variant)
    return unless experiment

    expected = { 'experiment' => experiment }
    expected['variant'] = variant.to_s if variant

    include(expected)
  end

  # Summarizes every captured event, not just the ones being matched, so a missing experiment
  # context reads as "the event fired without a context" rather than "no events".
  def captured_events_summary
    events = captured_snowplow_events

    return '  (none)' if events.empty?

    events.map do |event|
      "  #{event.platform} #{event.event_type} action=#{event.action.inspect} " \
        "property=#{event.property.inspect} experiment=#{event.experiment_context.inspect}"
    end.join("\n")
  end

  def build_snowplow_event(payload)
    SnowplowEvent.new(
      event_type: payload['e'],
      category: payload['se_ca'],
      action: payload['se_ac'],
      label: payload['se_la'],
      property: payload['se_pr'],
      platform: payload['p'],
      experiment_context: experiment_context_for(decoded_contexts(payload))
    )
  end

  # An experiment is identified by this context rather than by category, because frontend events
  # are categorised by page (for example "root:index") while backend events use the experiment
  # name. Events outside an experiment have no such context.
  def experiment_context_for(contexts)
    contexts.find { |context| context['schema'].to_s.start_with?(GITLAB_EXPERIMENT_SCHEMA) }&.dig('data')
  end

  # The Ruby tracker base64-encodes contexts into `cx` (URL-safe alphabet), the browser
  # tracker sends them unencoded in `co`.
  def decoded_contexts(payload)
    json = payload['cx'].present? ? Base64.decode64(payload['cx'].tr('-_', '+/')) : payload['co']

    return [] if json.blank?

    Gitlab::Json::SafeParser.parse(json).fetch('data', [])
  end
end
