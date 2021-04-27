# frozen_string_literal: true

require 'spec_helper'
require 'stackprof'

RSpec.describe Gitlab::Middleware::Speedscope do
  let(:app) { proc { |env| [200, { 'Content-Type' => 'text/plain' }, ['Hello world!']] } }
  let(:middleware) { described_class.new(app) }

  describe '#call' do
    shared_examples 'returns original response' do
      it 'returns original response' do
        expect(StackProf).not_to receive(:run)

        status, headers, body = middleware.call(env)

        expect(status).to eq(200)
        expect(headers).to eq({ 'Content-Type' => 'text/plain' })
        expect(body.first).to eq('Hello world!')
      end
    end

    context 'when flamegraph is not requested' do
      let(:env) { Rack::MockRequest.env_for('/') }

      it_behaves_like 'returns original response'
    end

    context 'when flamegraph requested' do
      let(:env) { Rack::MockRequest.env_for('/', params: { 'performance_bar' => 'flamegraph' }) }

      before do
        allow(env).to receive(:[]).and_call_original
      end

      context 'when user is not allowed' do
        before do
          allow(env).to receive(:[]).with('warden').and_return(double('Warden', user: create(:user)))
        end

        it_behaves_like 'returns original response'
      end

      context 'when user is allowed' do
        before do
          allow(env).to receive(:[]).with('warden').and_return(double('Warden', user: create(:admin)))
        end

        it 'runs StackProf and returns a flamegraph' do
          expect(StackProf).to receive(:run).and_call_original

          status, headers, body = middleware.call(env)

          expect(status).to eq(200)
          expect(headers).to eq({ 'Content-Type' => 'text/html' })
          expect(body.first).to include('speedscope-iframe')
        end
      end
    end
  end
end
