require 'spec_helper'

describe Gitlab::Metrics::RackMiddleware do
  let(:app) { double(:app) }

  let(:middleware) { described_class.new(app) }

  let(:env) { { 'REQUEST_METHOD' => 'GET', 'REQUEST_URI' => '/foo' } }

  describe '#call' do
    before do
      expect_any_instance_of(Gitlab::Metrics::Transaction).to receive(:finish)
    end

    it 'tracks a transaction' do
      expect(app).to receive(:call).with(env).and_return('yay')

      expect(middleware.call(env)).to eq('yay')
    end

    it 'tags a transaction with the name and action of a controller' do
      klass      = double(:klass, name: 'TestController', content_type: 'text/html')
      controller = double(:controller, class: klass, action_name: 'show')

      env['action_controller.instance'] = controller

      allow(app).to receive(:call).with(env)

      expect(middleware).to receive(:tag_controller).
        with(an_instance_of(Gitlab::Metrics::Transaction), env)

      middleware.call(env)
    end

    it 'tags a transaction with the method and path of the route in the grape endpoint' do
      route    = double(:route, route_method: "GET", route_path: "/:version/projects/:id/archive(.:format)")
      endpoint = double(:endpoint, route: route)

      env['api.endpoint'] = endpoint

      allow(app).to receive(:call).with(env)

      expect(middleware).to receive(:tag_endpoint).
        with(an_instance_of(Gitlab::Metrics::Transaction), env)

      middleware.call(env)
    end

    it 'tracks any raised exceptions' do
      expect(app).to receive(:call).with(env).and_raise(RuntimeError)

      expect_any_instance_of(Gitlab::Metrics::Transaction).
        to receive(:add_event).with(:rails_exception)

      expect { middleware.call(env) }.to raise_error(RuntimeError)
    end
  end

  describe '#transaction_from_env' do
    let(:transaction) { middleware.transaction_from_env(env) }

    it 'returns a Transaction' do
      expect(transaction).to be_an_instance_of(Gitlab::Metrics::Transaction)
    end

    it 'stores the request method and URI in the transaction as values' do
      expect(transaction.values[:request_method]).to eq('GET')
      expect(transaction.values[:request_uri]).to eq('/foo')
    end

    context "when URI includes sensitive parameters" do
      let(:env) do
        {
          'REQUEST_METHOD' => 'GET',
          'REQUEST_URI'    => '/foo?private_token=my-token',
          'PATH_INFO' => '/foo',
          'QUERY_STRING' => 'private_token=my_token',
          'action_dispatch.parameter_filter' => [:private_token]
        }
      end

      it 'stores the request URI with the sensitive parameters filtered' do
        expect(transaction.values[:request_uri]).to eq('/foo?private_token=[FILTERED]')
      end
    end
  end

  describe '#tag_controller' do
    let(:transaction) { middleware.transaction_from_env(env) }
    let(:content_type) { 'text/html' }

    before do
      klass      = double(:klass, name: 'TestController')
      controller = double(:controller, class: klass, action_name: 'show', content_type: content_type)

      env['action_controller.instance'] = controller
    end

    it 'tags a transaction with the name and action of a controller' do
      middleware.tag_controller(transaction, env)

      expect(transaction.action).to eq('TestController#show')
    end

    context 'when the response content type is not :html' do
      let(:content_type) { 'application/json' }

      it 'appends the mime type to the transaction action' do
        middleware.tag_controller(transaction, env)

        expect(transaction.action).to eq('TestController#show.json')
      end
    end
  end

  describe '#tag_endpoint' do
    let(:transaction) { middleware.transaction_from_env(env) }

    it 'tags a transaction with the method and path of the route in the grape endpount' do
      route    = double(:route, route_method: "GET", route_path: "/:version/projects/:id/archive(.:format)")
      endpoint = double(:endpoint, route: route)

      env['api.endpoint'] = endpoint

      middleware.tag_endpoint(transaction, env)

      expect(transaction.action).to eq('Grape#GET /projects/:id/archive')
    end
  end
end
