# frozen_string_literal: true

require 'fast_spec_helper'

RSpec.describe Gitlab::Metrics::RackMiddleware do
  let(:app) { double(:app) }

  let(:middleware) { described_class.new(app) }

  let(:env) { { 'REQUEST_METHOD' => 'GET', 'REQUEST_URI' => '/foo' } }

  describe '#call' do
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
end
