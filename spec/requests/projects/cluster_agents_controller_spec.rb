# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Projects::ClusterAgentsController, feature_category: :deployment_management do
  let_it_be(:cluster_agent) { create(:cluster_agent) }

  let(:project) { cluster_agent.project }

  describe 'GET #show' do
    subject { get project_cluster_agent_path(project, cluster_agent.name) }

    context 'when user is unauthorized' do
      let_it_be(:user) { create(:user) }

      before do
        project.add_reporter(user)
        sign_in(user)
        subject
      end

      it 'shows 404' do
        expect(response).to have_gitlab_http_status(:not_found)
      end
    end

    context 'when user is authorized' do
      let(:user) { project.creator }

      before do
        sign_in(user)
        subject
      end

      it 'renders content' do
        expect(response).to be_successful
      end
    end
  end
end
