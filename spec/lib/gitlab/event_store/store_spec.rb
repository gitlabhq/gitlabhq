# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::EventStore::Store, feature_category: :shared do
  let(:event_klass) { stub_const('TestEvent', Class.new(Gitlab::EventStore::Event)) }
  let(:event) { event_klass.new(data: data) }
  let(:another_event_klass) { stub_const('TestAnotherEvent', Class.new(Gitlab::EventStore::Event)) }

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

  let(:another_worker) do
    stub_const('AnotherEventSubscriber', Class.new).tap do |klass|
      klass.class_eval do
        include Gitlab::EventStore::Subscriber
      end
    end
  end

  let(:unrelated_worker) do
    stub_const('UnrelatedEventSubscriber', Class.new).tap do |klass|
      klass.class_eval do
        include Gitlab::EventStore::Subscriber
      end
    end
  end

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

  describe '#subscribe' do
    it 'subscribes a worker to an event' do
      store = described_class.new do |s|
        s.subscribe worker, to: event_klass
      end

      subscriptions = store.subscriptions[event_klass]
      expect(subscriptions.map(&:worker)).to contain_exactly(worker)
    end

    it 'subscribes multiple workers to an event' do
      store = described_class.new do |s|
        s.subscribe worker, to: event_klass
        s.subscribe another_worker, to: event_klass
      end

      subscriptions = store.subscriptions[event_klass]
      expect(subscriptions.map(&:worker)).to contain_exactly(worker, another_worker)
    end

    it 'subscribes a worker to multiple events is separate calls' do
      store = described_class.new do |s|
        s.subscribe worker, to: event_klass
        s.subscribe worker, to: another_event_klass
      end

      subscriptions = store.subscriptions[event_klass]
      expect(subscriptions.map(&:worker)).to contain_exactly(worker)

      subscriptions = store.subscriptions[another_event_klass]
      expect(subscriptions.map(&:worker)).to contain_exactly(worker)
    end

    it 'subscribes a worker to multiple events in a single call' do
      store = described_class.new do |s|
        s.subscribe worker, to: [event_klass, another_event_klass]
      end

      subscriptions = store.subscriptions[event_klass]
      expect(subscriptions.map(&:worker)).to contain_exactly(worker)

      subscriptions = store.subscriptions[another_event_klass]
      expect(subscriptions.map(&:worker)).to contain_exactly(worker)
    end

    it 'subscribes a worker to an event with condition' do
      store = described_class.new do |s|
        s.subscribe worker, to: event_klass, if: ->(event) { event.data[:name] == 'Alice' }
      end

      subscriptions = store.subscriptions[event_klass]

      expect(subscriptions.size).to eq(1)

      subscription = subscriptions.first
      expect(subscription).to be_an_instance_of(Gitlab::EventStore::Subscription)
      expect(subscription.worker).to eq(worker)
      expect(subscription.condition.call(double(data: { name: 'Bob' }))).to eq(false)
      expect(subscription.condition.call(double(data: { name: 'Alice' }))).to eq(true)
    end

    it 'refuses the subscription if the target is not an Event object' do
      expect do
        described_class.new do |s|
          s.subscribe worker, to: Integer
        end
      end.to raise_error(
        Gitlab::EventStore::Error,
        /Event being subscribed to is not a subclass of Gitlab::EventStore::Event/)
    end

    it 'refuses the subscription if the subscriber is not a worker' do
      expect do
        described_class.new do |s|
          s.subscribe double, to: event_klass
        end
      end.to raise_error(
        Gitlab::EventStore::Error,
        /Subscriber is not an ApplicationWorker/)
    end
  end

  describe '#publish' do
    let(:data) { { name: 'Bob', id: 123 } }
    let(:serialized_data) { data.deep_stringify_keys }

    context 'when event has a subscribed worker' do
      let(:store) do
        described_class.new do |store|
          store.subscribe worker, to: event_klass
          store.subscribe another_worker, to: another_event_klass
        end
      end

      it 'dispatches the event to the subscribed worker' do
        expect(worker).to receive(:perform_async).with('TestEvent', serialized_data)
        expect(another_worker).not_to receive(:perform_async)

        store.publish(event)
      end

      it 'does not raise any Sidekiq warning' do
        logger = double(:logger, info: nil)
        allow(Sidekiq).to receive(:logger).and_return(logger)
        expect(logger).not_to receive(:warn).with(/do not serialize to JSON safely/)
        expect(worker).to receive(:perform_async).with('TestEvent', serialized_data).and_call_original

        store.publish(event)
      end

      context 'when other workers subscribe to the same event' do
        let(:store) do
          described_class.new do |store|
            store.subscribe worker, to: event_klass
            store.subscribe another_worker, to: event_klass
            store.subscribe unrelated_worker, to: another_event_klass
          end
        end

        it 'dispatches the event to each subscribed worker' do
          expect(worker).to receive(:perform_async).with('TestEvent', serialized_data)
          expect(another_worker).to receive(:perform_async).with('TestEvent', serialized_data)
          expect(unrelated_worker).not_to receive(:perform_async)

          store.publish(event)
        end
      end

      context 'when an error is raised' do
        before do
          allow(worker).to receive(:perform_async).and_raise(NoMethodError, 'the error message')
        end

        it 'is rescued and tracked' do
          expect(Gitlab::ErrorTracking)
            .to receive(:track_and_raise_for_dev_exception)
            .with(kind_of(NoMethodError), event_class: event.class.name, event_data: event.data)
            .and_call_original

          expect { store.publish(event) }.to raise_error(NoMethodError, 'the error message')
        end
      end

      it 'raises and tracks an error when event is published inside a database transaction' do
        expect(Gitlab::ErrorTracking)
          .to receive(:track_and_raise_for_dev_exception)
          .at_least(:once)
          .and_call_original

        expect do
          ApplicationRecord.transaction do
            store.publish(event)
          end
        end.to raise_error(Sidekiq::Worker::EnqueueFromTransactionError)
      end

      it 'refuses publishing if the target is not an Event object' do
        expect { store.publish(double(:event)) }
          .to raise_error(
            Gitlab::EventStore::Error,
            /Event being published is not an instance of Gitlab::EventStore::Event/)
      end
    end

    context 'when event has subscribed workers with condition' do
      let(:store) do
        described_class.new do |s|
          s.subscribe worker, to: event_klass, if: ->(event) { event.data[:name] == 'Bob' }
          s.subscribe another_worker, to: event_klass, if: ->(event) { event.data[:name] == 'Alice' }
        end
      end

      it 'dispatches the event to the workers satisfying the condition' do
        expect(worker).to receive(:perform_async).with('TestEvent', serialized_data)
        expect(another_worker).not_to receive(:perform_async)

        store.publish(event)
      end
    end

    context 'when subscription has delayed dispatching of event' do
      let(:store) do
        described_class.new do |s|
          s.subscribe worker, to: event_klass, delay: 1.minute
        end
      end

      it 'dispatches the event to the worker after some time' do
        expect(worker).to receive(:perform_in).with(1.minute, 'TestEvent', serialized_data)

        store.publish(event)
      end
    end

    context 'when the event does not have any subscribers' do
      let(:store) do
        described_class.new do |s|
          s.subscribe unrelated_worker, to: another_event_klass
        end
      end

      it 'returns successfully' do
        expect { store.publish(event) }.not_to raise_error
      end

      it 'does not dispatch the event to another subscription' do
        expect(unrelated_worker).not_to receive(:perform_async)

        store.publish(event)
      end
    end
  end

  describe '#publish_group' do
    let(:event1) { event_klass.new(data: { name: 'Bob', id: 123 }) }
    let(:event2) { event_klass.new(data: { name: 'Alice', id: 456 }) }
    let(:event3) { event_klass.new(data: { name: 'Eva', id: 789 }) }

    let(:group_size) { 3 }
    let(:events) { [event1, event2, event3] }
    let(:serialized_data) { events.map(&:data).map(&:deep_stringify_keys) }

    let(:store) do
      described_class.new do |s|
        s.subscribe worker, to: event_klass, group_size: group_size
      end
    end

    subject { store.publish_group(events) }

    context 'with valid events' do
      it 'calls consume_events of subscription' do
        expect(store.subscriptions[event_klass].first).to receive(:consume_events).with(events)

        subject
      end
    end

    context 'when there is invalid event' do
      let(:events) { [event1, invalid_event] }

      context 'when event is invalid' do
        let(:invalid_event) { stub_const('TestEvent', {}) }

        it 'raises InvalidEvent error' do
          expect { subject }.to raise_error(Gitlab::EventStore::InvalidEvent)
        end
      end

      context 'when one of the events is a different event' do
        let(:invalid_event) { stub_const('DifferentEvent', Class.new(Gitlab::EventStore::Event)) }

        it 'raises InvalidEvent error' do
          expect { subject }.to raise_error(Gitlab::EventStore::InvalidEvent)
        end
      end
    end
  end

  describe 'subscriber' do
    let(:data) { { name: 'Bob', id: 123 } }
    let(:event_data) { data }
    let(:event_name) { event.class.name }
    let(:worker_instance) { worker.new }

    subject { worker_instance.perform(event_name, event_data) }

    it 'is a Sidekiq worker' do
      expect(worker_instance).to be_a(ApplicationWorker)
    end

    it 'handles the event' do
      expect(worker_instance).to receive(:handle_event).with(instance_of(event.class))

      expect_any_instance_of(event.class) do |event|
        expect(event).to receive(:data).and_return(event_data)
      end

      subject
    end

    context 'when the event name does not exist' do
      let(:event_name) { 'UnknownClass' }

      it 'raises an error' do
        expect { subject }.to raise_error(Gitlab::EventStore::InvalidEvent)
      end
    end

    context 'when the worker does not define handle_event method' do
      let(:worker_instance) { another_worker.new }

      it 'raises an error' do
        expect { subject }.to raise_error(NotImplementedError)
      end
    end

    context 'when there are multiple events' do
      let(:event_data) { [{ name: 'Bob', id: 123 }, { name: 'Alice', id: 456 }] }

      let(:first_event) { event_klass.new(data: event_data.first) }
      let(:second_event) { event_klass.new(data: event_data.last) }

      before do
        allow(worker_instance).to receive(:construct_event).with(event_klass, event_data.first).and_return(first_event)
        allow(worker_instance).to receive(:construct_event).with(event_klass, event_data.last).and_return(second_event)
      end

      it 'calls handle_event multiple times' do
        expect(worker_instance).to receive(:handle_event).once.with(first_event)
        expect(worker_instance).to receive(:handle_event).once.with(second_event)

        subject
      end
    end
  end
end
