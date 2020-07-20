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

        expect(json_response['project_id']).to eq(project.id)
        expect(json_response['agent_id']).to eq(agent.id)
        expect(json_response['agent_name']).to eq(agent.name)
        expect(json_response['storage_name']).to eq(project.repository_storage)
        expect(json_response['relative_path']).to eq(project.disk_path + '.git')
        expect(json_response['gl_repository']).to eq("project-#{project.id}")
        expect(json_response['gl_project_path']).to eq(project.full_path)
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

          expect(json_response['project_id']).to eq(project.id)
          expect(json_response['storage_name']).to eq(project.repository_storage)
          expect(json_response['relative_path']).to eq(project.disk_path + '.git')
          expect(json_response['gl_repository']).to eq("project-#{project.id}")
          expect(json_response['gl_project_path']).to eq(project.full_path)
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
          get api('/internal/kubernetes/project_info'), params: { id: 0 }, headers: { 'Authorization' => "Bearer #{agent_token.token}" }

          expect(response).to have_gitlab_http_status(:not_found)
        end
      end
    end
  end
end
