# frozen_string_literal: true

require 'spec_helper'

RSpec.describe API::ImportBitbucket, :with_current_organization, feature_category: :importers do
  let_it_be(:user) { create(:user) }
  let_it_be(:project) { create(:project) }

  describe 'POST /import/bitbucket' do
    it_behaves_like 'authorizing granular token permissions', :create_bitbucket_import do
      before do
        allow_next_instance_of(Import::BitbucketService) do |service|
          allow(service).to receive(:execute).and_return(status: :success, project: project)
        end
      end

      let_it_be(:group) { create(:group, developers: [user]) }
      let_it_be(:params) do
        {
          bitbucket_email: 'user@example.com',
          bitbucket_api_token: 'token123',
          repo_path: 'path/to/repo',
          target_namespace: group.full_path
        }
      end

      let(:boundary_object) { group }
      let(:request) do
        post api('/import/bitbucket', personal_access_token: pat), params: params
      end
    end

    it_behaves_like 'authorizing granular token permissions', :create_bitbucket_import do
      before do
        allow_next_instance_of(Import::BitbucketService) do |service|
          allow(service).to receive(:execute).and_return(status: :success, project: project)
        end
      end

      let_it_be(:user) { create(:user, :with_namespace) }
      let_it_be(:params) do
        {
          bitbucket_email: 'user@example.com',
          bitbucket_api_token: 'token123',
          repo_path: 'path/to/repo',
          target_namespace: user.namespace_path
        }
      end

      let(:boundary_object) { :user }
      let(:request) do
        post api('/import/bitbucket', personal_access_token: pat), params: params
      end
    end

    context 'when a granular token scoped only to the user boundary targets a group namespace' do
      let_it_be(:group) { create(:group, developers: [user]) }
      let(:user_boundary_pat) do
        create(:granular_pat, user: user, boundary: ::Authz::Boundary.for(:user),
          permissions: [::Authz::PermissionGroups::Assignable.for_permission(:create_bitbucket_import).first.name])
      end

      it 'denies the cross-boundary import', :aggregate_failures do
        post api('/import/bitbucket', personal_access_token: user_boundary_pat), params: {
          bitbucket_email: 'user@example.com',
          bitbucket_api_token: 'token123',
          repo_path: 'path/to/repo',
          target_namespace: group.full_path
        }

        expect(response).to have_gitlab_http_status(:forbidden)
        expect(json_response['error']).to eq('insufficient_granular_scope')
      end
    end

    context 'when a granular token targets a non-existent namespace path' do
      let(:user_boundary_pat) do
        create(:granular_pat, user: user, boundary: ::Authz::Boundary.for(:user),
          permissions: [::Authz::PermissionGroups::Assignable.for_permission(:create_bitbucket_import).first.name])
      end

      it 'returns not found instead of falling back to the user boundary' do
        expect(Import::BitbucketService).not_to receive(:new)

        post api('/import/bitbucket', personal_access_token: user_boundary_pat), params: {
          bitbucket_email: 'user@example.com',
          bitbucket_api_token: 'token123',
          repo_path: 'path/to/repo',
          target_namespace: 'this-namespace-does-not-exist'
        }

        expect(response).to have_gitlab_http_status(:not_found)
      end
    end

    shared_examples 'bitbucket import endpoint' do
      before do
        allow_next_instance_of(Import::BitbucketService) do |service|
          allow(service).to receive(:execute).and_return(
            status: :success,
            project: project
          )
        end
      end

      it 'calls Import::BitbucketService with correct params' do
        expect(Import::BitbucketService).to receive(:new).with(user, hash_including(params))

        post api('/import/bitbucket', user), params: params
      end

      context 'when successful' do
        it 'returns project entity response' do
          post api('/import/bitbucket', user), params: params

          expect(response).to have_gitlab_http_status(:created)
          expect(json_response['name']).to eq(project.name)
        end
      end

      context 'when unsuccessful' do
        it 'returns api error' do
          allow_next_instance_of(Import::BitbucketService) do |service|
            allow(service).to receive(:execute).and_return(
              status: :error,
              http_status: :unprocessable_entity,
              message: 'Error!'
            )
          end

          post api('/import/bitbucket', user), params: params

          expect(response).to have_gitlab_http_status(:unprocessable_entity)
          expect(json_response['message']['error']).to eq('Error!')
        end
      end
    end

    context 'when authenticated' do
      let(:params) do
        {
          bitbucket_email: 'user@example.com',
          bitbucket_api_token: 'token123',
          repo_path: 'path/to/repo',
          target_namespace: user.namespace_path
        }
      end

      it_behaves_like 'bitbucket import endpoint'

      context 'when missing required credentials' do
        it 'returns validation error' do
          post api('/import/bitbucket', user), params: {
            repo_path: 'path/to/repo',
            target_namespace: user.namespace_path
          }

          expect(response).to have_gitlab_http_status(:bad_request)
          expect(response.body).to include('bitbucket_email is missing')
        end
      end
    end

    context 'when unauthenticated' do
      it 'returns api error' do
        post api('/import/bitbucket')

        expect(response).to have_gitlab_http_status(:unauthorized)
      end
    end
  end
end
