# frozen_string_literal: true

require 'spec_helper'

describe Gitlab::Metrics::WebTransaction do
  let(:env) { {} }
  let(:transaction) { described_class.new(env) }
  let(:prometheus_metric) { double("prometheus metric") }

  before do
    allow(described_class).to receive(:transaction_metric).and_return(prometheus_metric)
  end

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

  describe '#method_call_for' do
    it 'returns a MethodCall' do
      method = transaction.method_call_for('Foo#bar', :Foo, '#bar')

      expect(method).to be_an_instance_of(Gitlab::Metrics::MethodCall)
    end
  end

  describe '#increment' do
    it 'increments a counter' do
      expect(prometheus_metric).to receive(:increment).with({}, 1)

      transaction.increment(:time, 1)
    end
  end

  describe '#set' do
    it 'sets a value' do
      expect(prometheus_metric).to receive(:set).with({}, 10)

      transaction.set(:number, 10)
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
      end

      it 'does not provide labels if route infos are missing' do
        endpoint = double(:endpoint)
        allow(endpoint).to receive(:route).and_raise

        env['api.endpoint'] = endpoint

        expect(transaction.labels).to eq({})
      end
    end

    context 'when request goes to ActionController' do
      let(:request) { double(:request, format: double(:format, ref: :html)) }

      before do
        klass = double(:klass, name: 'TestController')
        controller = double(:controller, class: klass, action_name: 'show', request: request)

        env['action_controller.instance'] = controller
      end

      it 'tags a transaction with the name and action of a controller' do
        expect(transaction.labels).to eq({ controller: 'TestController', action: 'show' })
      end

      context 'when the request content type is not :html' do
        let(:request) { double(:request, format: double(:format, ref: :json)) }

        it 'appends the mime type to the transaction action' do
          expect(transaction.labels).to eq({ controller: 'TestController', action: 'show.json' })
        end
      end

      context 'when the request content type is not' do
        let(:request) { double(:request, format: double(:format, ref: 'http://example.com')) }

        it 'does not append the MIME type to the transaction action' do
          expect(transaction.labels).to eq({ controller: 'TestController', action: 'show' })
        end
      end
    end

    it 'returns no labels when no route information is present in env' do
      expect(transaction.labels).to eq({})
    end
  end

  describe '#add_event' do
    it 'adds a metric' do
      expect(prometheus_metric).to receive(:increment)

      transaction.add_event(:meow)
    end

    it 'allows tracking of custom tags' do
      expect(prometheus_metric).to receive(:increment).with(animal: "dog")

      transaction.add_event(:bau, animal: 'dog')
    end
  end
end
