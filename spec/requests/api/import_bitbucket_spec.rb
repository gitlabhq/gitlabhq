# frozen_string_literal: true

require 'spec_helper'

RSpec.describe API::ImportBitbucket, :with_current_organization, feature_category: :importers do
  let_it_be(:user) { create(:user) }
  let_it_be(:project) { create(:project) }
  let(:params) do
    {
      bitbucket_username: 'foo',
      bitbucket_app_password: 'bar',
      repo_path: 'path/to/repo',
      target_namespace: user.namespace_path
    }
  end

  describe 'POST /import/bitbucket' do
    context 'when authenticated' do
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

    context 'when unauthenticated' do
      it 'returns api error' do
        post api('/import/bitbucket')

        expect(response).to have_gitlab_http_status(:unauthorized)
      end
    end
  end
end
