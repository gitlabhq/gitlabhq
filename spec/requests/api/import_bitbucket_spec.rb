# frozen_string_literal: true

require 'spec_helper'

RSpec.describe API::ImportBitbucket, feature_category: :importers do
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
          bitbucket_username: 'foo',
          bitbucket_app_password: 'bar',
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

      let_it_be(:params) do
        {
          bitbucket_username: 'foo',
          bitbucket_app_password: 'bar',
          repo_path: 'path/to/repo',
          target_namespace: user.namespace_path
        }
      end

      let(:boundary_object) { :user }
      let(:request) do
        post api('/import/bitbucket', personal_access_token: pat), params: params
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
      context 'when using app password authentication' do
        let(:params) do
          {
            bitbucket_username: 'foo',
            bitbucket_app_password: 'bar',
            repo_path: 'path/to/repo',
            target_namespace: user.namespace_path
          }
        end

        it_behaves_like 'bitbucket import endpoint'
      end

      context 'when using API token authentication' do
        let(:params) do
          {
            bitbucket_email: 'user@example.com',
            bitbucket_api_token: 'token123',
            repo_path: 'path/to/repo',
            target_namespace: user.namespace_path
          }
        end

        it_behaves_like 'bitbucket import endpoint'
      end

      context 'when both app password and API token provided' do
        let(:both_params) do
          {
            bitbucket_username: 'username',
            bitbucket_app_password: 'app_pass',
            bitbucket_email: 'user@example.com',
            bitbucket_api_token: 'token123',
            repo_path: 'path/to/repo',
            target_namespace: user.namespace_path
          }
        end

        it 'returns validation error' do
          post api('/import/bitbucket', user), params: both_params

          expect(response).to have_gitlab_http_status(:bad_request)
          expect(response.body).to include('are mutually exclusive')
        end
      end

      context 'when partial app password credentials provided' do
        let(:partial_app_pass_params) do
          {
            bitbucket_username: 'username',
            repo_path: 'path/to/repo',
            target_namespace: user.namespace_path
          }
        end

        it 'returns validation error' do
          post api('/import/bitbucket', user), params: partial_app_pass_params

          expect(response).to have_gitlab_http_status(:bad_request)
          expect(response.body)
            .to include('bitbucket_username, bitbucket_app_password provide all or none of parameters')
        end
      end

      context 'when partial API token credentials provided' do
        let(:partial_api_token_params) do
          {
            bitbucket_email: 'user@example.com',
            repo_path: 'path/to/repo',
            target_namespace: user.namespace_path
          }
        end

        it 'returns validation error' do
          post api('/import/bitbucket', user), params: partial_api_token_params

          expect(response).to have_gitlab_http_status(:bad_request)
          expect(response.body).to include('bitbucket_email, bitbucket_api_token provide all or none of parameters')
        end
      end

      context 'when neither authentication method provided' do
        let(:no_auth_params) do
          {
            repo_path: 'path/to/repo',
            target_namespace: user.namespace_path
          }
        end

        it 'returns validation error' do
          post api('/import/bitbucket', user), params: no_auth_params

          expect(response).to have_gitlab_http_status(:bad_request)
          expect(response.body).to include('at least one parameter must be provided')
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
