require 'spec_helper'

describe Gitlab::Metrics::WebTransaction do
  let(:env) { {} }
  let(:transaction) { described_class.new(env) }

  describe '#duration' do
    it 'returns the duration of a transaction in seconds' do
      transaction.run { sleep(0.5) }

      expect(transaction.duration).to be >= 0.5
    end
  end

  describe '#allocated_memory' do
    it 'returns the allocated memory in bytes' do
      transaction.run { 'a' * 32 }

      expect(transaction.allocated_memory).to be_a_kind_of(Numeric)
    end
  end

  describe '#run' do
    it 'yields the supplied block' do
      expect { |b| transaction.run(&b) }.to yield_control
    end

    it 'stores the transaction in the current thread' do
      transaction.run do
        expect(Thread.current[described_class::THREAD_KEY]).to eq(transaction)
      end
    end

    it 'removes the transaction from the current thread upon completion' do
      transaction.run { }

      expect(Thread.current[described_class::THREAD_KEY]).to be_nil
    end
  end

  describe '#add_metric' do
    it 'adds a metric to the transaction' do
      expect(Gitlab::Metrics::Metric).to receive(:new)
        .with('rails_foo', { number: 10 }, {})

      transaction.add_metric('foo', number: 10)
    end
  end

  describe '#method_call_for' do
    it 'returns a MethodCall' do
      method = transaction.method_call_for('Foo#bar', :Foo, '#bar')

      expect(method).to be_an_instance_of(Gitlab::Metrics::MethodCall)
    end
  end

  describe '#increment' do
    it 'increments a counter' do
      transaction.increment(:time, 1)
      transaction.increment(:time, 2)

      values = { duration: 0.0, time: 3, allocated_memory: a_kind_of(Numeric) }

      expect(transaction).to receive(:add_metric)
        .with('transactions', values, {})

      transaction.track_self
    end
  end

  describe '#set' do
    it 'sets a value' do
      transaction.set(:number, 10)

      values = {
        duration:         0.0,
        number:           10,
        allocated_memory: a_kind_of(Numeric)
      }

      expect(transaction).to receive(:add_metric)
        .with('transactions', values, {})

      transaction.track_self
    end
  end

  describe '#finish' do
    it 'tracks the transaction details and submits them to Sidekiq' do
      expect(transaction).to receive(:track_self)
      expect(transaction).to receive(:submit)

      transaction.finish
    end
  end

  describe '#track_self' do
    it 'adds a metric for the transaction itself' do
      values = {
        duration:         transaction.duration,
        allocated_memory: a_kind_of(Numeric)
      }

      expect(transaction).to receive(:add_metric)
        .with('transactions', values, {})

      transaction.track_self
    end
  end

  describe '#submit' do
    it 'submits the metrics to Sidekiq' do
      transaction.track_self

      expect(Gitlab::Metrics).to receive(:submit_metrics)
        .with([an_instance_of(Hash)])

      transaction.submit
    end

    it 'adds the action as a tag for every metric' do
      allow(transaction).to receive(:labels).and_return(controller: 'Foo', action: 'bar')
      transaction.track_self

      hash = {
        series:    'rails_transactions',
        tags:      { action: 'Foo#bar' },
        values:    { duration: 0.0, allocated_memory: a_kind_of(Numeric) },
        timestamp: a_kind_of(Integer)
      }

      expect(Gitlab::Metrics).to receive(:submit_metrics)
        .with([hash])

      transaction.submit
    end

    it 'does not add an action tag for events' do
      allow(transaction).to receive(:labels).and_return(controller: 'Foo', action: 'bar')

      transaction.add_event(:meow)

      hash = {
        series:    'events',
        tags:      { event: :meow },
        values:    { count: 1 },
        timestamp: a_kind_of(Integer)
      }

      expect(Gitlab::Metrics).to receive(:submit_metrics)
        .with([hash])

      transaction.submit
    end
  end

  describe '#labels' do
    context 'when request goes to Grape endpoint' do
      before do
        route = double(:route, request_method: 'GET', path: '/:version/projects/:id/archive(.:format)')
        endpoint = double(:endpoint, route: route)

        env['api.endpoint'] = endpoint
      end
      it 'provides labels with the method and path of the route in the grape endpoint' do
        expect(transaction.labels).to eq({ controller: 'Grape', action: 'GET /projects/:id/archive' })
        expect(transaction.action).to eq('Grape#GET /projects/:id/archive')
      end

      it 'does not provide labels if route infos are missing' do
        endpoint = double(:endpoint)
        allow(endpoint).to receive(:route).and_raise

        env['api.endpoint'] = endpoint

        expect(transaction.labels).to eq({})
        expect(transaction.action).to be_nil
      end
    end

    context 'when request goes to ActionController' do
      let(:content_type) { 'text/html' }

      before do
        klass = double(:klass, name: 'TestController')
        controller = double(:controller, class: klass, action_name: 'show', content_type: content_type)

        env['action_controller.instance'] = controller
      end

      it 'tags a transaction with the name and action of a controller' do
        expect(transaction.labels).to eq({ controller: 'TestController', action: 'show' })
        expect(transaction.action).to eq('TestController#show')
      end

      context 'when the response content type is not :html' do
        let(:content_type) { 'application/json' }

        it 'appends the mime type to the transaction action' do
          expect(transaction.labels).to eq({ controller: 'TestController', action: 'show.json' })
          expect(transaction.action).to eq('TestController#show.json')
        end
      end
    end

    it 'returns no labels when no route information is present in env' do
      expect(transaction.labels).to eq({})
      expect(transaction.action).to eq(nil)
    end
  end

  describe '#add_event' do
    it 'adds a metric' do
      transaction.add_event(:meow)

      expect(transaction.metrics[0]).to be_an_instance_of(Gitlab::Metrics::Metric)
    end

    it "does not prefix the metric's series name" do
      transaction.add_event(:meow)

      metric = transaction.metrics[0]

      expect(metric.series).to eq(described_class::EVENT_SERIES)
    end

    it 'tracks a counter for every event' do
      transaction.add_event(:meow)

      metric = transaction.metrics[0]

      expect(metric.values).to eq(count: 1)
    end

    it 'tracks the event name' do
      transaction.add_event(:meow)

      metric = transaction.metrics[0]

      expect(metric.tags).to eq(event: :meow)
    end

    it 'allows tracking of custom tags' do
      transaction.add_event(:meow, animal: 'cat')

      metric = transaction.metrics[0]

      expect(metric.tags).to eq(event: :meow, animal: 'cat')
    end
  end
end
