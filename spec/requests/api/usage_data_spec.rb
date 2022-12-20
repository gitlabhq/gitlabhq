# frozen_string_literal: true

require 'spec_helper'

RSpec.describe API::UsageData, feature_category: :service_ping do
  let_it_be(:user) { create(:user) }

  describe 'POST /usage_data/increment_counter' do
    let(:endpoint) { '/usage_data/increment_counter' }
    let(:known_event) { "diff_searches" }
    let(:unknown_event) { 'unknown' }

    context 'without CSRF token' do
      it 'returns forbidden' do
        stub_feature_flags(usage_data_api: true)
        allow(Gitlab::RequestForgeryProtection).to receive(:verified?).and_return(false)

        post api(endpoint, user), params: { event: known_event }

        expect(response).to have_gitlab_http_status(:forbidden)
      end
    end

    context 'usage_data_api feature not enabled' do
      it 'returns not_found' do
        stub_feature_flags(usage_data_api: false)

        post api(endpoint, user), params: { event: known_event }

        expect(response).to have_gitlab_http_status(:not_found)
      end
    end

    context 'without authentication' do
      it 'returns 401 response' do
        post api(endpoint), params: { event: known_event }

        expect(response).to have_gitlab_http_status(:unauthorized)
      end
    end

    context 'with authentication' do
      before do
        stub_feature_flags(usage_data_api: true)
        stub_application_setting(usage_ping_enabled: true)
        allow(Gitlab::RequestForgeryProtection).to receive(:verified?).and_return(true)
      end

      context 'when event is missing from params' do
        it 'returns bad request' do
          post api(endpoint, user), params: {}

          expect(response).to have_gitlab_http_status(:bad_request)
        end
      end

      context 'with correct params' do
        before do
          stub_application_setting(usage_ping_enabled: true)
          stub_feature_flags(usage_data_api: true)
          allow(Gitlab::RequestForgeryProtection).to receive(:verified?).and_return(true)
        end

        it 'returns status :ok' do
          expect(Gitlab::UsageDataCounters::BaseCounter).to receive(:count).with("searches")

          post api(endpoint, user), params: { event: known_event }

          expect(response).to have_gitlab_http_status(:ok)
        end
      end

      context 'with unknown event' do
        before do
          skip_feature_flags_yaml_validation
          skip_default_enabled_yaml_check
        end

        it 'returns status ok' do
          expect(Gitlab::UsageDataCounters::BaseCounter).not_to receive(:count)

          post api(endpoint, user), params: { event: unknown_event }

          expect(response).to have_gitlab_http_status(:ok)
        end
      end
    end
  end

  describe 'POST /usage_data/increment_unique_users' do
    let(:endpoint) { '/usage_data/increment_unique_users' }
    let(:known_event) { 'g_compliance_dashboard' }
    let(:unknown_event) { 'unknown' }

    context 'without CSRF token' do
      it 'returns forbidden' do
        stub_feature_flags(usage_data_api: true)
        allow(Gitlab::RequestForgeryProtection).to receive(:verified?).and_return(false)

        post api(endpoint, user), params: { event: known_event }

        expect(response).to have_gitlab_http_status(:forbidden)
      end
    end

    context 'usage_data_api feature not enabled' do
      it 'returns not_found' do
        stub_feature_flags(usage_data_api: false)

        post api(endpoint, user), params: { event: known_event }

        expect(response).to have_gitlab_http_status(:not_found)
      end
    end

    context 'without authentication' do
      it 'returns 401 response' do
        post api(endpoint), params: { event: known_event }

        expect(response).to have_gitlab_http_status(:unauthorized)
      end
    end

    context 'with authentication' do
      before do
        stub_feature_flags(usage_data_api: true)
        stub_application_setting(usage_ping_enabled: true)
        allow(Gitlab::RequestForgeryProtection).to receive(:verified?).and_return(true)
      end

      context 'when event is missing from params' do
        it 'returns bad request' do
          post api(endpoint, user), params: {}

          expect(response).to have_gitlab_http_status(:bad_request)
        end
      end

      context 'with correct params' do
        it 'returns status ok' do
          expect(Gitlab::UsageDataCounters::HLLRedisCounter).to receive(:track).with(anything, known_event, anything)
          # allow other events to also get triggered
          allow(Gitlab::UsageDataCounters::HLLRedisCounter).to receive(:track)

          post api(endpoint, user), params: { event: known_event }

          expect(response).to have_gitlab_http_status(:ok)
        end
      end

      context 'with unknown event' do
        before do
          skip_feature_flags_yaml_validation
        end

        it 'returns status ok' do
          expect(Gitlab::Redis::HLL).not_to receive(:add)

          post api(endpoint, user), params: { event: unknown_event }

          expect(response).to have_gitlab_http_status(:ok)
        end
      end
    end
  end

  describe 'GET /usage_data/metric_definitions' do
    let(:endpoint) { '/usage_data/metric_definitions' }
    let(:metric_yaml) do
      { 'key_path' => 'counter.category.event', 'description' => 'Metric description' }.to_yaml
    end

    context 'without authentication' do
      it 'returns a YAML file', :aggregate_failures do
        allow(Gitlab::Usage::MetricDefinition).to receive(:dump_metrics_yaml).and_return(metric_yaml)

        get api(endpoint)

        expect(response).to have_gitlab_http_status(:ok)
        expect(response.media_type).to eq('application/yaml')
        expect(response.body).to eq(metric_yaml)
      end
    end
  end
end
