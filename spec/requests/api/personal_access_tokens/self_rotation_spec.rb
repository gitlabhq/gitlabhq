# frozen_string_literal: true

require 'spec_helper'

RSpec.describe API::PersonalAccessTokens::SelfRotation, feature_category: :system_access do
  let(:path) { '/personal_access_tokens/self/rotate' }
  let(:token) { create(:personal_access_token, user: current_user) }
  let(:expiry_date) { 1.week.from_now }
  let(:params) { {} }

  let_it_be(:current_user) { create(:user) }

  describe 'POST /personal_access_tokens/self/rotate' do
    subject(:rotate_token) { post(api(path, personal_access_token: token), params: params) }

    it_behaves_like 'authorizing granular token permissions', :rotate_personal_access_token do
      let(:boundary_object) { :user }
      let(:user) { current_user }
      let(:request) { post api(path, personal_access_token: pat) }
    end

    shared_examples 'rotating token succeeds' do
      it 'rotate token', :aggregate_failures do
        rotate_token

        expect(response).to have_gitlab_http_status(:ok)
        expect(json_response['token']).not_to eq(token.token)
        expect(json_response['expires_at']).to eq(expiry_date.to_date.iso8601)
        expect(token.reload).to be_revoked
      end
    end

    shared_examples 'rotating token denied' do |status|
      it 'cannot rotate token' do
        rotate_token

        expect(response).to have_gitlab_http_status(status)
      end
    end

    it 'passes creation_source api to the service' do
      expect(::PersonalAccessTokens::RotateService).to receive(:new)
        .with(anything, anything, anything, hash_including(creation_source: PersonalAccessToken::CREATION_SOURCE_API))
        .and_call_original

      rotate_token
    end

    context 'when the token is not granular' do
      it 'does not return granular_scopes or load any to present the new token', :aggregate_failures do
        recorder = ActiveRecord::QueryRecorder.new { rotate_token }

        expect(response).to have_gitlab_http_status(:ok)
        expect(json_response).not_to have_key('granular_scopes')
        # RotateService may ask of the token it rotates whether it has granular scopes to copy. Presenting
        # the new token adds no query about granular scopes.
        expect(recorder.log.grep(/"(personal_access_token_)?granular_scopes"/)).to all(
          start_with('SELECT 1 AS one FROM "granular_scopes"')
        )
      end
    end

    context 'when the token is granular' do
      let_it_be(:project) { create(:project) }

      let(:token) { granular_token_with_project_scopes([project]) }

      def granular_token_with_project_scopes(projects)
        create(:granular_pat, user: current_user, permissions: ['rotate_personal_access_token'],
          boundary: ::Authz::Boundary.for(::Authz::GranularScope::Access::USER),
          additional_scopes: projects.map do |project|
            { boundary: ::Authz::Boundary.for(project), permissions: ['read_job'] }
          end)
      end

      it 'returns the granular scopes of the new token with the project ID of a project scope', :aggregate_failures do
        rotate_token

        expect(response).to have_gitlab_http_status(:ok)
        expect(json_response['granular_scopes']).to contain_exactly(
          a_hash_including('access' => 'user', 'permissions' => ['rotate_personal_access_token'],
            'project_id' => nil, 'group_id' => nil),
          a_hash_including('access' => 'selected_memberships', 'permissions' => ['read_job'],
            'project_id' => project.id, 'group_id' => nil)
        )
      end

      context 'when presenting the granular scopes of the new token' do
        let_it_be(:other_project) { create(:project) }

        # RotateService writes a row for every scope it copies, so each token is rotated through it
        # before its request, and the request presents the new token as the service returned it. The
        # requests then differ only in the number of scopes they present.
        def rotate_through_service(projects)
          ::PersonalAccessTokens::RotateService.new(current_user, granular_token_with_project_scopes(projects))
            .execute
        end

        def post_presenting(service_response)
          allow_next_instance_of(::PersonalAccessTokens::RotateService) do |service|
            allow(service).to receive(:execute).and_return(service_response)
          end

          post(api(path, personal_access_token: token), params: params)
        end

        it 'avoids N+1 queries', :aggregate_failures do
          # Users::ActivityService's lease-gated write to last_activity_on would otherwise land on a random request.
          User.find(token.user_id).update_column(:last_activity_on, Date.current)

          # Every token is rotated before the first request stubs the service.
          warm_up = rotate_through_service([project])
          one_scope = rotate_through_service([project])
          two_scopes = rotate_through_service([project, other_project])

          post_presenting(warm_up)

          control = ActiveRecord::QueryRecorder.new(skip_cached: false) { post_presenting(one_scope) }

          expect { post_presenting(two_scopes) }.not_to exceed_all_query_limit(control)
          expect(json_response['granular_scopes'].pluck('project_id')).to contain_exactly(
            nil, project.id, other_project.id
          )
        end
      end
    end

    context 'when current_user is an administrator', :enable_admin_mode do
      let(:current_user) { create(:admin) }

      it_behaves_like 'rotating token succeeds'

      context 'when expiry is defined' do
        let(:expiry_date) { 1.month.from_now }
        let(:params) { { expires_at: expiry_date } }

        it_behaves_like 'rotating token succeeds'
      end

      context 'with impersonated token' do
        let(:token) { create(:personal_access_token, :impersonation, user: current_user) }

        it_behaves_like 'rotating token succeeds'
      end

      Gitlab::Auth.all_available_scopes.each do |scope|
        context "with a '#{scope}' scoped token" do
          let(:current_user) { create(:admin) }
          let(:token) { create(:personal_access_token, scopes: [scope], user: current_user) }

          if [Gitlab::Auth::API_SCOPE, Gitlab::Auth::SELF_ROTATE_SCOPE].include? scope
            it_behaves_like 'rotating token succeeds'
          else
            it_behaves_like 'rotating token denied', :forbidden
          end
        end
      end
    end

    context 'when current_user is not an administrator' do
      let(:current_user) { create(:user) }

      it_behaves_like 'rotating token succeeds'

      context 'when expiry is defined' do
        let(:expiry_date) { 1.month.from_now }
        let(:params) { { expires_at: expiry_date } }

        it_behaves_like 'rotating token succeeds'
      end

      context 'with impersonated token' do
        let(:token) { create(:personal_access_token, :impersonation, user: current_user) }

        it_behaves_like 'rotating token succeeds'
      end

      Gitlab::Auth.all_available_scopes.each do |scope|
        context "with a '#{scope}' scoped token" do
          let(:current_user) { create(:user) }
          let(:token) { create(:personal_access_token, scopes: [scope], user: current_user) }

          if [Gitlab::Auth::API_SCOPE, Gitlab::Auth::SELF_ROTATE_SCOPE].include? scope
            it_behaves_like 'rotating token succeeds'
          else
            it_behaves_like 'rotating token denied', :forbidden
          end
        end

        context "with '#{scope}' and 'self_rotate' scoped token" do
          let(:current_user) { create(:user) }
          let(:token) do
            create(:personal_access_token, scopes: [scope, Gitlab::Auth::SELF_ROTATE_SCOPE], user: current_user)
          end

          it_behaves_like 'rotating token succeeds'
        end
      end
    end

    context 'when token is invalid' do
      let(:current_user) { create(:user) }
      let(:token) { instance_double(PersonalAccessToken, token: 'invalidtoken') }

      it_behaves_like 'rotating token denied', :unauthorized
    end

    context 'with a revoked token' do
      let(:token) { create(:personal_access_token, :revoked, user: current_user) }

      it_behaves_like 'rotating token denied', :unauthorized
    end

    context 'with an expired token' do
      let(:token) { create(:personal_access_token, expires_at: 1.day.ago, user: current_user) }

      it_behaves_like 'rotating token denied', :unauthorized
    end

    context 'with a rotated token' do
      let(:token) { create(:personal_access_token, :revoked, user: current_user) }
      let!(:child_token) { create(:personal_access_token, previous_personal_access_token_id: token.id) }

      it_behaves_like 'rotating token denied', :unauthorized

      it 'revokes token family' do
        rotate_token

        expect(child_token.reload).to be_revoked
      end
    end

    context 'with an OAuth token' do
      subject(:rotate_token) { post(api(path, oauth_access_token: token), params: params) }

      context 'with default scope' do
        let(:token) { create(:oauth_access_token) }

        it_behaves_like 'rotating token denied', :forbidden
      end

      Gitlab::Auth.all_available_scopes.each do |scope|
        context "with a '#{scope}' scoped token" do
          let(:token) { create(:oauth_access_token, scopes: [scope]) }

          if [Gitlab::Auth::API_SCOPE, Gitlab::Auth::SELF_ROTATE_SCOPE].include? scope
            it_behaves_like 'rotating token denied', :method_not_allowed
          else
            it_behaves_like 'rotating token denied', :forbidden
          end
        end
      end
    end

    context 'with a deploy token' do
      let(:token) { create(:deploy_token) }
      let(:headers) { { Gitlab::Auth::AuthFinders::DEPLOY_TOKEN_HEADER => token.token } }

      subject(:rotate_token) { post(api(path), params: params, headers: headers) }

      it_behaves_like 'rotating token denied', :unauthorized
    end

    context 'with a job token' do
      let(:job) { create(:ci_build, :running, user: current_user) }

      subject(:rotate_token) { post(api(path, job_token: job.token), params: params) }

      it_behaves_like 'rotating token denied', :unauthorized
    end

    context 'when current_user is a project bot' do
      let(:current_user) { create(:user, :project_bot) }

      it_behaves_like 'rotating token succeeds'

      context 'when expiry is defined' do
        let(:expiry_date) { 1.month.from_now }
        let(:params) { { expires_at: expiry_date } }

        it_behaves_like 'rotating token succeeds'
      end

      context 'with impersonated token' do
        let(:token) { create(:personal_access_token, :impersonation, user: current_user) }

        it_behaves_like 'rotating token succeeds'
      end

      Gitlab::Auth.resource_bot_scopes.each do |scope|
        context "with a '#{scope}' scoped token" do
          let(:token) { create(:personal_access_token, scopes: [scope], user: current_user) }

          if [Gitlab::Auth::API_SCOPE, Gitlab::Auth::SELF_ROTATE_SCOPE].include? scope
            it_behaves_like 'rotating token succeeds'
          else
            it_behaves_like 'rotating token denied', :forbidden
          end
        end

        context "with '#{scope}' and 'self_rotate' scoped token" do
          let(:token) do
            create(:personal_access_token, scopes: [scope, Gitlab::Auth::SELF_ROTATE_SCOPE], user: current_user)
          end

          it_behaves_like 'rotating token succeeds'
        end
      end
    end
  end
end
