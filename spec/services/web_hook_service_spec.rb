# frozen_string_literal: true

require 'spec_helper'

RSpec.describe WebHookService do
  include StubRequests

  let_it_be(:project) { create(:project) }
  let_it_be_with_reload(:project_hook) { create(:project_hook, project: project) }

  let(:headers) do
    {
      'Content-Type' => 'application/json',
      'User-Agent' => "GitLab/#{Gitlab::VERSION}",
      'X-Gitlab-Event' => 'Push Hook'
    }
  end

  let(:data) do
    { before: 'oldrev', after: 'newrev', ref: 'ref' }
  end

  let(:service_instance) { described_class.new(project_hook, data, :push_hooks) }

  around do |example|
    travel_to(Time.current) { example.run }
  end

  describe '#initialize' do
    before do
      stub_application_setting(setting_name => setting)
    end

    shared_examples_for 'respects outbound network setting' do
      context 'when local requests are allowed' do
        let(:setting) { true }

        it { expect(hook.request_options[:allow_local_requests]).to be_truthy }
      end

      context 'when local requests are not allowed' do
        let(:setting) { false }

        it { expect(hook.request_options[:allow_local_requests]).to be_falsey }
      end
    end

    context 'when SystemHook' do
      let(:setting_name) { :allow_local_requests_from_system_hooks }
      let(:hook) { described_class.new(build(:system_hook), data, :system_hook) }

      include_examples 'respects outbound network setting'
    end

    context 'when ProjectHook' do
      let(:setting_name) { :allow_local_requests_from_web_hooks_and_services }
      let(:hook) { described_class.new(build(:project_hook), data, :project_hook) }

      include_examples 'respects outbound network setting'
    end
  end

  describe '#execute' do
    context 'when token is defined' do
      let_it_be(:project_hook) { create(:project_hook, :token) }

      it 'POSTs to the webhook URL' do
        stub_full_request(project_hook.url, method: :post)

        service_instance.execute

        expect(WebMock).to have_requested(:post, stubbed_hostname(project_hook.url)).with(
          headers: headers.merge({ 'X-Gitlab-Token' => project_hook.token })
        ).once
      end
    end

    it 'POSTs the data as JSON' do
      stub_full_request(project_hook.url, method: :post)

      service_instance.execute

      expect(WebMock).to have_requested(:post, stubbed_hostname(project_hook.url)).with(
        headers: headers
      ).once
    end

    context 'when auth credentials are present' do
      let_it_be(:url) {'https://example.org'}
      let_it_be(:project_hook) { create(:project_hook, url: 'https://demo:demo@example.org/') }

      it 'uses the credentials' do
        stub_full_request(url, method: :post)

        service_instance.execute

        expect(WebMock).to have_requested(:post, stubbed_hostname(url)).with(
          headers: headers.merge('Authorization' => 'Basic ZGVtbzpkZW1v')
        ).once
      end
    end

    context 'when auth credentials are partial present' do
      let_it_be(:url) {'https://example.org'}
      let_it_be(:project_hook) { create(:project_hook, url: 'https://demo@example.org/') }

      it 'uses the credentials anyways' do
        stub_full_request(url, method: :post)

        service_instance.execute

        expect(WebMock).to have_requested(:post, stubbed_hostname(url)).with(
          headers: headers.merge('Authorization' => 'Basic ZGVtbzo=')
        ).once
      end
    end

    it 'catches exceptions' do
      stub_full_request(project_hook.url, method: :post).to_raise(StandardError.new('Some error'))

      expect { service_instance.execute }.to raise_error(StandardError)
    end

    it 'does not execute disabled hooks' do
      project_hook.update!(recent_failures: 4)

      expect(service_instance.execute).to eq({ status: :error, message: 'Hook disabled' })
    end

    it 'handles exceptions' do
      exceptions = Gitlab::HTTP::HTTP_ERRORS + [
        Gitlab::Json::LimitedEncoder::LimitExceeded, URI::InvalidURIError
      ]

      exceptions.each do |exception_class|
        exception = exception_class.new('Exception message')
        project_hook.enable!

        stub_full_request(project_hook.url, method: :post).to_raise(exception)
        expect(service_instance.execute).to eq({ status: :error, message: exception.to_s })
        expect { service_instance.execute }.not_to raise_error
      end
    end

    context 'when url is not encoded' do
      let_it_be(:project_hook) { create(:project_hook, url: 'http://server.com/my path/') }

      it 'handles exceptions' do
        expect(service_instance.execute).to eq(status: :error, message: 'bad URI(is not URI?): "http://server.com/my path/"')
        expect { service_instance.execute }.not_to raise_error
      end
    end

    context 'when request body size is too big' do
      it 'does not perform the request' do
        stub_const("#{described_class}::REQUEST_BODY_SIZE_LIMIT", 10.bytes)

        expect(service_instance.execute).to eq({ status: :error, message: "Gitlab::Json::LimitedEncoder::LimitExceeded" })
      end
    end

    it 'handles 200 status code' do
      stub_full_request(project_hook.url, method: :post).to_return(status: 200, body: 'Success')

      expect(service_instance.execute).to include({ status: :success, http_status: 200, message: 'Success' })
    end

    it 'handles 2xx status codes' do
      stub_full_request(project_hook.url, method: :post).to_return(status: 201, body: 'Success')

      expect(service_instance.execute).to include({ status: :success, http_status: 201, message: 'Success' })
    end

    context 'execution logging' do
      let(:hook_log) { project_hook.web_hook_logs.last }

      def run_service
        service_instance.execute
        ::WebHooks::LogExecutionWorker.drain
        project_hook.reload
      end

      context 'with success' do
        before do
          stub_full_request(project_hook.url, method: :post).to_return(status: 200, body: 'Success')
        end

        it 'log successful execution' do
          run_service

          expect(hook_log.trigger).to eq('push_hooks')
          expect(hook_log.url).to eq(project_hook.url)
          expect(hook_log.request_headers).to eq(headers)
          expect(hook_log.response_body).to eq('Success')
          expect(hook_log.response_status).to eq('200')
          expect(hook_log.execution_duration).to be > 0
          expect(hook_log.internal_error_message).to be_nil
        end

        it 'does not log in the service itself' do
          expect { service_instance.execute }.not_to change(::WebHookLog, :count)
        end

        it 'does not increment the failure count' do
          expect { run_service }.not_to change(project_hook, :recent_failures)
        end

        it 'does not change the disabled_until attribute' do
          expect { run_service }.not_to change(project_hook, :disabled_until)
        end

        context 'when the hook had previously failed' do
          before do
            project_hook.update!(recent_failures: 2)
          end

          it 'resets the failure count' do
            expect { run_service }.to change(project_hook, :recent_failures).to(0)
          end
        end
      end

      context 'with bad request' do
        before do
          stub_full_request(project_hook.url, method: :post).to_return(status: 400, body: 'Bad request')
        end

        it 'logs failed execution' do
          run_service

          expect(hook_log).to have_attributes(
            trigger: eq('push_hooks'),
            url: eq(project_hook.url),
            request_headers: eq(headers),
            response_body: eq('Bad request'),
            response_status: eq('400'),
            execution_duration: be > 0,
            internal_error_message: be_nil
          )
        end

        it 'increments the failure count' do
          expect { run_service }.to change(project_hook, :recent_failures).by(1)
        end

        it 'does not change the disabled_until attribute' do
          expect { run_service }.not_to change(project_hook, :disabled_until)
        end

        it 'does not allow the failure count to overflow' do
          project_hook.update!(recent_failures: 32767)

          expect { run_service }.not_to change(project_hook, :recent_failures)
        end

        context 'when the web_hooks_disable_failed FF is disabled' do
          before do
            # Hook will only be executed if the flag is disabled.
            stub_feature_flags(web_hooks_disable_failed: false)
          end

          it 'does not allow the failure count to overflow' do
            project_hook.update!(recent_failures: 32767)

            expect { run_service }.not_to change(project_hook, :recent_failures)
          end
        end
      end

      context 'with exception' do
        before do
          stub_full_request(project_hook.url, method: :post).to_raise(SocketError.new('Some HTTP Post error'))
        end

        it 'log failed execution' do
          run_service

          expect(hook_log.trigger).to eq('push_hooks')
          expect(hook_log.url).to eq(project_hook.url)
          expect(hook_log.request_headers).to eq(headers)
          expect(hook_log.response_body).to eq('')
          expect(hook_log.response_status).to eq('internal error')
          expect(hook_log.execution_duration).to be > 0
          expect(hook_log.internal_error_message).to eq('Some HTTP Post error')
        end

        it 'does not increment the failure count' do
          expect { run_service }.not_to change(project_hook, :recent_failures)
        end

        it 'backs off' do
          expect { run_service }.to change(project_hook, :disabled_until)
        end

        it 'increases the backoff count' do
          expect { run_service }.to change(project_hook, :backoff_count).by(1)
        end

        context 'when the previous cool-off was near the maximum' do
          before do
            project_hook.update!(disabled_until: 5.minutes.ago, backoff_count: 8)
          end

          it 'sets the disabled_until attribute' do
            expect { run_service }.to change(project_hook, :disabled_until).to(1.day.from_now)
          end
        end

        context 'when we have backed-off many many times' do
          before do
            project_hook.update!(disabled_until: 5.minutes.ago, backoff_count: 365)
          end

          it 'sets the disabled_until attribute' do
            expect { run_service }.to change(project_hook, :disabled_until).to(1.day.from_now)
          end
        end
      end

      context 'with unsafe response body' do
        before do
          stub_full_request(project_hook.url, method: :post).to_return(status: 200, body: "\xBB")
          run_service
        end

        it 'log successful execution' do
          expect(hook_log.trigger).to eq('push_hooks')
          expect(hook_log.url).to eq(project_hook.url)
          expect(hook_log.request_headers).to eq(headers)
          expect(hook_log.response_body).to eq('')
          expect(hook_log.response_status).to eq('200')
          expect(hook_log.execution_duration).to be > 0
          expect(hook_log.internal_error_message).to be_nil
        end
      end
    end
  end

  describe '#async_execute' do
    def expect_to_perform_worker(hook)
      expect(WebHookWorker).to receive(:perform_async).with(hook.id, data, 'push_hooks')
    end

    def expect_to_rate_limit(hook, threshold:, throttled: false)
      expect(Gitlab::ApplicationRateLimiter).to receive(:throttled?)
        .with(:web_hook_calls, scope: [hook], threshold: threshold)
        .and_return(throttled)
    end

    context 'when rate limiting is not configured' do
      it 'queues a worker without tracking the call' do
        expect(Gitlab::ApplicationRateLimiter).not_to receive(:throttled?)
        expect_to_perform_worker(project_hook)

        service_instance.async_execute
      end
    end

    context 'when rate limiting is configured' do
      let_it_be(:threshold) { 3 }
      let_it_be(:plan_limits) { create(:plan_limits, :default_plan, web_hook_calls: threshold) }

      it 'queues a worker and tracks the call' do
        expect_to_rate_limit(project_hook, threshold: threshold)
        expect_to_perform_worker(project_hook)

        service_instance.async_execute
      end

      context 'when the hook is throttled (via mock)' do
        before do
          expect_to_rate_limit(project_hook, threshold: threshold, throttled: true)
        end

        it 'does not queue a worker and logs an error' do
          expect(WebHookWorker).not_to receive(:perform_async)

          expect(Gitlab::AuthLogger).to receive(:error).with(
            include(
              message: 'Webhook rate limit exceeded',
              hook_id: project_hook.id,
              hook_type: 'ProjectHook',
              hook_name: 'push_hooks',
              "correlation_id" => kind_of(String),
              "meta.project" => project.full_path,
              "meta.related_class" => 'ProjectHook',
              "meta.root_namespace" => project.root_namespace.full_path
            )
          )

          service_instance.async_execute
        end
      end

      context 'when the hook is throttled (via Redis)', :clean_gitlab_redis_cache do
        before do
          # Set a high interval to avoid intermittent failures in CI
          allow(Gitlab::ApplicationRateLimiter).to receive(:rate_limits).and_return(
            web_hook_calls: { interval: 1.day }
          )

          expect_to_perform_worker(project_hook).exactly(threshold).times

          threshold.times { service_instance.async_execute }
        end

        it 'stops queueing workers and logs errors' do
          expect(Gitlab::AuthLogger).to receive(:error).twice

          2.times { service_instance.async_execute }
        end

        it 'still queues workers for other hooks' do
          other_hook = create(:project_hook)

          expect_to_perform_worker(other_hook)

          described_class.new(other_hook, data, :push_hooks).async_execute
        end
      end
    end

    context 'when hook has custom context attributes' do
      it 'includes the attributes in the worker context' do
        expect(WebHookWorker).to receive(:perform_async) do
          expect(Gitlab::ApplicationContext.current).to include(
            'meta.project' => project_hook.project.full_path,
            'meta.root_namespace' => project.root_ancestor.path,
            'meta.related_class' => 'ProjectHook'
          )
        end

        service_instance.async_execute
      end
    end
  end
end
