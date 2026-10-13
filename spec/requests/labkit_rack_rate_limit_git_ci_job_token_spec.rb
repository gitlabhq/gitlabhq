# frozen_string_literal: true

require 'spec_helper'

# Git over HTTP must stay out of the general web throttles when the Git HTTP
# throttles are disabled, as it does under Rack::Attack. CI job-token Git requests
# resolve no requester at the rack layer, so without that exclusion they are counted
# per IP as unauthenticated web traffic.
RSpec.describe 'Labkit rack rate limiting of Git over HTTP with the Git HTTP throttles disabled',
  :clean_gitlab_redis_rate_limiting, feature_category: :rate_limiting do
  using RSpec::Parameterized::TableSyntax
  include RackAttackSpecHelpers
  include WorkhorseHelpers

  let_it_be(:project) { create(:project, :small_repo, :private) }
  let_it_be(:user) { create(:user, developer_of: project) }
  let_it_be(:token) { create(:personal_access_token, user: user) }
  let_it_be(:build) { create(:ci_build, :running, project: project, user: user) }

  let(:repo_path) { "/#{project.full_path}.git" }
  let(:refs_path) { "#{repo_path}/info/refs?service=git-upload-pack" }
  let(:upload_pack_path) { "#{repo_path}/git-upload-pack" }
  let(:lfs_batch_path) { "#{repo_path}/info/lfs/objects/batch" }
  let(:lfs_params) { { operation: 'download', objects: [{ oid: Digest::SHA256.hexdigest('lfs'), size: 1 }] }.to_json }
  let(:lfs_content_type) { { 'Content-Type' => LfsRequest::CONTENT_TYPE } }
  let(:job_token_headers) do
    workhorse_internal_api_request_header.merge(
      'AUTHORIZATION' => ActionController::HttpAuthentication::Basic.encode_credentials('gitlab-ci-token', build.token)
    )
  end

  let(:job_token_lfs_headers) { job_token_headers.merge(lfs_content_type) }
  let(:token_headers) { workhorse_internal_api_request_header.merge(basic_auth_headers(user, token)) }

  before do
    Gitlab::RackAttack::LabkitRateLimit::ThrottleRegistry.cohorts.each do |cohort|
      stub_feature_flags(
        "rate_limiter_use_labkit_rack_cohort_#{cohort}": true,
        "rate_limiter_use_labkit_rack_cohort_#{cohort}_enforce": true
      )
    end

    stub_lfs_setting(enabled: true)
    stub_application_setting(
      throttle_unauthenticated_enabled: true,
      throttle_unauthenticated_requests_per_period: 1,
      throttle_unauthenticated_period_in_seconds: 60,
      throttle_authenticated_web_enabled: true,
      throttle_authenticated_web_requests_per_period: 1,
      throttle_authenticated_web_period_in_seconds: 60,
      throttle_unauthenticated_git_http_enabled: false,
      throttle_authenticated_git_http_enabled: false
    )
  end

  # Without this, the examples below would also pass if nothing enforced at all.
  it 'still rejects unauthenticated web traffic over the limit' do
    get '/dashboard/projects'

    expect_rejection('throttle_unauthenticated_web') { get '/dashboard/projects' }
  end

  # Rack::Attack counts authenticated LFS as web traffic while its LFS throttle is off.
  # The rejection also proves the token resolved a requester at the rack layer.
  it 'counts personal access token LFS under the authenticated web limit' do
    headers = token_headers.merge(lfs_content_type)

    post lfs_batch_path, params: lfs_params, headers: headers
    expect(response).to have_gitlab_http_status(:ok)

    expect_rejection('throttle_authenticated_web') { post lfs_batch_path, params: lfs_params, headers: headers }
  end

  where(:case_name, :method, :path, :params, :headers) do
    'job token LFS batch'       | :post | ref(:lfs_batch_path)   | ref(:lfs_params) | ref(:job_token_lfs_headers)
    'job token info/refs'       | :get  | ref(:refs_path)        | nil              | ref(:job_token_headers)
    'job token git-upload-pack' | :post | ref(:upload_pack_path) | nil              | ref(:job_token_headers)
    'PAT info/refs'             | :get  | ref(:refs_path)        | nil              | ref(:token_headers)
    'PAT git-upload-pack'       | :post | ref(:upload_pack_path) | nil              | ref(:token_headers)
  end

  with_them do
    it 'serves every request over the web limits' do
      3.times do
        public_send(method, path, params: params, headers: headers)

        expect(response).to have_gitlab_http_status(:ok)
      end
    end
  end
end
