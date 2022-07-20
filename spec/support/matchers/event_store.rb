# frozen_string_literal: true

RSpec::Matchers.define :publish_event do |expected_event_class|
  include RSpec::Matchers::Composable

  supports_block_expectations

  match do |proc|
    raise ArgumentError, 'This matcher only supports block expectation' unless proc.respond_to?(:call)

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
    values_match?(actual.keys, expected.keys) &&
      actual.keys.each do |key|
        values_match?(actual[key], expected[key])
      end
  end

  chain :with do |expected_data|
    @expected_data = expected_data
  end

  failure_message do
    "expected #{expected_event_class} with #{@expected_data} to be published, but got #{@events}"
  end

  match_when_negated do |proc|
    raise ArgumentError, 'This matcher only supports block expectation' unless proc.respond_to?(:call)

    allow(Gitlab::EventStore).to receive(:publish)

    proc.call

    expect(Gitlab::EventStore).not_to have_received(:publish).with(instance_of(expected_event_class))
  end
end
