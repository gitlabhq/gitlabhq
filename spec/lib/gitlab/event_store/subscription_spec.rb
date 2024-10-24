# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::EventStore::Subscription, feature_category: :shared do
  let(:worker) do
    stub_const('EventSubscriber', Class.new).tap do |klass|
      klass.class_eval do
        include Gitlab::EventStore::Subscriber

        def handle_event(event)
          event.data
        end
      end
    end
  end

  let(:event_klass) { stub_const('TestEvent', Class.new(Gitlab::EventStore::Event)) }
  let(:event) { event_klass.new(data: data) }

  let(:delay) { nil }
  let(:condition) { nil }
  let(:group_size) { nil }

  subject(:subscription) { described_class.new(worker, condition, delay, group_size) }

  before do
    event_klass.class_eval do
      def schema
        {
          'required' => %w[name id],
          'type' => 'object',
          'properties' => {
            'name' => { 'type' => 'string' },
            'id' => { 'type' => 'integer' }
          }
        }
      end
    end
  end

  describe '#consume_event' do
    let(:event) { event_klass.new(data: { name: 'Bob', id: 123 }) }

    subject(:consume_event) { subscription.consume_event(event) }

    it { is_expected.to be_present }

    it 'triggers the execution of the worker' do
      expect(worker).to receive(:perform_async)

      consume_event
    end

    context 'when event is invalid' do
      let(:event) { event_klass.new(data: { name: 'Bob' }) }

      it 'raises InvalidEvent error' do
        expect { consume_event }.to raise_error(Gitlab::EventStore::InvalidEvent)
      end
    end

    context 'with delayed dispatching of event' do
      let(:delay) { 1.minute }

      it { is_expected.to be_present }

      it 'dispatches the events to the worker with batch parameters and delay' do
        expect(worker).to receive(:perform_in)

        consume_event
      end
    end
  end

  describe '#consume_events' do
    let(:event1) { event_klass.new(data: { name: 'Bob', id: 123 }) }
    let(:event2) { event_klass.new(data: { name: 'Alice', id: 456 }) }
    let(:event3) { event_klass.new(data: { name: 'Eva', id: 789 }) }

    let(:group_size) { 3 }
    let(:events) { [event1, event2, event3] }
    let(:serialized_data) { events.map(&:data).map(&:deep_stringify_keys) }

    subject(:consume_events) { subscription.consume_events(events) }

    context 'with invalid events' do
      let(:events) { [event1, invalid_event] }

      context 'when event is invalid' do
        let(:invalid_event) { stub_const('TestEvent', Class.new { attr_reader :data }).new }

        it 'raises InvalidEvent error' do
          expect { consume_events }.to raise_error(Gitlab::EventStore::InvalidEvent)
        end
      end

      context 'when one of the events is a different event' do
        let(:invalid_event_klass) { stub_const('DifferentEvent', Class.new(Gitlab::EventStore::Event)) }
        let(:invalid_event) { invalid_event_klass.new(data: {}) }

        before do
          invalid_event_klass.class_eval do
            def schema
              {
                'type' => 'object',
                'properties' => {}
              }
            end
          end
        end

        it 'raises InvalidEvent error' do
          expect { consume_events }.to raise_error(Gitlab::EventStore::InvalidEvent)
        end
      end
    end

    context 'when grouped events size is more than batch scheduling size' do
      let(:group_size) { 2 }

      before do
        stub_const("#{described_class}::SCHEDULING_BATCH_SIZE", 1)
      end

      it 'dispatches the events to the worker with batch parameters' do
        expect(worker).to receive(:bulk_perform_in).with(
          1.second,
          [['TestEvent', serialized_data.take(2)], ['TestEvent', serialized_data.drop(2)]],
          batch_size: 1,
          batch_delay: 10.seconds
        )

        consume_events
      end

      context 'with delayed dispatching of event' do
        let(:delay) { 1.minute }

        it 'dispatches the events to the worker with batch parameters and delay' do
          expect(worker).to receive(:bulk_perform_in).with(
            1.minute,
            [['TestEvent', serialized_data.take(2)], ['TestEvent', serialized_data.drop(2)]],
            batch_size: 1,
            batch_delay: 10.seconds
          )

          consume_events
        end
      end
    end

    context 'when subscription has grouped dispatching of events' do
      let(:group_size) { 2 }

      it 'dispatches the events to the worker in group' do
        expect(worker).to receive(:bulk_perform_async).once.with([
          ['TestEvent', serialized_data.take(2)],
          ['TestEvent', serialized_data.drop(2)]
        ])

        consume_events
      end
    end

    context 'when subscription has delayed dispatching of event' do
      let(:delay) { 1.minute }

      it 'dispatches the events to the worker after some time' do
        expect(worker).to receive(:bulk_perform_in).with(1.minute, [['TestEvent', serialized_data]])

        consume_events
      end
    end
  end
end
