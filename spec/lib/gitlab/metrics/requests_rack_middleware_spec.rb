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
        expect(described_class).to receive_message_chain(:http_request_total, :increment).with(method: 'get', status: 200, feature_category: 'unknown')

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
        ['/-/liveness', '/-/liveness/', '/-/%6D%65%74%72%69%63%73'].each do |path|
          context "when path is #{path}" do
            before do
              env['PATH_INFO'] = path
            end

            it 'increments health endpoint counter rather than overall counter' do
              expect(described_class).to receive_message_chain(:http_health_requests_total, :increment).with(method: 'get', status: 200)
              expect(described_class).not_to receive(:http_request_total)

              subject.call(env)
            end

            it 'does not record the request duration' do
              expect(described_class).not_to receive(:http_request_duration_seconds)

              subject.call(env)
            end
          end
        end
      end

      context 'request is not a health check endpoint' do
        ['/-/ordinary-requests', '/-/', '/-/health/subpath'].each do |path|
          context "when path is #{path}" do
            before do
              env['PATH_INFO'] = path
            end

            it 'increments overall counter rather than health endpoint counter' do
              expect(described_class).to receive_message_chain(:http_request_total, :increment).with(method: 'get', status: 200, feature_category: 'unknown')
              expect(described_class).not_to receive(:http_health_requests_total)

              subject.call(env)
            end

            it 'records the request duration' do
              expect(described_class)
                .to receive_message_chain(:http_request_duration_seconds, :observe)
                      .with({ method: 'get', status: '200' }, a_positive_execution_time)

              subject.call(env)
            end
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
        expect(described_class).to receive_message_chain(:http_request_total, :increment).with(method: 'get', status: 'undefined', feature_category: 'unknown')

        expect { subject.call(env) }.to raise_error(StandardError)
      end

      it "does't measure request execution time" do
        expect(described_class.http_request_duration_seconds).not_to receive(:increment)

        expect { subject.call(env) }.to raise_error(StandardError)
      end
    end

    context 'when a feature category header is present' do
      before do
        allow(app).to receive(:call).and_return([200, { described_class::FEATURE_CATEGORY_HEADER => 'issue_tracking' }, nil])
      end

      it 'adds the feature category to the labels for http_request_total' do
        expect(described_class).to receive_message_chain(:http_request_total, :increment).with(method: 'get', status: 200, feature_category: 'issue_tracking')

        subject.call(env)
      end

      it 'does not record a feature category for health check endpoints' do
        env['PATH_INFO'] = '/-/liveness'

        expect(described_class).to receive_message_chain(:http_health_requests_total, :increment).with(method: 'get', status: 200)
        expect(described_class).not_to receive(:http_request_total)

        subject.call(env)
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
