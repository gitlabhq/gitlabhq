# frozen_string_literal: true

require 'spec_helper'

RSpec.describe API::TrackAPIRequestFromPersonalAccessToken, :request_store,
  :clean_gitlab_redis_shared_state, feature_category: :permissions do
  let_it_be(:user) { create(:user) }
  let_it_be(:legacy_pat) { create(:personal_access_token, user: user) }
  let_it_be(:granular_pat) { create(:granular_pat, user: user) }
  let_it_be(:oauth_token) { create(:oauth_access_token, scopes: [:api], user: user) }
  let_it_be(:ci_build) { create(:ci_build, :running, user: user) }

  let_it_be(:endpoint) { '/test_pat_middleware' }
  let_it_be(:forbidden_endpoint) { '/test_pat_middleware_forbidden' }
  let_it_be(:app) do
    Class.new(API::API).tap do |app|
      app.route_setting :authentication, job_token_allowed: true
      app.route_setting :authorization, skip_granular_token_authorization: true
      app.get(endpoint) do
        authenticate!
        status 200
      end
      app.get(forbidden_endpoint) do
        authenticate!
        forbidden!
      end
    end
  end

  let(:use_legacy_pat_metric) do
    'redis_hll_counters.count_distinct_user_id_from_use_pat_legacy_weekly'
  end

  let(:use_granular_pat_metric) do
    'redis_hll_counters.count_distinct_user_id_from_use_pat_granular_monthly'
  end

  shared_examples 'does not track the use_pat event' do
    it { expect { request }.not_to trigger_internal_events('use_pat') }
  end

  shared_examples 'tracks the use_pat event' do
    it 'tracks the use_pat event with the correct pat_type' do
      expect { request }.to trigger_internal_events('use_pat')
        .with(
          user: user,
          category: 'InternalEventTracking',
          additional_properties: {
            pat_type: expected_pat_type,
            label: "GET /api/:version#{target_endpoint}",
            response_code: expected_response_code
          }
        )
        .and increment_usage_metrics(expected_metric)
    end
  end

  it 'is loaded' do
    expect(API::API.middleware).to include([:use, described_class])
  end

  describe '#after' do
    let(:target_endpoint) { endpoint }
    let(:headers) { { 'Private-Token' => legacy_pat.token } }
    let(:expected_response_code) { 200 }

    subject(:request) { get api(target_endpoint), headers: headers }

    context 'with invalid token(s)' do
      context 'with no token' do
        let(:headers) { {} }

        it_behaves_like 'does not track the use_pat event'
      end

      context 'with non-PAT token types' do
        context 'with a job token' do
          let(:headers) { { 'Job-Token' => ci_build.token } }

          it_behaves_like 'does not track the use_pat event'
        end

        context 'with an OAuth token' do
          subject(:request) { get api(endpoint, oauth_access_token: oauth_token) }

          it_behaves_like 'does not track the use_pat event'
        end
      end
    end

    context 'when the feature flag is disabled' do
      it_behaves_like 'does not track the use_pat event'
    end

    context 'when the feature flag is enabled' do
      before do
        stub_feature_flags(track_api_request_from_personal_access_token: true)
      end

      context 'with PAT types' do
        where(:pat_type, :headers) do
          [
            ['legacy',   { 'Private-Token' => lazy { legacy_pat.token } }],
            ['granular', { 'Private-Token' => lazy { granular_pat.token } }]
          ]
        end

        with_them do
          it_behaves_like 'tracks the use_pat event' do
            let(:expected_pat_type) { pat_type }
            let(:expected_metric) { pat_type == 'legacy' ? use_legacy_pat_metric : use_granular_pat_metric }
          end
        end
      end

      context 'when the response is non-2xx' do
        let(:target_endpoint) { forbidden_endpoint }
        let(:expected_response_code) { 403 }

        it_behaves_like 'tracks the use_pat event' do
          let(:expected_pat_type) { 'legacy' }
          let(:expected_metric) { use_legacy_pat_metric }
        end
      end
    end
  end
end
