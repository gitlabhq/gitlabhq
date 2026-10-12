# frozen_string_literal: true

# Specs for how the group and project service account APIs present the token they rotate.
#
# Requires:
#   let(:admin): an administrator, who rotates the tokens
#   let(:service_account_user): the service account the tokens belong to
#   let(:base_path): the path of the service account's personal access tokens
#   let(:token): a personal access token of service_account_user that is not granular
#   let(:project), let(:other_project): two projects a granular token can be scoped to
RSpec.shared_examples 'service account token rotation presenting granular scopes' do
  it 'does not return granular_scopes or load any when the token is not granular' do
    url = api("#{base_path}/#{token.id}/rotate", admin, admin_mode: true)

    recorder = ActiveRecord::QueryRecorder.new { post url }

    expect(response).to have_gitlab_http_status(:ok)
    expect(json_response).not_to have_key('granular_scopes')
    # RotateService may ask of the token it rotates whether it has granular scopes to copy. Presenting
    # the new token adds no query about granular scopes.
    expect(recorder.log.grep(/"(personal_access_token_)?granular_scopes"/)).to all(
      start_with('SELECT 1 AS one FROM "granular_scopes"')
    )
  end

  context 'when the token is granular' do
    let_it_be(:granular_token) do
      create(:granular_pat, user: service_account_user, permissions: ['read_job'],
        boundary: ::Authz::Boundary.for(project))
    end

    it 'returns the granular scopes of the new token with the project ID of a project scope' do
      post api("#{base_path}/#{granular_token.id}/rotate", admin, admin_mode: true)

      expect(response).to have_gitlab_http_status(:ok)
      expect(json_response['granular_scopes']).to contain_exactly(
        a_hash_including('access' => 'selected_memberships', 'permissions' => ['read_job'],
          'project_id' => project.id, 'group_id' => nil)
      )
    end

    context 'when presenting the granular scopes of the new token' do
      let_it_be(:admin_token) { create(:personal_access_token, :admin_mode, user: admin) }

      # RotateService writes a row for every scope it copies, so each token is rotated through it
      # before its request, and the request presents the new token as the service returned it. The
      # requests then differ only in the number of scopes they present.
      def rotate_through_service(projects)
        old_token = create(:granular_pat, user: service_account_user, permissions: ['read_job'],
          boundary: ::Authz::Boundary.for(projects.first),
          additional_scopes: projects.drop(1).map do |additional_project|
            { boundary: ::Authz::Boundary.for(additional_project), permissions: ['read_job'] }
          end)

        ::PersonalAccessTokens::RotateService.new(admin, old_token).execute
      end

      def post_presenting(service_response)
        allow_next_instance_of(::PersonalAccessTokens::RotateService) do |service|
          allow(service).to receive(:execute).and_return(service_response)
        end

        post api("#{base_path}/#{granular_token.id}/rotate", personal_access_token: admin_token)
      end

      it 'avoids N+1 queries' do
        # The lease-gated writes of Users::ActivityService to last_activity_on, and of
        # PersonalAccessTokens::LastUsedService to the token the requests share, would otherwise land on a
        # random request.
        User.find(admin.id).update_column(:last_activity_on, Date.current)
        PersonalAccessToken.find(admin_token.id).update_column(:last_used_at, Time.current)

        # Every token is rotated before the first request stubs the service.
        warm_up = rotate_through_service([project])
        one_scope = rotate_through_service([project])
        two_scopes = rotate_through_service([project, other_project])

        post_presenting(warm_up)

        control = ActiveRecord::QueryRecorder.new(skip_cached: false) { post_presenting(one_scope) }

        expect { post_presenting(two_scopes) }.not_to exceed_all_query_limit(control)
        expect(json_response['granular_scopes'].pluck('project_id')).to contain_exactly(
          project.id, other_project.id
        )
      end
    end
  end
end
