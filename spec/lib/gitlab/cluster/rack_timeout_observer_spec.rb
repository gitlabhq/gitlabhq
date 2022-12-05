# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::Cluster::RackTimeoutObserver do
  let(:counter) { Gitlab::Metrics::NullMetric.instance }

  before do
    allow(Gitlab::Metrics).to receive(:counter)
      .with(any_args)
      .and_return(counter)
  end

  describe '#callback' do
    context 'when request times out' do
      let(:env) do
        {
          ::Rack::Timeout::ENV_INFO_KEY => double(state: :timed_out),
          'action_dispatch.request.parameters' => {
            'controller' => 'foo',
            'action' => 'bar'
          }
        }
      end

      subject { described_class.new }

      it 'increments counter' do
        expect(counter)
          .to receive(:increment)
          .with({ controller: 'foo', action: 'bar', route: nil, state: :timed_out })

        subject.callback.call(env)
      end
    end

    context 'when request expires' do
      let(:endpoint) { double }
      let(:env) do
        {
          ::Rack::Timeout::ENV_INFO_KEY => double(state: :expired),
          Grape::Env::API_ENDPOINT => endpoint
        }
      end

      subject { described_class.new }

      it 'increments counter' do
        allow(endpoint).to receive_message_chain('route.pattern.origin') { 'foobar' }
        expect(counter)
          .to receive(:increment)
          .with({ controller: nil, action: nil, route: 'foobar', state: :expired })

        subject.callback.call(env)
      end
    end

    context 'when request is being processed' do
      let(:endpoint) { double }
      let(:env) do
        {
          ::Rack::Timeout::ENV_INFO_KEY => double(state: :active),
          Grape::Env::API_ENDPOINT => endpoint
        }
      end

      subject { described_class.new }

      it 'does not increment counter' do
        allow(endpoint).to receive_message_chain('route.pattern.origin') { 'foobar' }
        expect(counter).not_to receive(:increment)

        subject.callback.call(env)
      end
    end

    context 'when request contains invalid string' do
      let(:env) do
        {
          ::Rack::Timeout::ENV_INFO_KEY => double(state: :timed_out),
          'action_dispatch.request.parameters' => {
            'controller' => 'foo',
            'action' => '\u003c',
            'route' => '?8\u003c/x'
          }
        }
      end

      subject { described_class.new }

      it 'sanitizes string' do
        expect(counter)
          .to receive(:increment)
          .with({ controller: 'foo', action: '\\u003c', route: '?8\\u003c/x', state: :timed_out })

        subject.callback.call(env)
      end
    end
  end
end
