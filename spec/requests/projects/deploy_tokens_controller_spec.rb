# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Projects::DeployTokensController, feature_category: :continuous_delivery do
  let_it_be(:user) { create(:user) }
  let_it_be(:project) { create(:project, maintainers: user) }
  let_it_be_with_reload(:deploy_token) { create(:deploy_token, projects: [project]) }

  before do
    sign_in(user)
  end

  describe 'PUT /:namespace/:project/-/deploy_tokens/:id/revoke' do
    subject(:put_revoke) do
      put revoke_project_deploy_token_path(project, deploy_token)
    end

    it 'revokes the deploy token named by the id param' do
      expect { put_revoke }.to change { deploy_token.reload.revoked? }.from(false).to(true)

      expect(response).to redirect_to(
        project_settings_repository_path(project, anchor: 'js-deploy-tokens')
      )
    end

    context 'when the deploy token belongs to another project' do
      let_it_be(:deploy_token) { create(:deploy_token, projects: [create(:project)]) }

      it 'responds with not found' do
        put_revoke

        expect(response).to have_gitlab_http_status(:not_found)
      end
    end
  end
end
