require 'spec_helper'

describe Gitlab::Sherlock::Middleware do
  let(:app) { double(:app) }
  let(:middleware) { described_class.new(app) }

  describe '#call' do
    describe 'when instrumentation is enabled' do
      it 'instruments a request' do
        allow(middleware).to receive(:instrument?).and_return(true)
        allow(middleware).to receive(:call_with_instrumentation)

        middleware.call({})
      end
    end

    describe 'when instrumentation is disabled' do
      it "doesn't instrument a request" do
        allow(middleware).to receive(:instrument).and_return(false)
        allow(app).to receive(:call)

        middleware.call({})
      end
    end
  end

  describe '#call_with_instrumentation' do
    it 'instruments a request' do
      trans = double(:transaction)
      retval = 'cats are amazing'
      env = {}

      allow(app).to receive(:call).with(env).and_return(retval)
      allow(middleware).to receive(:transaction_from_env).and_return(trans)
      allow(trans).to receive(:run).and_yield.and_return(retval)
      allow(Gitlab::Sherlock.collection).to receive(:add).with(trans)

      middleware.call_with_instrumentation(env)
    end
  end

  describe '#instrument?' do
    it 'returns false for a text/css request' do
      env = { 'HTTP_ACCEPT' => 'text/css', 'REQUEST_URI' => '/' }

      expect(middleware.instrument?(env)).to eq(false)
    end

    it 'returns false for a request to a Sherlock route' do
      env = {
        'HTTP_ACCEPT' => 'text/html',
        'REQUEST_URI' => '/sherlock/transactions'
      }

      expect(middleware.instrument?(env)).to eq(false)
    end

    it 'returns true for a request that should be instrumented' do
      env = {
        'HTTP_ACCEPT' => 'text/html',
        'REQUEST_URI' => '/cats'
      }

      expect(middleware.instrument?(env)).to eq(true)
    end
  end

  describe '#transaction_from_env' do
    it 'returns a Transaction' do
      env = {
        'HTTP_ACCEPT' => 'text/html',
        'REQUEST_URI' => '/cats'
      }

      expect(middleware.transaction_from_env(env))
        .to be_an_instance_of(Gitlab::Sherlock::Transaction)
    end
  end
end
