# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::Metrics::RequestsRackMiddleware, :aggregate_failures do
  let(:app) { double('app') }

  subject { described_class.new(app) }

  around do |example|
    # Simulate application context middleware
    # In fact, this middleware cleans up the contexts after a request lifecycle
    ::Gitlab::ApplicationContext.with_context({}) do
      example.run
    end
  end

  describe '#call' do
    let(:status) { 200 }
    let(:env) { { 'REQUEST_METHOD' => 'GET' } }
    let(:stack_result) { [status, {}, 'body'] }

    before do
      allow(app).to receive(:call).and_return(stack_result)
    end

    context '@app.call succeeds with 200' do
      before do
        allow(app).to receive(:call).and_return([200, nil, nil])
      end

      RSpec::Matchers.define :a_positive_execution_time do
        match { |actual| actual > 0 }
      end

      it 'tracks request count and duration' do
        expect(described_class).to receive_message_chain(:http_requests_total, :increment).with(method: 'get', status: '200', feature_category: 'unknown')
        expect(described_class).to receive_message_chain(:http_request_duration_seconds, :observe).with({ method: 'get' }, a_positive_execution_time)

        subject.call(env)
      end

      context 'request is a health check endpoint' do
        ['/-/liveness', '/-/liveness/', '/-/%6D%65%74%72%69%63%73'].each do |path|
          context "when path is #{path}" do
            before do
              env['PATH_INFO'] = path
            end

            it 'increments health endpoint counter rather than overall counter and does not record duration' do
              expect(described_class).not_to receive(:http_request_duration_seconds)
              expect(described_class).not_to receive(:http_requests_total)
              expect(described_class).to receive_message_chain(:http_health_requests_total, :increment).with(method: 'get', status: '200')

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

            it 'increments regular counters and tracks duration' do
              expect(described_class).to receive_message_chain(:http_requests_total, :increment).with(method: 'get', status: '200', feature_category: 'unknown')
              expect(described_class).not_to receive(:http_health_requests_total)
              expect(described_class)
                .to receive_message_chain(:http_request_duration_seconds, :observe)
                      .with({ method: 'get' }, a_positive_execution_time)

              subject.call(env)
            end
          end
        end
      end
    end

    context '@app.call returns an error code' do
      let(:status) { '500' }

      it 'tracks count but not duration' do
        expect(described_class).to receive_message_chain(:http_requests_total, :increment).with(method: 'get', status: '500', feature_category: 'unknown')
        expect(described_class).not_to receive(:http_request_duration_seconds)

        subject.call(env)
      end
    end

    context '@app.call throws exception' do
      let(:http_request_duration_seconds) { double('http_request_duration_seconds') }
      let(:http_requests_total) { double('http_requests_total') }

      before do
        allow(app).to receive(:call).and_raise(StandardError)
        allow(described_class).to receive(:http_request_duration_seconds).and_return(http_request_duration_seconds)
        allow(described_class).to receive(:http_requests_total).and_return(http_requests_total)
      end

      it 'tracks the correct metrics' do
        expect(described_class).to receive_message_chain(:rack_uncaught_errors_count, :increment)
        expect(described_class).to receive_message_chain(:http_requests_total, :increment).with(method: 'get', status: 'undefined', feature_category: 'unknown')
        expect(described_class.http_request_duration_seconds).not_to receive(:observe)

        expect { subject.call(env) }.to raise_error(StandardError)
      end
    end

    context 'feature category header' do
      context 'when a feature category context is present' do
        before do
          ::Gitlab::ApplicationContext.push(feature_category: 'issue_tracking')
        end

        it 'adds the feature category to the labels for http_requests_total' do
          expect(described_class).to receive_message_chain(:http_requests_total, :increment).with(method: 'get', status: '200', feature_category: 'issue_tracking')
          expect(described_class).not_to receive(:http_health_requests_total)

          subject.call(env)
        end

        it 'does not record a feature category for health check endpoints' do
          env['PATH_INFO'] = '/-/liveness'

          expect(described_class).to receive_message_chain(:http_health_requests_total, :increment).with(method: 'get', status: '200')
          expect(described_class).not_to receive(:http_requests_total)

          subject.call(env)
        end
      end

      context 'when application raises an exception when the feature category context is present' do
        before do
          ::Gitlab::ApplicationContext.push(feature_category: 'issue_tracking')
          allow(app).to receive(:call).and_raise(StandardError)
        end

        it 'adds the feature category to the labels for http_requests_total' do
          expect(described_class).to receive_message_chain(:http_requests_total, :increment).with(method: 'get', status: 'undefined', feature_category: 'issue_tracking')

          expect { subject.call(env) }.to raise_error(StandardError)
        end
      end

      context 'when the feature category context is not available' do
        it 'sets the feature category to unknown' do
          expect(described_class).to receive_message_chain(:http_requests_total, :increment).with(method: 'get', status: '200', feature_category: 'unknown')
          expect(described_class).not_to receive(:http_health_requests_total)

          subject.call(env)
        end
      end
    end

    describe '.initialize_metrics', :prometheus do
      it "sets labels for http_requests_total" do
        expected_labels = []

        described_class::HTTP_METHODS.each do |method, statuses|
          statuses.each do |status|
            described_class::FEATURE_CATEGORIES_TO_INITIALIZE.each do |feature_category|
              expected_labels << { method: method.to_s, status: status.to_s, feature_category: feature_category.to_s }
            end
          end
        end

        described_class.initialize_metrics

        expect(described_class.http_requests_total.values.keys).to contain_exactly(*expected_labels)
      end

      it 'sets labels for http_request_duration_seconds' do
        expected_labels = described_class::HTTP_METHODS.keys.map { |method| { method: method } }

        described_class.initialize_metrics

        expect(described_class.http_request_duration_seconds.values.keys).to include(*expected_labels)
      end

      it 'has every label in config/feature_categories.yml' do
        defaults = [described_class::FEATURE_CATEGORY_DEFAULT, 'not_owned']
        feature_categories = YAML.load_file(Rails.root.join('config', 'feature_categories.yml')).map(&:strip) + defaults

        expect(described_class::FEATURE_CATEGORIES_TO_INITIALIZE).to all(be_in(feature_categories))
      end
    end
  end
end
