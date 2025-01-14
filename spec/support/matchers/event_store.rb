# frozen_string_literal: true

module RSpec
  module PublishedGitlabEventStoreEvents
    class FakeGitlabEventStore
      include ::RSpec::Mocks::ExampleMethods

      attr_reader :events

      def initialize
        @events = []
        allow(Gitlab::EventStore).to receive(:publish) do |published_event|
          @events << published_event
        end
        allow(Gitlab::EventStore).to receive(:publish_group) do |published_event|
          @events += published_event
        end
      end
    end

    # Ensure to use the same stubbed Gitlab::EventStore within the test example, this
    # way the list of published events is shared within the example enabling us to
    # use .(not_)to publish_event multiple times and also mix it with .[to/and] not_publish_event
    def self.setup(test)
      @tests ||= Hash.new { |h, k| h[k] = [] }.tap(&:compare_by_identity)
      @tests[test] = FakeGitlabEventStore.new
    end

    def self.on(test)
      @tests[test]&.events
    end
  end

  Matchers.define :publish_event do |expected_event_class|
    include RSpec::Matchers::Composable

    supports_block_expectations

    match do |proc|
      raise ArgumentError, 'publish_event matcher only supports block expectation' unless proc.respond_to?(:call)

      RSpec::PublishedGitlabEventStoreEvents.setup(@matcher_execution_context)

      proc.call

      RSpec::PublishedGitlabEventStoreEvents.on(@matcher_execution_context).any? do |event|
        event.instance_of?(expected_event_class) && match_data?(event.data, @expected_data)
      end
    end

    chain :with do |expected_data|
      @expected_data = expected_data.with_indifferent_access
    end

    failure_message do
      message = "expected #{expected_event_class} with #{@expected_data || 'no data'} to be published"

      if RSpec::PublishedGitlabEventStoreEvents.on(@matcher_execution_context).present?
        <<~MESSAGE
        #{message}, but only the following events were published:
        #{published_events_description}
        MESSAGE
      else
        "#{message}, but no events were published."
      end
    end

    failure_message_when_negated do
      "expected #{expected_event_class} not to be published"
    end

    private

    def match_data?(actual, expected)
      return true if actual.blank? && expected.blank?
      return false if actual.blank? || expected.blank?

      values_match?(expected.keys.sort, actual.keys.sort) &&
        actual.keys.all? do |key|
          case expected[key]
          when Array
            values_match?(expected[key].sort, actual[key].sort)
          else
            values_match?(expected[key], actual[key])
          end
        end
    end

    def published_events_description
      RSpec::PublishedGitlabEventStoreEvents.on(@matcher_execution_context).map do |event|
        " - #{event.class.name} with #{event.data}"
      end.join("\n")
    end
  end

  # not_publish_event enables multiple assertions on a single block, for example:
  #     expect { Model.create(invalid: :attribute) }
  #       .to not_change(Model, :count)
  #       .and not_publish_event(ModelCreated)
  Matchers.define :not_publish_event do |expected_event_class|
    include RSpec::Matchers::Composable

    supports_block_expectations

    match do |proc|
      raise ArgumentError, 'not_publish_event matcher only supports block expectation' unless proc.respond_to?(:call)

      RSpec::PublishedGitlabEventStoreEvents.setup(@matcher_execution_context)

      proc.call

      RSpec::PublishedGitlabEventStoreEvents.on(@matcher_execution_context).none? do |event|
        event.instance_of?(expected_event_class)
      end
    end

    failure_message do
      "expected #{expected_event_class} not to be published"
    end

    chain :with do |_| # rubocop: disable Lint/UnreachableLoop -- false positive
      raise ArgumentError, 'not_publish_event does not permit .with to avoid ambiguity'
    end

    match_when_negated do |_proc|
      raise ArgumentError,
        'not_publish_event matcher does not support negation. Use `expect {}.to publish_event` instead'
    end
  end
end
