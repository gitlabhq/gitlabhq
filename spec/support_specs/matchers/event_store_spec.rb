# frozen_string_literal: true

require 'fast_spec_helper'
require 'json_schemer'
require 'oj'

load File.expand_path('../../../spec/support/matchers/event_store.rb', __dir__)

RSpec.describe 'event store matchers', feature_category: :shared do
  let(:event_type1) do
    Class.new(Gitlab::EventStore::Event) do
      def schema
        {
          'type' => 'object',
          'properties' => {
            'id' => { 'type' => 'integer' }
          },
          'required' => %w[id]
        }
      end
    end
  end

  let(:event_type2) do
    Class.new(Gitlab::EventStore::Event) do
      def schema
        {
          'type' => 'object',
          'properties' => {
            'id' => { 'type' => 'integer' }
          },
          'required' => %w[id]
        }
      end
    end
  end

  before do
    stub_const('FakeEventType1', event_type1)
    stub_const('FakeEventType2', event_type2)
  end

  def publishing_event(event_type, data = {})
    ::Gitlab::EventStore.publish(event_type.new(data: data))
  end

  describe 'publish_event' do
    it 'requires a block matcher' do
      matcher = -> { expect(:anything).to publish_event(:anything) } # rubocop: disable RSpec/ExpectActual

      expect(&matcher).to raise_error(
        ArgumentError,
        'publish_event matcher only supports block expectation'
      )
    end

    it 'validates the event type' do
      valid_event_type = -> do
        expect { publishing_event(FakeEventType1, { 'id' => 1 }) }
          .to publish_event(FakeEventType1).with('id' => 1)
      end

      expect(&valid_event_type).not_to raise_error

      invalid_event_type = -> do
        expect { publishing_event(FakeEventType1, { 'id' => 1 }) }
          .to publish_event(FakeEventType2).with('id' => 1)
      end

      expect(&invalid_event_type).to raise_error <<~MESSAGE
        expected FakeEventType2 with {"id"=>1} to be published, but only the following events were published:
         - FakeEventType1 with {"id"=>1}
      MESSAGE
    end

    it 'validates the event data' do
      missing_data = -> do
        expect { publishing_event(FakeEventType1, { 'id' => 1 }) }
          .to publish_event(FakeEventType1)
      end

      expect(&missing_data).to raise_error <<~MESSAGE
        expected FakeEventType1 with no data to be published, but only the following events were published:
         - FakeEventType1 with {"id"=>1}
      MESSAGE

      different_data = -> do
        expect { publishing_event(FakeEventType1, { 'id' => 1 }) }
          .to publish_event(FakeEventType1).with({ 'id' => 2 })
      end

      expect(&different_data).to raise_error <<~MESSAGE
        expected FakeEventType1 with {"id"=>2} to be published, but only the following events were published:
         - FakeEventType1 with {"id"=>1}
      MESSAGE
    end
  end

  describe 'not_publish_event' do
    it 'requires a block matcher' do
      matcher = -> { expect(:anything).to not_publish_event(:anything) } # rubocop: disable RSpec/ExpectActual

      expect(&matcher)
        .to raise_error(ArgumentError, 'not_publish_event matcher only supports block expectation')
    end

    it 'does not permit .with' do
      matcher = -> do
        expect { publishing_event(FakeEventType1, { 'id' => 1 }) }
          .to not_publish_event(FakeEventType2).with({ 'id' => 1 })
      end

      expect(&matcher)
        .to raise_error(ArgumentError, 'not_publish_event does not permit .with to avoid ambiguity')
    end

    it 'validates the event type' do
      matcher = -> do
        expect { publishing_event(FakeEventType1, { 'id' => 1 }) }
          .to not_publish_event(FakeEventType1)
      end

      expect(&matcher)
        .to raise_error('expected FakeEventType1 not to be published')
    end
  end

  it 'validates with published_event and not_publish_event' do
    matcher = -> do
      expect { publishing_event(FakeEventType1, { 'id' => 1 }) }
        .to publish_event(FakeEventType1).with('id' => 1)
        .and not_publish_event(FakeEventType2)
    end

    expect(&matcher).not_to raise_error
  end

  it 'validates with not_publish_event and published_event' do
    matcher = -> do
      expect { publishing_event(FakeEventType2, { 'id' => 1 }) }
        .to not_publish_event(FakeEventType1)
        .and publish_event(FakeEventType2).with('id' => 1)
    end

    expect(&matcher).not_to raise_error
  end
end
