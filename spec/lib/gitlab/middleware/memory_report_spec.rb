# frozen_string_literal: true

require 'spec_helper'
require 'memory_profiler'

RSpec.describe Gitlab::Middleware::MemoryReport do
  let(:app) { proc { |env| [200, { 'Content-Type' => 'text/plain' }, ['Hello world!']] } }
  let(:middleware) { described_class.new(app) }

  describe '#call' do
    shared_examples 'returns original response' do
      it 'returns original response' do
        expect(MemoryProfiler).not_to receive(:report)

        status, headers, body = middleware.call(env)

        expect(status).to eq(200)
        expect(headers).to eq({ 'Content-Type' => 'text/plain' })
        expect(body.first).to eq('Hello world!')
      end

      it 'does not call the MemoryProfiler' do
        expect(MemoryProfiler).not_to receive(:report)

        middleware.call(env)
      end
    end

    context 'when user is not allowed' do
      before do
        allow(env).to receive(:[]).and_call_original
        allow(env).to receive(:[]).with('warden').and_return(instance_double(Warden::Proxy, user: create(:user)))
      end

      context 'when memory report is not requested' do
        let(:env) { Rack::MockRequest.env_for('/') }

        it_behaves_like 'returns original response'
      end

      context 'when memory report is requested' do
        let(:env) { Rack::MockRequest.env_for('/', params: { 'performance_bar' => 'memory' }) }

        it_behaves_like 'returns original response'
      end
    end

    context 'when user is allowed' do
      before do
        allow(env).to receive(:[]).and_call_original
        allow(env).to receive(:[]).with('warden').and_return(instance_double(Warden::Proxy, user: create(:admin)))
      end

      context 'when memory report is not requested' do
        let(:env) { Rack::MockRequest.env_for('/') }

        it_behaves_like 'returns original response'
      end

      context 'when memory report is requested' do
        let(:env) { Rack::MockRequest.env_for('/', params: { 'performance_bar' => 'memory' }) }

        before do
          allow(app).to receive(:call).and_return(empty_memory_report)
        end

        let(:empty_memory_report) do
          report = MemoryProfiler::Results.new
          report.register_results(MemoryProfiler::StatHash.new, MemoryProfiler::StatHash.new, 1)
        end

        it 'returns a memory report' do
          expect(MemoryProfiler).to receive(:report).and_yield

          status, headers, body = middleware.call(env)

          expect(status).to eq(200)
          expect(headers).to eq({ 'Content-Type' => 'text/plain' })
          expect(body.first).to include('Total allocated: 0 B')
        end

        context 'when something goes wrong with creating the report' do
          before do
            expect(MemoryProfiler).to receive(:report).and_raise(StandardError, 'something went terribly wrong!')
          end

          it 'logs the error' do
            expect(::Gitlab::ErrorTracking).to receive(:track_exception)

            middleware.call(env)
          end

          it 'returns the error' do
            status, headers, body = middleware.call(env)

            expect(status).to eq(500)
            expect(headers).to eq({ 'Content-Type' => 'text/plain' })
            expect(body.first).to include('Could not generate memory report: something went terribly wrong!')
          end
        end
      end
    end
  end
end
