# frozen_string_literal: true

require 'spec_helper'

RSpec.describe API::Keys do
  let(:user)  { create(:user) }
  let(:admin) { create(:admin) }
  let(:key)   { create(:key, user: user, expires_at: 1.day.from_now) }
  let(:email) { create(:email, user: user) }

  describe 'GET /keys/:uid' do
    context 'when unauthenticated' do
      it 'returns authentication error' do
        get api("/keys/#{key.id}")
        expect(response).to have_gitlab_http_status(:unauthorized)
      end
    end

    context 'when authenticated' do
      it 'returns 404 for non-existing key' do
        get api('/keys/0', admin)
        expect(response).to have_gitlab_http_status(:not_found)
        expect(json_response['message']).to eq('404 Not found')
      end

      it 'returns single ssh key with user information' do
        user.keys << key
        get api("/keys/#{key.id}", admin)
        expect(response).to have_gitlab_http_status(:ok)
        expect(json_response['title']).to eq(key.title)
        expect(Time.parse(json_response['expires_at'])).to be_like_time(key.expires_at)
        expect(json_response['user']['id']).to eq(user.id)
        expect(json_response['user']['username']).to eq(user.username)
      end

      it "does not include the user's `is_admin` flag" do
        get api("/keys/#{key.id}", admin)

        expect(json_response['user']['is_admin']).to be_nil
      end
    end
  end

  describe 'GET /keys?fingerprint=' do
    it 'returns authentication error' do
      get api("/keys?fingerprint=#{key.fingerprint}")

      expect(response).to have_gitlab_http_status(:unauthorized)
    end

    it 'returns authentication error when authenticated as user' do
      get api("/keys?fingerprint=#{key.fingerprint}", user)

      expect(response).to have_gitlab_http_status(:forbidden)
    end

    context 'when authenticated as admin' do
      it 'returns 404 for non-existing SSH md5 fingerprint' do
        get api("/keys?fingerprint=11:11:11:11:11:11:11:11:11:11:11:11:11:11:11:11", admin)

        expect(response).to have_gitlab_http_status(:not_found)
        expect(json_response['message']).to eq('404 Key Not Found')
      end

      it 'returns 404 for non-existing SSH sha256 fingerprint' do
        get api("/keys?fingerprint=#{URI.encode_www_form_component("SHA256:nUhzNyftwADy8AH3wFY31tAKs7HufskYTte2aXo1lCg")}", admin)

        expect(response).to have_gitlab_http_status(:not_found)
        expect(json_response['message']).to eq('404 Key Not Found')
      end

      it 'returns user if SSH md5 fingerprint found' do
        user.keys << key

        get api("/keys?fingerprint=#{key.fingerprint}", admin)

        expect(response).to have_gitlab_http_status(:ok)
        expect(json_response['title']).to eq(key.title)
        expect(json_response['user']['id']).to eq(user.id)
        expect(json_response['user']['username']).to eq(user.username)
      end

      it 'returns user if SSH sha256 fingerprint found' do
        user.keys << key

        get api("/keys?fingerprint=#{URI.encode_www_form_component("SHA256:" + key.fingerprint_sha256)}", admin)

        expect(response).to have_gitlab_http_status(:ok)
        expect(json_response['title']).to eq(key.title)
        expect(json_response['user']['id']).to eq(user.id)
        expect(json_response['user']['username']).to eq(user.username)
      end

      it 'returns user if SSH sha256 fingerprint found' do
        user.keys << key

        get api("/keys?fingerprint=#{URI.encode_www_form_component("sha256:" + key.fingerprint_sha256)}", admin)

        expect(response).to have_gitlab_http_status(:ok)
        expect(json_response['title']).to eq(key.title)
        expect(json_response['user']['id']).to eq(user.id)
        expect(json_response['user']['username']).to eq(user.username)
      end

      it "does not include the user's `is_admin` flag" do
        get api("/keys?fingerprint=#{key.fingerprint}", admin)

        expect(json_response['user']['is_admin']).to be_nil
      end

      context 'when searching a DeployKey' do
        let(:project) { create(:project, :repository) }
        let(:project_push) { create(:project, :repository) }
        let(:deploy_key) { create(:deploy_key) }

        let!(:deploy_keys_project) do
          create(:deploy_keys_project, project: project, deploy_key: deploy_key)
        end

        let!(:deploy_keys_project_push) do
          create(:deploy_keys_project, project: project_push, deploy_key: deploy_key, can_push: true)
        end

        it 'returns user and projects if SSH sha256 fingerprint for DeployKey found' do
          user.keys << deploy_key

          get api("/keys?fingerprint=#{URI.encode_www_form_component("SHA256:" + deploy_key.fingerprint_sha256)}", admin)

          expect(response).to have_gitlab_http_status(:ok)
          expect(json_response['title']).to eq(deploy_key.title)
          expect(json_response['user']['id']).to eq(user.id)

          expect(json_response['deploy_keys_projects'].count).to eq(2)
          expect(json_response['deploy_keys_projects'][0]['project_id']).to eq(deploy_keys_project.project.id)
          expect(json_response['deploy_keys_projects'][0]['can_push']).to eq(deploy_keys_project.can_push)
          expect(json_response['deploy_keys_projects'][1]['project_id']).to eq(deploy_keys_project_push.project.id)
          expect(json_response['deploy_keys_projects'][1]['can_push']).to eq(deploy_keys_project_push.can_push)
        end
      end
    end
  end
end
