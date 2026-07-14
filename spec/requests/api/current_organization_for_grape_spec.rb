# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Current.organization resolution in Grape API', feature_category: :organization do
  before do
    stub_feature_flags(set_current_organization_for_grape_api: true)
  end

  let_it_be(:default_organization) { create(:organization, :default) } # rubocop:disable Gitlab/RSpec/AvoidCreateDefaultOrganization -- needed for fallback
  let_it_be(:user_organization) { create(:organization) }
  let_it_be(:project_organization) { create(:organization) }
  let_it_be(:header_organization) { create(:organization) }

  let_it_be(:user) do
    create(:user, organizations: [user_organization]).tap do |u|
      u.update!(organization: user_organization)
    end
  end

  let_it_be(:project) do
    create(:project, :public, organization: project_organization).tap do |p|
      p.add_developer(user)
    end
  end

  def expect_logged_organization_id(expected_id)
    expect(::API::API::LOG_FORMATTER).to receive(:call) do |_severity, _datetime, _, data|
      expect(data.stringify_keys).to include('meta.organization_id' => expected_id)
    end
  end

  def expect_no_logged_organization_id
    expect(::API::API::LOG_FORMATTER).to receive(:call) do |_severity, _datetime, _, data|
      expect(data.stringify_keys).not_to include('meta.organization_id')
    end
  end

  describe 'X-GitLab-Organization-ID header' do
    it 'takes precedence over the authenticated user' do
      pat = create(:personal_access_token, user: user)

      expect_logged_organization_id(header_organization.id)

      get api("/projects/#{project.id}", personal_access_token: pat),
        headers: { 'X-GitLab-Organization-ID' => header_organization.id.to_s }

      expect(response).to have_gitlab_http_status(:ok)
    end
  end

  describe 'Personal Access Token' do
    let_it_be(:pat) { create(:personal_access_token, user: user) }

    it 'resolves to the user organization (via private_token query param)' do
      expect_logged_organization_id(user_organization.id)

      get api("/projects/#{project.id}", personal_access_token: pat)

      expect(response).to have_gitlab_http_status(:ok)
    end

    it 'resolves to the user organization (via PRIVATE-TOKEN header)' do
      expect_logged_organization_id(user_organization.id)

      get api("/projects/#{project.id}"), headers: { 'PRIVATE-TOKEN' => pat.token }

      expect(response).to have_gitlab_http_status(:ok)
    end

    it 'resolves to the user organization (via Authorization: Bearer)' do
      expect_logged_organization_id(user_organization.id)

      get api("/projects/#{project.id}"), headers: { 'Authorization' => "Bearer #{pat.token}" }

      expect(response).to have_gitlab_http_status(:ok)
    end
  end

  describe 'Group access token' do
    let_it_be(:group) { create(:group, :public, organization: user_organization) }
    let_it_be(:group_bot) do
      create(:user, :project_bot, organizations: [user_organization]).tap do |bot|
        bot.update!(organization: user_organization)
        group.add_developer(bot)
      end
    end

    let_it_be(:group_access_token) { create(:personal_access_token, user: group_bot) }

    it 'resolves to the bot user organization' do
      expect_logged_organization_id(user_organization.id)

      get api("/projects/#{project.id}", personal_access_token: group_access_token)

      expect(response).to have_gitlab_http_status(:ok)
    end
  end

  describe 'Project access token' do
    let_it_be(:project_bot) do
      create(:user, :project_bot, organizations: [project_organization]).tap do |bot|
        bot.update!(organization: project_organization)
        project.add_developer(bot)
      end
    end

    let_it_be(:project_access_token) { create(:personal_access_token, user: project_bot) }

    it 'resolves to the bot user organization' do
      expect_logged_organization_id(project_organization.id)

      get api("/projects/#{project.id}", personal_access_token: project_access_token)

      expect(response).to have_gitlab_http_status(:ok)
    end
  end

  describe 'OAuth bearer token' do
    let_it_be(:oauth_token) { create(:oauth_access_token, resource_owner: user, scopes: 'api') }

    it 'resolves to the user organization (via Authorization header)' do
      expect_logged_organization_id(user_organization.id)

      get api("/projects/#{project.id}"),
        headers: { 'Authorization' => "Bearer #{oauth_token.plaintext_token}" }

      expect(response).to have_gitlab_http_status(:ok)
    end
  end

  describe 'CI job token' do
    let_it_be(:pipeline) { create(:ci_pipeline, project: project) }
    let_it_be(:build) { create(:ci_build, :running, pipeline: pipeline, user: user) }

    # /projects/:id/merge_requests is one of the few endpoints that opts in
    # via route_setting :authentication, job_token_allowed: true.
    let(:path) { "/projects/#{project.id}/merge_requests" }

    it 'resolves to the job user organization (via job_token query param)' do
      expect_logged_organization_id(user_organization.id)

      get api(path, job_token: build.token)

      expect(response).to have_gitlab_http_status(:ok)
    end

    it 'resolves to the job user organization (via JOB-TOKEN header)' do
      expect_logged_organization_id(user_organization.id)

      get api(path), headers: { 'JOB-TOKEN' => build.token }

      expect(response).to have_gitlab_http_status(:ok)
    end
  end

  describe 'Deploy token' do
    let_it_be(:deploy_token) { create(:deploy_token, projects: [project]) }

    it 'falls back to the default organization (deploy tokens are not user-based)' do
      expect_logged_organization_id(default_organization.id)

      get api("/projects/#{project.id}/registry/repositories"),
        headers: { 'Deploy-Token' => deploy_token.token }

      # Endpoint returns 404 when the registry is disabled, but the global hook still fires.
      expect(response).to have_gitlab_http_status(:ok).or have_gitlab_http_status(:not_found)
    end
  end

  describe 'Runner authentication token' do
    let_it_be(:runner_organization) { create(:organization) }
    let_it_be(:runner_project) { create(:project, organization: runner_organization) }
    let_it_be(:runner) { create(:ci_runner, :project, projects: [runner_project]) }

    it 'is set by the runner endpoint to the runner organization (global hook opted out)' do
      expect_logged_organization_id(runner_organization.id)

      post api('/runners/verify'), params: { token: runner.token }

      expect(response).to have_gitlab_http_status(:ok)
    end
  end

  describe 'Internal API (gitlab-shell shared secret)' do
    include GitlabShellHelpers

    let_it_be(:key) { create(:key, user: user) }

    it 'resolves to the gitlab-shell actor user organization' do
      expect_logged_organization_id(user_organization.id)

      get api('/internal/discover'),
        params: { key_id: key.id },
        headers: gitlab_shell_internal_api_request_header

      expect(response).to have_gitlab_http_status(:ok)
    end
  end

  describe 'Unauthenticated public endpoint' do
    it 'falls back to the default organization on the project list' do
      expect_logged_organization_id(default_organization.id)

      get api('/projects')

      expect(response).to have_gitlab_http_status(:ok)
    end

    it 'falls back to the default organization on a single public project' do
      expect_logged_organization_id(default_organization.id)

      get api("/projects/#{project.id}")

      expect(response).to have_gitlab_http_status(:ok)
    end

    it 'falls back to the default organization on a single public group' do
      public_group = create(:group, :public, organization: project_organization)

      expect_logged_organization_id(default_organization.id)

      get api("/groups/#{public_group.id}")

      expect(response).to have_gitlab_http_status(:ok)
    end

    it 'lets the X-GitLab-Organization-ID header override the fallback' do
      expect_logged_organization_id(header_organization.id)

      get api('/projects'),
        headers: { 'X-GitLab-Organization-ID' => header_organization.id.to_s }

      expect(response).to have_gitlab_http_status(:ok)
    end
  end

  describe 'Authentication still fails for invalid or wrong-type tokens' do
    it 'rejects an invalid Personal Access Token with 401' do
      get api('/personal_access_tokens'),
        headers: { 'PRIVATE-TOKEN' => 'invalid-pat-token' }

      expect(response).to have_gitlab_http_status(:unauthorized)
    end

    it 'rejects a revoked Personal Access Token with 401' do
      revoked_pat = create(:personal_access_token, :revoked, user: user)

      get api('/personal_access_tokens', personal_access_token: revoked_pat)

      expect(response).to have_gitlab_http_status(:unauthorized)
    end

    it 'rejects an expired Personal Access Token with 401' do
      expired_pat = create(:personal_access_token, :expired, user: user)

      get api('/personal_access_tokens', personal_access_token: expired_pat)

      expect(response).to have_gitlab_http_status(:unauthorized)
    end

    it 'rejects a deploy token on an endpoint that requires a user with 401' do
      deploy_token = create(:deploy_token, projects: [project])

      get api('/personal_access_tokens'),
        headers: { 'Deploy-Token' => deploy_token.token }

      expect(response).to have_gitlab_http_status(:unauthorized)
    end

    it 'rejects a job token on an endpoint that does not opt into job tokens with 401' do
      pipeline = create(:ci_pipeline, project: project)
      build = create(:ci_build, :running, pipeline: pipeline, user: user)

      # /personal_access_tokens does not declare job_token_allowed.
      get api('/personal_access_tokens', job_token: build.token)

      expect(response).to have_gitlab_http_status(:unauthorized)
    end

    it 'rejects an invalid runner token with 403' do
      post api('/runners/verify'), params: { token: 'invalid-runner-token' }

      expect(response).to have_gitlab_http_status(:forbidden)
    end
  end

  describe 'Anonymous requests against protected endpoints' do
    it 'returns 401 on GET /user without a token' do
      get api('/user')

      expect(response).to have_gitlab_http_status(:unauthorized)
    end

    it 'returns 401 on GET /personal_access_tokens without a token' do
      get api('/personal_access_tokens')

      expect(response).to have_gitlab_http_status(:unauthorized)
    end

    it 'returns 401 on POST /projects without a token' do
      post api('/projects'), params: { name: 'test' }

      expect(response).to have_gitlab_http_status(:unauthorized)
    end

    it 'returns 404 on GET /projects/:id for a private project without a token' do
      private_project = create(:project, :private, organization: project_organization)

      get api("/projects/#{private_project.id}")

      # GitLab hides the existence of private projects from anonymous users.
      expect(response).to have_gitlab_http_status(:not_found)
    end
  end

  describe 'Cluster agent token (KAS, opted out)' do
    let(:jwt_secret) { SecureRandom.random_bytes(Gitlab::Kas::SECRET_LENGTH) }
    let(:jwt_token) do
      JWT.encode(
        { 'iss' => Gitlab::Kas::JWT_ISSUER, 'aud' => Gitlab::Kas::JWT_AUDIENCE },
        Gitlab::Kas.secret,
        'HS256'
      )
    end

    before do
      allow(Gitlab::Kas).to receive(:secret).and_return(jwt_secret)
    end

    it 'leaves Current.organization unassigned (global hook opted out)' do
      expect_no_logged_organization_id

      post api('/internal/kubernetes/usage_metrics'),
        params: { counters: { gitops_sync: 1 } },
        headers: { Gitlab::Kas::INTERNAL_API_KAS_REQUEST_HEADER => jwt_token }

      expect(response).to have_gitlab_http_status(:no_content)
    end
  end
end
