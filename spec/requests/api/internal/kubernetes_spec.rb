# frozen_string_literal: true

require 'spec_helper'

RSpec.describe API::Internal::Kubernetes do
  describe "GET /internal/kubernetes/agent_info" do
    context 'kubernetes_agent_internal_api feature flag disabled' do
      before do
        stub_feature_flags(kubernetes_agent_internal_api: false)
      end

      it 'returns 404' do
        get api('/internal/kubernetes/agent_info')

        expect(response).to have_gitlab_http_status(:not_found)
      end
    end

    it 'returns 403 if Authorization header not sent' do
      get api('/internal/kubernetes/agent_info')

      expect(response).to have_gitlab_http_status(:forbidden)
    end

    context 'an agent is found' do
      let!(:agent_token) { create(:cluster_agent_token) }

      let(:agent) { agent_token.agent }
      let(:project) { agent.project }

      it 'returns expected data', :aggregate_failures do
        get api('/internal/kubernetes/agent_info'), headers: { 'Authorization' => "Bearer #{agent_token.token}" }

        expect(response).to have_gitlab_http_status(:success)

        expect(json_response).to match(
          a_hash_including(
            'project_id' => project.id,
            'agent_id' => agent.id,
            'agent_name' => agent.name,
            'gitaly_info' => a_hash_including(
              'address' => match(/\.socket$/),
              'token' => 'secret',
              'features' => {}
            ),
            'gitaly_repository' => a_hash_including(
              'storage_name' => project.repository_storage,
              'relative_path' => project.disk_path + '.git',
              'gl_repository' => "project-#{project.id}",
              'gl_project_path' => project.full_path
            )
          )
        )
      end
    end

    context 'no such agent exists' do
      it 'returns 404' do
        get api('/internal/kubernetes/agent_info'), headers: { 'Authorization' => 'Bearer ABCD' }

        expect(response).to have_gitlab_http_status(:forbidden)
      end
    end
  end

  describe 'GET /internal/kubernetes/project_info' do
    context 'kubernetes_agent_internal_api feature flag disabled' do
      before do
        stub_feature_flags(kubernetes_agent_internal_api: false)
      end

      it 'returns 404' do
        get api('/internal/kubernetes/project_info')

        expect(response).to have_gitlab_http_status(:not_found)
      end
    end

    it 'returns 403 if Authorization header not sent' do
      get api('/internal/kubernetes/project_info')

      expect(response).to have_gitlab_http_status(:forbidden)
    end

    context 'no such agent exists' do
      it 'returns 404' do
        get api('/internal/kubernetes/project_info'), headers: { 'Authorization' => 'Bearer ABCD' }

        expect(response).to have_gitlab_http_status(:forbidden)
      end
    end

    context 'an agent is found' do
      let!(:agent_token) { create(:cluster_agent_token) }

      let(:agent) { agent_token.agent }

      context 'project is public' do
        let(:project) { create(:project, :public) }

        it 'returns expected data', :aggregate_failures do
          get api('/internal/kubernetes/project_info'), params: { id: project.id }, headers: { 'Authorization' => "Bearer #{agent_token.token}" }

          expect(response).to have_gitlab_http_status(:success)

          expect(json_response).to match(
            a_hash_including(
              'project_id' => project.id,
              'gitaly_info' => a_hash_including(
                'address' => match(/\.socket$/),
                'token' => 'secret',
                'features' => {}
              ),
              'gitaly_repository' => a_hash_including(
                'storage_name' => project.repository_storage,
                'relative_path' => project.disk_path + '.git',
                'gl_repository' => "project-#{project.id}",
                'gl_project_path' => project.full_path
              )
            )
          )
        end

        context 'repository is for project members only' do
          let(:project) { create(:project, :public, :repository_private) }

          it 'returns 404' do
            get api('/internal/kubernetes/project_info'), params: { id: project.id }, headers: { 'Authorization' => "Bearer #{agent_token.token}" }

            expect(response).to have_gitlab_http_status(:not_found)
          end
        end
      end

      context 'project is private' do
        let(:project) { create(:project, :private) }

        it 'returns 404' do
          get api('/internal/kubernetes/project_info'), params: { id: project.id }, headers: { 'Authorization' => "Bearer #{agent_token.token}" }

          expect(response).to have_gitlab_http_status(:not_found)
        end
      end

      context 'project is internal' do
        let(:project) { create(:project, :internal) }

        it 'returns 404' do
          get api('/internal/kubernetes/project_info'), params: { id: project.id }, headers: { 'Authorization' => "Bearer #{agent_token.token}" }

          expect(response).to have_gitlab_http_status(:not_found)
        end
      end

      context 'project does not exist' do
        it 'returns 404' do
          get api('/internal/kubernetes/project_info'), params: { id: non_existing_record_id }, headers: { 'Authorization' => "Bearer #{agent_token.token}" }

          expect(response).to have_gitlab_http_status(:not_found)
        end
      end
    end
  end
end
