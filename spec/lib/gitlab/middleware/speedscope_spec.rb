# frozen_string_literal: true

require 'spec_helper'
require 'stackprof'

RSpec.describe Gitlab::Middleware::Speedscope, feature_category: :shared do
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

        it 'returns a flamegraph' do
          expect(StackProf).to receive(:run).and_call_original

          status, headers, body = middleware.call(env)

          expect(status).to eq(200)
          expect(headers).to eq({ 'Content-Type' => 'text/html' })
          expect(body.first).to include('speedscope-iframe')
        end

        context 'when the stackprof_mode parameter is set and valid' do
          let(:env) { Rack::MockRequest.env_for('/', params: { 'performance_bar' => 'flamegraph', 'stackprof_mode' => 'cpu' }) }

          it 'runs StackProf in the mode specified in the stackprof_mode parameter' do
            expect(StackProf).to receive(:run).with(hash_including(mode: :cpu))

            middleware.call(env)
          end
        end

        context 'when the stackprof_mode parameter is not set' do
          let(:env) { Rack::MockRequest.env_for('/', params: { 'performance_bar' => 'flamegraph' }) }

          it 'runs StackProf in wall mode' do
            expect(StackProf).to receive(:run).with(hash_including(mode: :wall))

            middleware.call(env)
          end
        end

        context 'when the stackprof_mode parameter is invalid' do
          let(:env) { Rack::MockRequest.env_for('/', params: { 'performance_bar' => 'flamegraph', 'stackprof_mode' => 'invalid' }) }

          it 'runs StackProf in wall mode' do
            expect(StackProf).to receive(:run).with(hash_including(mode: :wall))

            middleware.call(env)
          end
        end

        context 'when the stackprof_mode parameter is set to object mode' do
          let(:env) { Rack::MockRequest.env_for('/', params: { 'performance_bar' => 'flamegraph', 'stackprof_mode' => 'object' }) }

          it 'runs StackProf with an interval of 100' do
            expect(StackProf).to receive(:run).with(hash_including(interval: 100))

            middleware.call(env)
          end
        end

        context 'when the stackprof_mode parameter is not set to object mode' do
          let(:env) { Rack::MockRequest.env_for('/', params: { 'performance_bar' => 'flamegraph', 'stackprof_mode' => 'wall' }) }

          it 'runs StackProf with an interval of 10_100' do
            expect(StackProf).to receive(:run).with(hash_including(interval: 10_100))

            middleware.call(env)
          end
        end

        context 'when the request is for JSON' do
          let(:env) do
            Rack::MockRequest.env_for(
              '/', params: { 'performance_bar' => 'flamegraph' }, 'HTTP_ACCEPT' => 'application/json'
            )
          end

          it 'returns a stackprof report as JSON' do
            status, headers, body = middleware.call(env)

            expect(status).to eq(200)
            expect(headers).to eq({ 'Content-Type' => 'application/json' })
            expect(body.first).to include('"mode":"wall"')
          end
        end
      end
    end
  end
end
