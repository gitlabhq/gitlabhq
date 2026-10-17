# frozen_string_literal: true

# Specs for how the group and project service account APIs present the tokens they list.
#
# Requires:
#   let(:admin): an administrator, who lists the tokens
#   let(:service_account_user): the service account the tokens belong to
#   let(:base_path): the path of the service account's personal access tokens
#   let(:existing_token): a personal access token of service_account_user that is not granular
#   let(:project), let(:other_project): two projects a granular token can be scoped to
RSpec.shared_examples 'service account token list presenting granular scopes' do
  let_it_be(:admin_token) { create(:personal_access_token, :admin_mode, user: admin) }

  def list_tokens
    get api(base_path, personal_access_token: admin_token)
  end

  def listed(token)
    json_response.find { |listed_token| listed_token['id'] == token.id }
  end

  it 'does not return granular_scopes or load any when no token is granular' do
    recorder = ActiveRecord::QueryRecorder.new { list_tokens }

    expect(response).to have_gitlab_http_status(:ok)
    expect(listed(existing_token)).to be_present
    expect(listed(existing_token)).not_to have_key('granular_scopes')
    expect(recorder.log.grep(/"(personal_access_token_)?granular_scopes"/)).to be_empty
  end

  context 'when a token is granular' do
    let_it_be(:granular_token) do
      create(:granular_pat, user: service_account_user, permissions: ['read_job'],
        boundary: ::Authz::Boundary.for(project))
    end

    it 'returns the granular scopes of the granular token with the project ID of a project scope' do
      list_tokens

      expect(response).to have_gitlab_http_status(:ok)
      expect(listed(granular_token)['granular_scopes']).to contain_exactly(
        a_hash_including('access' => 'selected_memberships', 'permissions' => ['read_job'],
          'project_id' => project.id, 'group_id' => nil)
      )
      expect(listed(existing_token)).not_to have_key('granular_scopes')
    end

    it 'avoids N+1 queries' do
      # The lease-gated writes of Users::ActivityService to last_activity_on, and of
      # PersonalAccessTokens::LastUsedService to the token the requests share, would otherwise land on a
      # random request.
      User.find(admin.id).update_column(:last_activity_on, Date.current)
      PersonalAccessToken.find(admin_token.id).update_column(:last_used_at, Time.current)

      list_tokens

      control = ActiveRecord::QueryRecorder.new(skip_cached: false) { list_tokens }

      create(:granular_pat, user: service_account_user, permissions: ['read_job'],
        boundary: ::Authz::Boundary.for(other_project),
        additional_scopes: [{ boundary: ::Authz::Boundary.for(project), permissions: ['read_job'] }])

      expect { list_tokens }.not_to exceed_all_query_limit(control)
      expect(json_response.flat_map { |token| token['granular_scopes'].to_a }.pluck('project_id')).to contain_exactly(
        project.id, other_project.id, project.id
      )
    end
  end
end
