# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::Metrics::RequestsRackMiddleware do
  let(:app) { double('app') }

  subject { described_class.new(app) }

  describe '#call' do
    let(:status) { 100 }
    let(:env) { { 'REQUEST_METHOD' => 'GET' } }
    let(:stack_result) { [status, {}, 'body'] }

    before do
      allow(app).to receive(:call).and_return(stack_result)
    end

    context '@app.call succeeds with 200' do
      before do
        allow(app).to receive(:call).and_return([200, nil, nil])
      end

      it 'increments requests count' do
        expect(described_class).to receive_message_chain(:http_request_total, :increment).with(method: 'get')

        subject.call(env)
      end

      RSpec::Matchers.define :a_positive_execution_time do
        match { |actual| actual > 0 }
      end

      it 'measures execution time' do
        expect(described_class).to receive_message_chain(:http_request_duration_seconds, :observe).with({ status: '200', method: 'get' }, a_positive_execution_time)

        Timecop.scale(3600) { subject.call(env) }
      end

      context 'request is a health check endpoint' do
        it 'increments health endpoint counter' do
          env['PATH_INFO'] = '/-/liveness'

          expect(described_class).to receive_message_chain(:http_health_requests_total, :increment).with(method: 'get')

          subject.call(env)
        end

        context 'with trailing slash' do
          before do
            env['PATH_INFO'] = '/-/liveness/'
          end

          it 'increments health endpoint counter' do
            expect(described_class).to receive_message_chain(:http_health_requests_total, :increment).with(method: 'get')

            subject.call(env)
          end
        end

        context 'with percent encoded values' do
          before do
            env['PATH_INFO'] = '/-/%6D%65%74%72%69%63%73' # /-/metrics
          end

          it 'increments health endpoint counter' do
            expect(described_class).to receive_message_chain(:http_health_requests_total, :increment).with(method: 'get')

            subject.call(env)
          end
        end
      end

      context 'request is not a health check endpoint' do
        it 'does not increment health endpoint counter' do
          env['PATH_INFO'] = '/-/ordinary-requests'

          expect(described_class).not_to receive(:http_health_requests_total)

          subject.call(env)
        end

        context 'path info is a root path' do
          before do
            env['PATH_INFO'] = '/-/'
          end

          it 'does not increment health endpoint counter' do
            expect(described_class).not_to receive(:http_health_requests_total)

            subject.call(env)
          end
        end

        context 'path info is a subpath' do
          before do
            env['PATH_INFO'] = '/-/health/subpath'
          end

          it 'does not increment health endpoint counter' do
            expect(described_class).not_to receive(:http_health_requests_total)

            subject.call(env)
          end
        end
      end
    end

    context '@app.call throws exception' do
      let(:http_request_duration_seconds) { double('http_request_duration_seconds') }

      before do
        allow(app).to receive(:call).and_raise(StandardError)
        allow(described_class).to receive(:http_request_duration_seconds).and_return(http_request_duration_seconds)
      end

      it 'increments exceptions count' do
        expect(described_class).to receive_message_chain(:rack_uncaught_errors_count, :increment)

        expect { subject.call(env) }.to raise_error(StandardError)
      end

      it 'increments requests count' do
        expect(described_class).to receive_message_chain(:http_request_total, :increment).with(method: 'get')

        expect { subject.call(env) }.to raise_error(StandardError)
      end

      it "does't measure request execution time" do
        expect(described_class.http_request_duration_seconds).not_to receive(:increment)

        expect { subject.call(env) }.to raise_error(StandardError)
      end
    end

    describe '.initialize_http_request_duration_seconds' do
      it "sets labels" do
        expected_labels = []
        described_class::HTTP_METHODS.each do |method, statuses|
          statuses.each do |status|
            expected_labels << { method: method, status: status.to_s }
          end
        end

        described_class.initialize_http_request_duration_seconds
        expect(described_class.http_request_duration_seconds.values.keys).to include(*expected_labels)
      end
    end
  end
end
