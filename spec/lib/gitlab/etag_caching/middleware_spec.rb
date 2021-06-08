# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::EtagCaching::Middleware, :clean_gitlab_redis_shared_state do
  let(:app) { double(:app) }
  let(:middleware) { described_class.new(app) }
  let(:app_status_code) { 200 }
  let(:if_none_match) { nil }
  let(:enabled_path) { '/gitlab-org/gitlab-foss/noteable/issue/1/notes' }
  let(:endpoint) { 'issue_notes' }

  describe '.skip!' do
    it 'sets the skip header on the response' do
      rsp = ActionDispatch::Response.new
      rsp.set_header('Anything', 'Else')

      described_class.skip!(rsp)

      expect(rsp.headers.to_h).to eq(described_class::SKIP_HEADER_KEY => '1', 'Anything' => 'Else')
    end
  end

  context 'when ETag caching is not enabled for current route' do
    let(:path) { '/gitlab-org/gitlab-foss/tree/master/noteable/issue/1/notes' }

    before do
      mock_app_response
    end

    it 'does not add ETag headers' do
      _, headers, _ = middleware.call(build_request(path, if_none_match))

      expect(headers['ETag']).to be_nil
      expect(headers['X-Gitlab-From-Cache']).to be_nil
    end

    it 'passes status code from app' do
      status, _, _ = middleware.call(build_request(path, if_none_match))

      expect(status).to eq app_status_code
    end

    it 'does not set feature category attribute' do
      expect(Gitlab::ApplicationContext).not_to receive(:push)

      _, _, _ = middleware.call(build_request(path, if_none_match))
    end
  end

  context 'when there is no ETag in store for given resource' do
    let(:path) { enabled_path }

    before do
      mock_app_response
      mock_value_in_store(nil)
    end

    it 'generates ETag' do
      expect_next_instance_of(Gitlab::EtagCaching::Store) do |instance|
        expect(instance).to receive(:touch).and_return('123')
      end

      middleware.call(build_request(path, if_none_match))
    end

    context 'when If-None-Match header was specified' do
      let(:if_none_match) { 'W/"abc"' }

      it 'tracks "etag_caching_key_not_found" event' do
        expect(Gitlab::Metrics).to receive(:add_event)
          .with(:etag_caching_middleware_used, endpoint: endpoint)
        expect(Gitlab::Metrics).to receive(:add_event)
          .with(:etag_caching_key_not_found, endpoint: endpoint)

        middleware.call(build_request(path, if_none_match))
      end
    end
  end

  context 'when there is ETag in store for given resource' do
    let(:path) { enabled_path }

    before do
      mock_app_response
      mock_value_in_store('123')
    end

    it 'returns the correct headers' do
      _, headers, _ = middleware.call(build_request(path, if_none_match))

      expect(headers['ETag']).to eq 'W/"123"'
    end
  end

  context 'when the matching route requests that the ETag is skipped' do
    let(:path) { enabled_path }
    let(:app) do
      proc do |_env|
        response = ActionDispatch::Response.new

        described_class.skip!(response)

        [200, response.headers.to_h, '']
      end
    end

    it 'returns the correct headers' do
      expect(app).to receive(:call).and_call_original

      _, headers, _ = middleware.call(build_request(path, if_none_match))

      expect(headers).not_to have_key('ETag')
      expect(headers).not_to have_key(described_class::SKIP_HEADER_KEY)
    end
  end

  shared_examples 'sends a process_action.action_controller notification' do |status_code|
    let(:expected_items) do
      {
        etag_route: endpoint,
        params:     {},
        format:     :html,
        method:     'GET',
        path:       enabled_path,
        status:     status_code
      }
    end

    it 'sends the expected payload' do
      payload = payload_for('process_action.action_controller') do
        middleware.call(build_request(path, if_none_match))
      end

      expect(payload).to include(expected_items)

      expect(payload[:headers].env['HTTP_IF_NONE_MATCH']).to eq('W/"123"')
    end

    it 'log subscriber processes action' do
      expect_any_instance_of(ActionController::LogSubscriber).to receive(:process_action)
        .with(instance_of(ActiveSupport::Notifications::Event))
        .and_call_original

      middleware.call(build_request(path, if_none_match))
    end
  end

  context 'when If-None-Match header matches ETag in store' do
    let(:path) { enabled_path }
    let(:if_none_match) { 'W/"123"' }

    before do
      mock_value_in_store('123')
    end

    it 'does not call app' do
      expect(app).not_to receive(:call)

      middleware.call(build_request(path, if_none_match))
    end

    it 'returns status code 304' do
      status, _, _ = middleware.call(build_request(path, if_none_match))

      expect(status).to eq 304
    end

    it 'sets correct headers' do
      _, headers, _ = middleware.call(build_request(path, if_none_match))

      expect(headers).to include('X-Gitlab-From-Cache' => 'true')
    end

    it "pushes route's feature category to the context" do
      expect(Gitlab::ApplicationContext).to receive(:push).with(
        feature_category: 'issue_tracking'
      )

      _, _, _ = middleware.call(build_request(path, if_none_match))
    end

    it_behaves_like 'sends a process_action.action_controller notification', 304

    it 'returns empty body' do
      _, _, body = middleware.call(build_request(path, if_none_match))

      expect(body).to be_empty
    end

    it 'tracks "etag_caching_cache_hit" event' do
      expect(Gitlab::Metrics).to receive(:add_event)
        .with(:etag_caching_middleware_used, endpoint: endpoint)
      expect(Gitlab::Metrics).to receive(:add_event)
        .with(:etag_caching_cache_hit, endpoint: endpoint)

      middleware.call(build_request(path, if_none_match))
    end

    context 'when polling is disabled' do
      before do
        allow(Gitlab::PollingInterval).to receive(:polling_enabled?)
          .and_return(false)
      end

      it 'returns status code 429' do
        status, _, _ = middleware.call(build_request(path, if_none_match))

        expect(status).to eq 429
      end

      it_behaves_like 'sends a process_action.action_controller notification', 429
    end
  end

  context 'when If-None-Match header does not match ETag in store' do
    let(:path) { enabled_path }
    let(:if_none_match) { 'W/"abc"' }

    before do
      mock_value_in_store('123')
    end

    it 'calls app' do
      expect(app).to receive(:call).and_return([app_status_code, {}, ['body']])

      middleware.call(build_request(path, if_none_match))
    end

    it 'tracks "etag_caching_resource_changed" event' do
      mock_app_response

      expect(Gitlab::Metrics).to receive(:add_event)
        .with(:etag_caching_middleware_used, endpoint: endpoint)
      expect(Gitlab::Metrics).to receive(:add_event)
        .with(:etag_caching_resource_changed, endpoint: endpoint)

      middleware.call(build_request(path, if_none_match))
    end
  end

  context 'when If-None-Match header is not specified' do
    let(:path) { enabled_path }

    before do
      mock_value_in_store('123')
      mock_app_response
    end

    it 'tracks "etag_caching_header_missing" event' do
      expect(Gitlab::Metrics).to receive(:add_event)
        .with(:etag_caching_middleware_used, endpoint: endpoint)
      expect(Gitlab::Metrics).to receive(:add_event)
        .with(:etag_caching_header_missing, endpoint: endpoint)

      middleware.call(build_request(path, if_none_match))
    end
  end

  context 'when GitLab instance is using a relative URL' do
    before do
      mock_app_response
    end

    it 'uses full path as cache key' do
      env = {
        'PATH_INFO' => enabled_path,
        'SCRIPT_NAME' => '/relative-gitlab'
      }

      expect_next_instance_of(Gitlab::EtagCaching::Store) do |instance|
        expect(instance).to receive(:get).with("/relative-gitlab#{enabled_path}").and_return(nil)
      end

      middleware.call(env)
    end
  end

  def mock_app_response
    allow(app).to receive(:call).and_return([app_status_code, {}, ['body']])
  end

  def mock_value_in_store(value)
    allow_next_instance_of(Gitlab::EtagCaching::Store) do |instance|
      allow(instance).to receive(:get).and_return(value)
    end
  end

  def build_request(path, if_none_match)
    { 'PATH_INFO' => path,
      'HTTP_IF_NONE_MATCH' => if_none_match,
      'rack.input' => '',
      'REQUEST_METHOD' => 'GET' }
  end

  def payload_for(event)
    payload = nil
    subscription = ActiveSupport::Notifications.subscribe event do |_, _, _, _, extra_payload|
      payload = extra_payload
    end

    yield

    ActiveSupport::Notifications.unsubscribe(subscription)
    payload
  end
end
