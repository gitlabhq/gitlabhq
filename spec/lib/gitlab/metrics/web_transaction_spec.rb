# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::Metrics::WebTransaction do
  let(:env) { {} }
  let(:transaction) { described_class.new(env) }
  let(:prometheus_metric) { instance_double(Prometheus::Client::Metric, base_labels: {}) }

  before do
    allow(described_class).to receive(:prometheus_metric).and_return(prometheus_metric)
  end

  RSpec.shared_context 'ActionController request' do
    let(:request) { double(:request, format: double(:format, ref: :html)) }
    let(:controller_class) { double(:controller_class, name: 'TestController') }

    before do
      controller = double(:controller, class: controller_class, action_name: 'show', request: request)
      env['action_controller.instance'] = controller
    end
  end

  RSpec.shared_context 'transaction observe metrics' do
    before do
      allow(transaction).to receive(:observe)
    end
  end

  RSpec.shared_examples 'metric with labels' do |metric_method|
    include_context 'ActionController request'

    it 'measures with correct labels and value' do
      value = 1
      expect(prometheus_metric).to receive(metric_method).with({ controller: 'TestController', action: 'show', feature_category: '' }, value)

      transaction.send(metric_method, :bau, value)
    end
  end

  describe '#run' do
    include_context 'transaction observe metrics'

    it 'yields the supplied block' do
      expect { |b| transaction.run(&b) }.to yield_control
    end

    it 'stores the transaction in the current thread' do
      transaction.run do
        expect(Thread.current[described_class::THREAD_KEY]).to eq(transaction)
        expect(described_class.current).to eq(transaction)

        ['200', {}, '']
      end
    end

    it 'removes the transaction from the current thread upon completion' do
      transaction.run { }

      expect(Thread.current[described_class::THREAD_KEY]).to be_nil
      expect(described_class.current).to be_nil
    end

    it 'records the duration of the transaction if the request was successful' do
      expect(transaction).to receive(:observe).with(:gitlab_transaction_duration_seconds, instance_of(Float))

      transaction.run { ['200', {}, ''] }
    end

    it 'does not record the duration of the transaction if the request failed' do
      expect(transaction).not_to receive(:observe).with(:gitlab_transaction_duration_seconds, instance_of(Float))

      transaction.run { ['500', {}, ''] }
    end

    it 'does not record the duration of the transaction if it raised' do
      expect(transaction).not_to receive(:observe).with(:gitlab_transaction_duration_seconds, instance_of(Float))

      expect do
        transaction.run { raise 'broken' }
      end.to raise_error('broken')
    end

    it 'returns the rack response' do
      response = ['500', {}, '']

      expect(transaction.run { response }).to eq(response)
    end
  end

  describe '#method_call_for' do
    it 'returns a MethodCall' do
      method = transaction.method_call_for('Foo#bar', :Foo, '#bar')

      expect(method).to be_an_instance_of(Gitlab::Metrics::MethodCall)
    end
  end

  describe '#labels' do
    context 'when request goes to Grape endpoint' do
      before do
        route = double(:route, request_method: 'GET', path: '/:version/projects/:id/archive(.:format)')
        endpoint = double(:endpoint, route: route,
                          options: { for: API::Projects, path: [":id/archive"] },
                          namespace: "/projects")

        env['api.endpoint'] = endpoint
      end

      it 'provides labels with the method and path of the route in the grape endpoint' do
        expect(transaction.labels).to eq({ controller: 'Grape', action: 'GET /projects/:id/archive', feature_category: 'projects' })
      end

      it 'contains only the labels defined for transactions' do
        expect(transaction.labels.keys).to contain_exactly(*described_class.superclass::BASE_LABEL_KEYS)
      end

      it 'does not provide labels if route infos are missing' do
        endpoint = double(:endpoint)
        allow(endpoint).to receive(:route).and_raise

        env['api.endpoint'] = endpoint

        expect(transaction.labels).to eq({})
      end
    end

    context 'when request goes to ActionController' do
      include_context 'ActionController request'

      it 'tags a transaction with the name and action of a controller' do
        expect(transaction.labels).to eq({ controller: 'TestController', action: 'show', feature_category: '' })
      end

      it 'contains only the labels defined for transactions' do
        expect(transaction.labels.keys).to contain_exactly(*described_class.superclass::BASE_LABEL_KEYS)
      end

      context 'when the request content type is not :html' do
        let(:request) { double(:request, format: double(:format, ref: :json)) }

        it 'appends the mime type to the transaction action' do
          expect(transaction.labels).to eq({ controller: 'TestController', action: 'show.json', feature_category: '' })
        end
      end

      context 'when the request content type is not' do
        let(:request) { double(:request, format: double(:format, ref: 'http://example.com')) }

        it 'does not append the MIME type to the transaction action' do
          expect(transaction.labels).to eq({ controller: 'TestController', action: 'show', feature_category: '' })
        end
      end

      context 'when the feature category is known' do
        it 'includes it in the feature category label' do
          expect(controller_class).to receive(:feature_category_for_action).with('show').and_return(:source_code_management)
          expect(transaction.labels).to eq({ controller: 'TestController', action: 'show', feature_category: "source_code_management" })
        end
      end
    end

    it 'returns no labels when no route information is present in env' do
      expect(transaction.labels).to eq({})
    end
  end

  describe '#add_event' do
    let(:prometheus_metric) { instance_double(Prometheus::Client::Counter, :increment, base_labels: {}) }

    it 'adds a metric' do
      expect(prometheus_metric).to receive(:increment)

      transaction.add_event(:meow)
    end

    it 'allows tracking of custom tags' do
      expect(prometheus_metric).to receive(:increment).with(animal: "dog")

      transaction.add_event(:bau, animal: 'dog')
    end
  end

  describe '#increment' do
    let(:prometheus_metric) { instance_double(Prometheus::Client::Counter, :increment, base_labels: {}) }

    it_behaves_like 'metric with labels', :increment
  end

  describe '#set' do
    let(:prometheus_metric) { instance_double(Prometheus::Client::Gauge, :set, base_labels: {}) }

    it_behaves_like 'metric with labels', :set
  end

  describe '#observe' do
    let(:prometheus_metric) { instance_double(Prometheus::Client::Histogram, :observe, base_labels: {}) }

    it_behaves_like 'metric with labels', :observe
  end
end
