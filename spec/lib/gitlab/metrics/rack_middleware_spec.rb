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
      klass      = double(:klass, name: 'TestController')
      controller = double(:controller, class: klass, action_name: 'show')

      env['action_controller.instance'] = controller

      allow(app).to receive(:call).with(env)

      expect(middleware).to receive(:tag_controller).
        with(an_instance_of(Gitlab::Metrics::Transaction), env)

      middleware.call(env)
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
  end

  describe '#tag_controller' do
    let(:transaction) { middleware.transaction_from_env(env) }

    it 'tags a transaction with the name and action of a controller' do
      klass      = double(:klass, name: 'TestController')
      controller = double(:controller, class: klass, action_name: 'show')

      env['action_controller.instance'] = controller

      middleware.tag_controller(transaction, env)

      expect(transaction.action).to eq('TestController#show')
    end
  end
end
