# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Granular OAuth token authorization', feature_category: :permissions do
  include GraphqlHelpers

  let_it_be(:user) { create(:user) }
  let_it_be(:group) { create(:group) }
  let_it_be_with_reload(:project) { create(:project, :private, group: group, developers: user) }
  let_it_be(:application) { create(:oauth_application) }

  let(:token) { create(:oauth_access_token, :granular, resource_owner: user, application: application) }

  def grant_consent(permissions, boundary: project)
    create(:oauth_consent_grant, user: user, application: application,
      boundary: ::Authz::Boundary.for(boundary), permissions: permissions)
  end

  def enforce_granular_tokens
    stub_feature_flags(granular_personal_access_tokens_enforcement_saas: group)
    ::NamespaceSetting.find_by!(namespace_id: group.id).update!(
      enforce_granular_tokens: true,
      granular_tokens_enforced_after: Date.current
    )
  end

  describe 'REST API' do
    let_it_be(:release) { create(:release, project: project) }

    subject(:request) { get api("/projects/#{project.id}/releases", oauth_access_token: token) }

    shared_examples 'denying access' do
      it 'denies access', :aggregate_failures do
        request

        expect(response).to have_gitlab_http_status(:forbidden)
        expect(json_response['error']).to eq('insufficient_granular_scope')
        expect(json_response['error_description']).to include(
          'This operation requires a fine-grained oauth access token with the following project permissions: ' \
            '[Release: Read].'
        )
      end
    end

    context 'when the consent grant carries the permission' do
      before do
        grant_consent(:read_release)
      end

      it 'grants access', :aggregate_failures do
        request

        expect(response).to have_gitlab_http_status(:ok)
        expect(json_response.pluck('tag_name')).to contain_exactly(release.tag)
      end
    end

    context 'when the consent grant is missing the permission' do
      before do
        grant_consent(:read_code)
      end

      it_behaves_like 'denying access'
    end

    context 'when the consent grant covers another project' do
      let_it_be(:other_project) { create(:project, :private, developers: user) }

      before do
        grant_consent(:read_release, boundary: other_project)
      end

      it_behaves_like 'denying access'
    end

    context 'when the consent grant is revoked' do
      before do
        grant_consent(:read_release).revoked!
      end

      it_behaves_like 'denying access'
    end

    context 'with a legacy OAuth token' do
      let(:token) { create(:oauth_access_token, resource_owner: user, application: application, scopes: ['api']) }

      it 'grants access' do
        request

        expect(response).to have_gitlab_http_status(:ok)
      end

      context 'when granular tokens are enforced for the namespace' do
        before do
          enforce_granular_tokens
        end

        it 'grants access' do
          request

          expect(response).to have_gitlab_http_status(:ok)
        end

        it 'denies a legacy personal access token' do
          get api("/projects/#{project.id}/releases", personal_access_token: create(:personal_access_token, user: user))

          expect(response).to have_gitlab_http_status(:forbidden)
        end
      end
    end
  end

  describe 'GraphQL API' do
    let(:query) { graphql_query_for(:project, { full_path: project.full_path }, 'name') }

    subject(:request) { post_graphql(query, token: { oauth_access_token: token }) }

    context 'when the consent grant carries the permission' do
      before do
        grant_consent(:read_project)
      end

      it 'returns the project', :aggregate_failures do
        request

        expect_graphql_errors_to_be_empty
        expect(graphql_data_at(:project, :name)).to eq(project.name)
      end
    end

    context 'when the consent grant is missing the permission' do
      before do
        grant_consent(:read_release)
      end

      it 'does not return the project' do
        request

        expect(graphql_data_at(:project)).to be_nil
      end
    end

    context 'with a legacy OAuth token' do
      let(:token) { create(:oauth_access_token, resource_owner: user, application: application, scopes: ['api']) }

      it 'returns the project' do
        request

        expect(graphql_data_at(:project, :name)).to eq(project.name)
      end

      context 'when granular tokens are enforced for the namespace' do
        before do
          enforce_granular_tokens
        end

        it 'returns the project' do
          request

          expect(graphql_data_at(:project, :name)).to eq(project.name)
        end

        it 'does not return the project for a legacy personal access token' do
          post_graphql(query, token: { personal_access_token: create(:personal_access_token, user: user) })

          expect(graphql_data_at(:project)).to be_nil
        end
      end
    end
  end
end
