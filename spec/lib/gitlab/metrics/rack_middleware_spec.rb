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

    it 'tracks any raised exceptions' do
      expect(app).to receive(:call).with(env).and_raise(RuntimeError)

      expect_any_instance_of(Gitlab::Metrics::Transaction)
        .to receive(:add_event).with(:rails_exception)

      expect { middleware.call(env) }.to raise_error(RuntimeError)
    end
  end

  describe '#transaction_from_env' do
    let(:transaction) { middleware.transaction_from_env(env) }

    it 'returns a Transaction' do
      expect(transaction).to be_an_instance_of(Gitlab::Metrics::WebTransaction)
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
end
