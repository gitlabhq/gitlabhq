# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Clusters::Agents::DashboardController, feature_category: :deployment_management do
  let(:user) { create(:user) }
  let(:stub_ff) { true }

  describe 'GET index' do
    before do
      allow(::Gitlab::Kas).to receive(:enabled?).and_return(true)
      stub_feature_flags(k8s_dashboard: stub_ff)
      sign_in(user)
      get kubernetes_dashboard_index_path
    end

    it 'returns ok and renders view' do
      expect(response).to have_gitlab_http_status(:ok)
    end

    context 'with k8s_dashboard feature flag disabled' do
      let(:stub_ff) { false }

      it 'returns not found' do
        expect(response).to have_gitlab_http_status(:not_found)
      end
    end
  end

  describe 'GET show' do
    let_it_be(:organization) { create(:group) }
    let_it_be(:agent_management_project) { create(:project, group: organization) }
    let_it_be(:agent) { create(:cluster_agent, project: agent_management_project) }
    let_it_be(:deployment_project) { create(:project, group: organization) }

    before do
      allow(::Gitlab::Kas).to receive(:enabled?).and_return(true)
    end

    context 'with authorized user' do
      let!(:authorization) do
        create(
          :agent_user_access_project_authorization,
          agent: agent,
          project: deployment_project
        )
      end

      before do
        stub_feature_flags(k8s_dashboard: stub_ff)
        deployment_project.add_member(user, :developer)
        sign_in(user)
        get kubernetes_dashboard_path(agent.id)
      end

      it 'sets the kas cookie' do
        expect(
          request.env['action_dispatch.cookies'][Gitlab::Kas::COOKIE_KEY]
        ).to be_present
      end

      it 'returns ok' do
        expect(response).to have_gitlab_http_status(:ok)
      end

      context 'with k8s_dashboard feature flag disabled' do
        let(:stub_ff) { false }

        it 'does not set the kas cookie' do
          expect(
            request.env['action_dispatch.cookies'][Gitlab::Kas::COOKIE_KEY]
          ).not_to be_present
        end

        it 'returns not found' do
          expect(response).to have_gitlab_http_status(:not_found)
        end
      end
    end

    context 'with unauthorized user' do
      before do
        sign_in(user)
        get kubernetes_dashboard_path(agent.id)
      end

      it 'does not set the kas cookie' do
        expect(
          request.env['action_dispatch.cookies'][Gitlab::Kas::COOKIE_KEY]
        ).not_to be_present
      end

      it 'returns not found' do
        expect(response).to have_gitlab_http_status(:not_found)
      end
    end
  end
end
