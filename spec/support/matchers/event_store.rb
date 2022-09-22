# frozen_string_literal: true

RSpec::Matchers.define :publish_event do |expected_event_class|
  include RSpec::Matchers::Composable

  supports_block_expectations

  match do |proc|
    raise ArgumentError, 'publish_event matcher only supports block expectation' unless proc.respond_to?(:call)

    @events ||= []

    allow(Gitlab::EventStore).to receive(:publish) do |published_event|
      @events << published_event
    end

    proc.call

    @events.any? do |event|
      event.instance_of?(expected_event_class) && match_data?(event.data, @expected_data)
    end
  end

  def match_data?(actual, expected)
    return if actual.blank? || expected.blank?

    values_match?(actual.keys, expected.keys) &&
      actual.keys.all? do |key|
        values_match?(expected[key], actual[key])
      end
  end

  chain :with do |expected_data|
    @expected_data = expected_data
  end

  failure_message do
    message = "expected #{expected_event_class} with #{@expected_data || 'no data'} to be published"

    if @events.present?
      <<~MESSAGE
      #{message}, but only the following events were published:
      #{events_list}
      MESSAGE
    else
      "#{message}, but no events were published."
    end
  end

  match_when_negated do |proc|
    raise ArgumentError, 'publish_event matcher only supports block expectation' unless proc.respond_to?(:call)

    allow(Gitlab::EventStore).to receive(:publish)

    proc.call

    expect(Gitlab::EventStore).not_to have_received(:publish).with(instance_of(expected_event_class))
  end

  def events_list
    @events.map do |event|
      " - #{event.class.name} with #{event.data}"
    end.join("\n")
  end
end

# not_publish_event enables multiple assertions on a single block, for example:
#     expect { Model.create(invalid: :attribute) }
#       .to not_change(Model, :count)
#       .and not_publish_event(ModelCreated)
RSpec::Matchers.define :not_publish_event do |expected_event_class|
  include RSpec::Matchers::Composable

  supports_block_expectations

  match do |proc|
    raise ArgumentError, 'not_publish_event matcher only supports block expectation' unless proc.respond_to?(:call)

    @events ||= []

    allow(Gitlab::EventStore).to receive(:publish) do |published_event|
      @events << published_event
    end

    proc.call

    @events.none? do |event|
      event.instance_of?(expected_event_class)
    end
  end

  failure_message do
    "expected #{expected_event_class} not to be published"
  end

  chain :with do |_| # rubocop: disable Lint/UnreachableLoop
    raise ArgumentError, 'not_publish_event does not permit .with to avoid ambiguity'
  end

  match_when_negated do |proc|
    raise ArgumentError, 'not_publish_event matcher does not support negation. Use `expect {}.to publish_event` instead'
  end
end
