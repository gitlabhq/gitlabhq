# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::Metrics::WebTransaction do
  let(:env) { {} }
  let(:transaction) { described_class.new(env) }

  describe '#run' do
    let(:prometheus_metric) { instance_double(Prometheus::Client::Metric, base_labels: {}) }

    before do
      allow(described_class).to receive(:prometheus_metric).and_return(prometheus_metric)
      allow(transaction).to receive(:observe)
    end

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
      transaction.run {}

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

  describe '#labels' do
    context 'when request goes to Grape endpoint' do
      before do
        route = double(:route, request_method: 'GET', path: '/:version/projects/:id/archive(.:format)', origin: '/:version/projects/:id/archive')
        endpoint = double(:endpoint, route: route,
          options: { for: API::Projects, path: [":id/archive"] },
          namespace: "/projects")

        env['api.endpoint'] = endpoint

        # This is needed since we're not actually making a request, which would trigger the controller pushing to the context
        ::Gitlab::ApplicationContext.push(feature_category: 'projects')
      end

      it 'provides labels with the method and path of the route in the grape endpoint' do
        expect(transaction.labels).to eq({
          controller: 'Grape',
          action: 'GET /projects/:id/archive',
          feature_category: 'projects',
          endpoint_id: 'GET /:version/projects/:id/archive'
        })
      end

      it 'contains only the labels defined for transactions' do
        expect(transaction.labels.keys).to contain_exactly(*described_class::BASE_LABEL_KEYS)
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
      let(:controller_class) { double(:controller_class, name: 'TestController') }

      before do
        controller = double(:controller, class: controller_class, action_name: 'show', request: request)
        env['action_controller.instance'] = controller
      end

      it 'tags a transaction with the name and action of a controller' do
        expect(transaction.labels).to eq({ controller: 'TestController', action: 'show', feature_category: ::Gitlab::FeatureCategories::FEATURE_CATEGORY_DEFAULT, endpoint_id: 'TestController#show' })
      end

      it 'contains only the labels defined for transactions' do
        expect(transaction.labels.keys).to contain_exactly(*described_class::BASE_LABEL_KEYS)
      end

      context 'when the request content type is not :html' do
        let(:request) { double(:request, format: double(:format, ref: :json)) }

        it 'appends the mime type to the transaction action' do
          expect(transaction.labels).to eq({ controller: 'TestController', action: 'show.json', feature_category: ::Gitlab::FeatureCategories::FEATURE_CATEGORY_DEFAULT, endpoint_id: 'TestController#show' })
        end
      end

      context 'when the request content type is not' do
        let(:request) { double(:request, format: double(:format, ref: 'http://example.com')) }

        it 'does not append the MIME type to the transaction action' do
          expect(transaction.labels).to eq({ controller: 'TestController', action: 'show', feature_category: ::Gitlab::FeatureCategories::FEATURE_CATEGORY_DEFAULT, endpoint_id: 'TestController#show' })
        end
      end

      context 'when the feature category is known' do
        it 'includes it in the feature category label' do
          # This is needed since we're not actually making a request, which would trigger the controller pushing to the context
          ::Gitlab::ApplicationContext.push(feature_category: 'source_code_management')

          expect(transaction.labels).to eq({ controller: 'TestController', action: 'show', feature_category: 'source_code_management', endpoint_id: 'TestController#show' })
        end
      end
    end

    it 'returns no labels when no route information is present in env' do
      expect(transaction.labels).to eq({})
    end
  end

  it_behaves_like 'transaction metrics with labels' do
    let(:request) { double(:request, format: double(:format, ref: :html)) }
    let(:controller_class) { double(:controller_class, name: 'TestController') }
    let(:controller) { double(:controller, class: controller_class, action_name: 'show', request: request) }

    let(:transaction_obj) { described_class.new({ 'action_controller.instance' => controller }) }
    let(:labels) { { controller: 'TestController', action: 'show', feature_category: 'projects', endpoint_id: 'TestController#show' } }

    before do
      ::Gitlab::ApplicationContext.push(feature_category: 'projects')
    end
  end
end
