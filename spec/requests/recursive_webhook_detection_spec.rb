# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Recursive webhook detection', :sidekiq_inline, :clean_gitlab_redis_shared_state, :request_store do
  include StubRequests

  let_it_be(:user) { create(:user) }
  let_it_be(:project) { create(:project, :repository, namespace: user.namespace, creator: user) }
  let_it_be(:merge_request) { create(:merge_request, source_project: project) }
  let_it_be(:project_hook) { create(:project_hook, project: project, merge_requests_events: true) }
  let_it_be(:system_hook) { create(:system_hook, merge_requests_events: true) }

  # Trigger a change to the merge request to fire the webhooks.
  def trigger_web_hooks
    params = { merge_request: { description: FFaker::Lorem.sentence } }
    put project_merge_request_path(project, merge_request), params: params, headers: headers
  end

  def stub_requests
    stub_full_request(project_hook.url, method: :post, ip_address: '8.8.8.8')
    stub_full_request(system_hook.url, method: :post, ip_address: '8.8.8.9')
  end

  before do
    login_as(user)
  end

  context 'when the request headers include the recursive webhook detection header' do
    let(:uuid) { SecureRandom.uuid }
    let(:headers) { { Gitlab::WebHooks::RecursionDetection::UUID::HEADER => uuid } }

    it 'executes all webhooks, logs no errors, and the webhook requests contain the same UUID header', :aggregate_failures do
      stub_requests

      expect(Gitlab::AuthLogger).not_to receive(:error)

      trigger_web_hooks

      expect(WebMock).to have_requested(:post, stubbed_hostname(project_hook.url))
        .with { |req| req.headers['X-Gitlab-Event-Uuid'] == uuid }
        .once
      expect(WebMock).to have_requested(:post, stubbed_hostname(system_hook.url))
        .with { |req| req.headers['X-Gitlab-Event-Uuid'] == uuid }
        .once
    end

    shared_examples 'when the feature flag is disabled' do
      it 'executes and logs no errors' do
        stub_feature_flags(webhook_recursion_detection: false)
        stub_requests

        expect(Gitlab::AuthLogger).not_to receive(:error)

        trigger_web_hooks

        expect(WebMock).to have_requested(:post, stubbed_hostname(project_hook.url)).once
        expect(WebMock).to have_requested(:post, stubbed_hostname(system_hook.url)).once
      end
    end

    context 'when one of the webhooks is recursive' do
      before do
        # Recreate the necessary state for the previous request to be
        # considered made from the webhook.
        Gitlab::WebHooks::RecursionDetection.set_request_uuid(uuid)
        Gitlab::WebHooks::RecursionDetection.register!(project_hook)
        Gitlab::WebHooks::RecursionDetection.set_request_uuid(nil)
      end

      it 'executes all webhooks and logs an error for the recursive hook', :aggregate_failures do
        stub_requests

        expect(Gitlab::AuthLogger).to receive(:error).with(
          include(
            message: 'Webhook recursion detected and will be blocked in future',
            hook_id: project_hook.id,
            recursion_detection: {
              uuid: uuid,
              ids: [project_hook.id]
            }
          )
        ).twice # Twice: once in `#async_execute`, and again in `#execute`.

        trigger_web_hooks

        expect(WebMock).to have_requested(:post, stubbed_hostname(project_hook.url)).once
        expect(WebMock).to have_requested(:post, stubbed_hostname(system_hook.url)).once
      end

      include_examples 'when the feature flag is disabled'
    end

    context 'when the count limit has been reached' do
      let_it_be(:previous_hooks) { create_list(:project_hook, 3) }

      before do
        stub_const('Gitlab::WebHooks::RecursionDetection::COUNT_LIMIT', 2)
        # Recreate the necessary state for a number of previous webhooks to
        # have been triggered previously.
        Gitlab::WebHooks::RecursionDetection.set_request_uuid(uuid)
        previous_hooks.each { Gitlab::WebHooks::RecursionDetection.register!(_1) }
        Gitlab::WebHooks::RecursionDetection.set_request_uuid(nil)
      end

      it 'executes and logs errors for all hooks', :aggregate_failures do
        stub_requests
        previous_hook_ids = previous_hooks.map(&:id)

        expect(Gitlab::AuthLogger).to receive(:error).with(
          include(
            message: 'Webhook recursion detected and will be blocked in future',
            hook_id: project_hook.id,
            recursion_detection: {
              uuid: uuid,
              ids: include(*previous_hook_ids)
            }
          )
        ).twice
        expect(Gitlab::AuthLogger).to receive(:error).with(
          include(
            message: 'Webhook recursion detected and will be blocked in future',
            hook_id: system_hook.id,
            recursion_detection: {
              uuid: uuid,
              ids: include(*previous_hook_ids)
            }
          )
        ).twice

        trigger_web_hooks

        expect(WebMock).to have_requested(:post, stubbed_hostname(project_hook.url)).once
        expect(WebMock).to have_requested(:post, stubbed_hostname(system_hook.url)).once
      end
    end

    include_examples 'when the feature flag is disabled'
  end

  context 'when the recursive webhook detection header is absent' do
    let(:headers) { {} }

    let(:uuid_header_spy) do
      Class.new do
        attr_reader :values

        def initialize
          @values = []
        end

        def to_proc
          proc do |method, *args|
            method.call(*args).tap do |headers|
              @values << headers[Gitlab::WebHooks::RecursionDetection::UUID::HEADER]
            end
          end
        end
      end.new
    end

    before do
      allow(Gitlab::WebHooks::RecursionDetection).to receive(:header).at_least(:once).and_wrap_original(&uuid_header_spy)
    end

    it 'executes all webhooks, logs no errors, and the webhook requests contain different UUID headers', :aggregate_failures do
      stub_requests

      expect(Gitlab::AuthLogger).not_to receive(:error)

      trigger_web_hooks

      uuid_headers = uuid_header_spy.values

      expect(uuid_headers).to all(be_present)
      expect(uuid_headers.uniq.length).to eq(2)
      expect(WebMock).to have_requested(:post, stubbed_hostname(project_hook.url))
        .with { |req| uuid_headers.include?(req.headers['X-Gitlab-Event-Uuid']) }
        .once
      expect(WebMock).to have_requested(:post, stubbed_hostname(system_hook.url))
        .with { |req| uuid_headers.include?(req.headers['X-Gitlab-Event-Uuid']) }
        .once
    end

    it 'uses new UUID values between requests' do
      stub_requests

      trigger_web_hooks
      trigger_web_hooks

      uuid_headers = uuid_header_spy.values

      expect(uuid_headers).to all(be_present)
      expect(uuid_headers.length).to eq(4)
      expect(uuid_headers.uniq.length).to eq(4)
      expect(WebMock).to have_requested(:post, stubbed_hostname(project_hook.url)).twice
      expect(WebMock).to have_requested(:post, stubbed_hostname(system_hook.url)).twice
    end
  end
end
