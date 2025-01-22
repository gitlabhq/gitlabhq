# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::Metrics::RequestsRackMiddleware, :aggregate_failures, feature_category: :error_budgets do
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
        expect(Gitlab::Metrics::RailsSlis.request_apdex).to receive(:increment)
          .with(labels: { feature_category: 'unknown', endpoint_id: 'unknown', request_urgency: :default }, success: true)
        expect(Gitlab::Metrics::RailsSlis.request_error_rate).to receive(:increment)
          .with(labels: { feature_category: 'unknown', endpoint_id: 'unknown', request_urgency: :default }, error: false)

        subject.call(env)
      end

      it 'guarantees SLI metrics are incremented with all the required labels' do
        described_class.initialize_slis!

        expect(Gitlab::Metrics::RailsSlis.request_apdex).to receive(:increment).and_call_original
        expect(Gitlab::Metrics::RailsSlis.request_error_rate).to receive(:increment).and_call_original

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

      it 'tracks count and error rate but not duration and apdex' do
        expect(described_class).to receive_message_chain(:http_requests_total, :increment).with(method: 'get', status: '500', feature_category: 'unknown')
        expect(described_class).not_to receive(:http_request_duration_seconds)
        expect(Gitlab::Metrics::RailsSlis).not_to receive(:request_apdex)
        expect(Gitlab::Metrics::RailsSlis.request_error_rate).to receive(:increment)
          .with(labels: { feature_category: 'unknown', endpoint_id: 'unknown', request_urgency: :default }, error: true)

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
        expect(Gitlab::Metrics::RailsSlis).not_to receive(:request_apdex)
        expect(Gitlab::Metrics::RailsSlis.request_error_rate).not_to receive(:increment)

        expect { subject.call(env) }.to raise_error(StandardError)
      end
    end

    context 'application context' do
      context 'when a context is present' do
        before do
          ::Gitlab::ApplicationContext.push(feature_category: 'team_planning', caller_id: 'IssuesController#show')
        end

        it 'adds the feature category to the labels for required metrics' do
          expect(described_class).to receive_message_chain(:http_requests_total, :increment).with(method: 'get', status: '200', feature_category: 'team_planning')
          expect(described_class).not_to receive(:http_health_requests_total)
          expect(Gitlab::Metrics::RailsSlis.request_apdex)
            .to receive(:increment).with(labels: { feature_category: 'team_planning', endpoint_id: 'IssuesController#show', request_urgency: :default }, success: true)
          expect(Gitlab::Metrics::RailsSlis.request_error_rate).to receive(:increment)
            .with(labels: { feature_category: 'team_planning', endpoint_id: 'IssuesController#show', request_urgency: :default }, error: false)

          subject.call(env)
        end

        it 'does not record a feature category for health check endpoints' do
          env['PATH_INFO'] = '/-/liveness'

          expect(described_class).to receive_message_chain(:http_health_requests_total, :increment).with(method: 'get', status: '200')
          expect(described_class).not_to receive(:http_requests_total)
          expect(Gitlab::Metrics::RailsSlis).not_to receive(:request_apdex)
          expect(Gitlab::Metrics::RailsSlis).not_to receive(:request_error_rate)

          subject.call(env)
        end
      end

      context 'when application raises an exception when the feature category context is present' do
        before do
          ::Gitlab::ApplicationContext.push(feature_category: 'team_planning')
          allow(app).to receive(:call).and_raise(StandardError)
        end

        it 'adds the feature category to the labels for http_requests_total' do
          expect(described_class).to receive_message_chain(:http_requests_total, :increment).with(method: 'get', status: 'undefined', feature_category: 'team_planning')

          expect(Gitlab::Metrics::RailsSlis).not_to receive(:request_apdex)
          expect(Gitlab::Metrics::RailsSlis).not_to receive(:request_error_rate)
          expect { subject.call(env) }.to raise_error(StandardError)
        end
      end

      context 'when the context is not available' do
        it 'sets the required labels to unknown' do
          expect(described_class).to receive_message_chain(:http_requests_total, :increment).with(method: 'get', status: '200', feature_category: 'unknown')
          expect(described_class).not_to receive(:http_health_requests_total)
          expect(Gitlab::Metrics::RailsSlis.request_apdex).to receive(:increment)
            .with(labels: { feature_category: 'unknown', endpoint_id: 'unknown', request_urgency: :default }, success: true)
          expect(Gitlab::Metrics::RailsSlis.request_error_rate).to receive(:increment)
            .with(labels: { feature_category: 'unknown', endpoint_id: 'unknown', request_urgency: :default }, error: false)

          subject.call(env)
        end
      end

      context 'SLI satisfactory' do
        where(:request_urgency_name, :duration, :success) do
          [
            [:high, 0.1, true],
            [:high, 0.25, false],
            [:high, 0.3, false],
            [:medium, 0.3, true],
            [:medium, 0.5, false],
            [:medium, 0.6, false],
            [:default, 0.6, true],
            [:default, 1.0, false],
            [:default, 1.2, false],
            [:low, 4.5, true],
            [:low, 5.0, false],
            [:low, 6, false]
          ]
        end

        with_them do
          context 'Grape API handler having expected duration setup' do
            let(:api_handler) do
              request_urgency = request_urgency_name
              Class.new(::API::Base) do
                feature_category :hello_world, ['/projects/:id/archive']
                urgency request_urgency, ['/projects/:id/archive']
              end
            end

            let(:endpoint) do
              route = double(:route, request_method: 'GET', path: '/:version/projects/:id/archive(.:format)')
              double(:endpoint,
                route: route, options: { for: api_handler, path: [":id/archive"] }, namespace: "/projects")
            end

            let(:env) { { 'api.endpoint' => endpoint, 'REQUEST_METHOD' => 'GET' } }

            before do
              ::Gitlab::ApplicationContext.push(feature_category: 'hello_world', caller_id: 'GET /projects/:id/archive')
              allow(Gitlab::Metrics::System).to receive(:monotonic_time).and_return(100, 100 + duration)
            end

            it "captures SLI metrics" do
              expect(Gitlab::Metrics::RailsSlis.request_apdex).to receive(:increment).with(
                labels: {
                  feature_category: 'hello_world',
                  endpoint_id: 'GET /projects/:id/archive',
                  request_urgency: request_urgency_name
                },
                success: success
              )
              expect(Gitlab::Metrics::RailsSlis.request_error_rate).to receive(:increment).with(
                labels: {
                  feature_category: 'hello_world',
                  endpoint_id: 'GET /projects/:id/archive',
                  request_urgency: request_urgency_name
                },
                error: false
              )

              subject.call(env)
            end
          end

          context 'Rails controller having expected duration setup' do
            let(:controller) do
              request_urgency = request_urgency_name
              Class.new(ApplicationController) do
                feature_category :hello_world, [:index, :show]
                urgency request_urgency, [:index, :show]
              end
            end

            let(:env) do
              controller_instance = controller.new
              controller_instance.action_name = :index
              { 'action_controller.instance' => controller_instance, 'REQUEST_METHOD' => 'GET' }
            end

            before do
              ::Gitlab::ApplicationContext.push(feature_category: 'hello_world', caller_id: 'AnonymousController#index')
              allow(Gitlab::Metrics::System).to receive(:monotonic_time).and_return(100, 100 + duration)
            end

            it "captures SLI metrics" do
              expect(Gitlab::Metrics::RailsSlis.request_apdex).to receive(:increment).with(
                labels: {
                  feature_category: 'hello_world',
                  endpoint_id: 'AnonymousController#index',
                  request_urgency: request_urgency_name
                },
                success: success
              )
              expect(Gitlab::Metrics::RailsSlis.request_error_rate).to receive(:increment).with(
                labels: {
                  feature_category: 'hello_world',
                  endpoint_id: 'AnonymousController#index',
                  request_urgency: request_urgency_name
                },
                error: false
              )

              subject.call(env)
            end
          end
        end

        context 'Grape API without expected duration' do
          let(:endpoint) do
            route = double(:route, request_method: 'GET', path: '/:version/projects/:id/archive(.:format)')
            double(:endpoint,
              route: route, options: { for: api_handler, path: [":id/archive"] }, namespace: "/projects")
          end

          let(:env) { { 'api.endpoint' => endpoint, 'REQUEST_METHOD' => 'GET' } }

          let(:api_handler) { Class.new(::API::Base) }

          it "falls back request's expectation to default (1 second)" do
            allow(Gitlab::Metrics::System).to receive(:monotonic_time).and_return(100, 100.9)
            expect(Gitlab::Metrics::RailsSlis.request_apdex).to receive(:increment).with(
              labels: {
                feature_category: 'unknown',
                endpoint_id: 'unknown',
                request_urgency: :default
              },
              success: true
            )
            expect(Gitlab::Metrics::RailsSlis.request_error_rate).to receive(:increment).with(
              labels: {
                feature_category: 'unknown',
                endpoint_id: 'unknown',
                request_urgency: :default
              },
              error: false
            )
            subject.call(env)

            allow(Gitlab::Metrics::System).to receive(:monotonic_time).and_return(100, 101)
            expect(Gitlab::Metrics::RailsSlis.request_apdex).to receive(:increment).with(
              labels: {
                feature_category: 'unknown',
                endpoint_id: 'unknown',
                request_urgency: :default
              },
              success: false
            )
            expect(Gitlab::Metrics::RailsSlis.request_error_rate).to receive(:increment).with(
              labels: {
                feature_category: 'unknown',
                endpoint_id: 'unknown',
                request_urgency: :default
              },
              error: false
            )
            subject.call(env)
          end
        end

        context 'Rails controller without expected duration' do
          let(:controller) { Class.new(ApplicationController) }

          let(:env) do
            controller_instance = controller.new
            controller_instance.action_name = :index
            { 'action_controller.instance' => controller_instance, 'REQUEST_METHOD' => 'GET' }
          end

          it "falls back request's expectation to default (1 second)" do
            allow(Gitlab::Metrics::System).to receive(:monotonic_time).and_return(100, 100.9)
            expect(Gitlab::Metrics::RailsSlis.request_apdex).to receive(:increment).with(
              labels: {
                feature_category: 'unknown',
                endpoint_id: 'unknown',
                request_urgency: :default
              },
              success: true
            )
            expect(Gitlab::Metrics::RailsSlis.request_error_rate).to receive(:increment).with(
              labels: {
                feature_category: 'unknown',
                endpoint_id: 'unknown',
                request_urgency: :default
              },
              error: false
            )
            subject.call(env)

            allow(Gitlab::Metrics::System).to receive(:monotonic_time).and_return(100, 101)
            expect(Gitlab::Metrics::RailsSlis.request_apdex).to receive(:increment).with(
              labels: {
                feature_category: 'unknown',
                endpoint_id: 'unknown',
                request_urgency: :default
              },
              success: false
            )
            expect(Gitlab::Metrics::RailsSlis.request_error_rate).to receive(:increment).with(
              labels: {
                feature_category: 'unknown',
                endpoint_id: 'unknown',
                request_urgency: :default
              },
              error: false
            )
            subject.call(env)
          end
        end

        context 'A request with urgency set on the env (from ETag-caching)' do
          let(:env) do
            { described_class::REQUEST_URGENCY_KEY => Gitlab::EndpointAttributes::Config::REQUEST_URGENCIES[:medium],
              'REQUEST_METHOD' => 'GET' }
          end

          it 'records the request with the correct urgency' do
            allow(Gitlab::Metrics::System).to receive(:monotonic_time).and_return(100, 100.1)
            expect(Gitlab::Metrics::RailsSlis.request_apdex).to receive(:increment).with(
              labels: {
                feature_category: 'unknown',
                endpoint_id: 'unknown',
                request_urgency: :medium
              },
              success: true
            )
            expect(Gitlab::Metrics::RailsSlis.request_error_rate).to receive(:increment).with(
              labels: {
                feature_category: 'unknown',
                endpoint_id: 'unknown',
                request_urgency: :medium
              },
              error: false
            )

            subject.call(env)
          end
        end

        context 'An unknown request' do
          let(:env) do
            { 'REQUEST_METHOD' => 'GET' }
          end

          it "falls back request's expectation to default (1 second)" do
            allow(Gitlab::Metrics::System).to receive(:monotonic_time).and_return(100, 100.9)
            expect(Gitlab::Metrics::RailsSlis.request_apdex).to receive(:increment).with(
              labels: {
                feature_category: 'unknown',
                endpoint_id: 'unknown',
                request_urgency: :default
              },
              success: true
            )
            expect(Gitlab::Metrics::RailsSlis.request_error_rate).to receive(:increment).with(
              labels: {
                feature_category: 'unknown',
                endpoint_id: 'unknown',
                request_urgency: :default
              },
              error: false
            )
            subject.call(env)

            allow(Gitlab::Metrics::System).to receive(:monotonic_time).and_return(100, 101)
            expect(Gitlab::Metrics::RailsSlis.request_apdex).to receive(:increment).with(
              labels: {
                feature_category: 'unknown',
                endpoint_id: 'unknown',
                request_urgency: :default
              },
              success: false
            )
            expect(Gitlab::Metrics::RailsSlis.request_error_rate).to receive(:increment).with(
              labels: {
                feature_category: 'unknown',
                endpoint_id: 'unknown',
                request_urgency: :default
              },
              error: false
            )
            subject.call(env)
          end
        end
      end
    end

    describe '.initialize_slis!', :prometheus do
      it "sets labels for http_requests_total" do
        expected_labels = []

        described_class::HTTP_METHODS.each do |method, statuses|
          statuses.each do |status|
            described_class::FEATURE_CATEGORIES_TO_INITIALIZE.each do |feature_category|
              expected_labels << { method: method.to_s, status: status.to_s, feature_category: feature_category.to_s }
            end
          end
        end

        described_class.initialize_slis!

        expect(described_class.http_requests_total.values.keys).to contain_exactly(*expected_labels)
      end

      it 'sets labels for http_request_duration_seconds' do
        expected_labels = described_class::HTTP_METHODS.keys.map { |method| { method: method } }

        described_class.initialize_slis!

        expect(described_class.http_request_duration_seconds.values.keys).to include(*expected_labels)
      end

      it 'has every label in config/feature_categories.yml' do
        defaults = [::Gitlab::FeatureCategories::FEATURE_CATEGORY_DEFAULT, 'not_owned']
        feature_categories = Gitlab::FeatureCategories.default.categories + defaults

        expect(described_class::FEATURE_CATEGORIES_TO_INITIALIZE).to all(be_in(feature_categories))
      end
    end
  end
end
