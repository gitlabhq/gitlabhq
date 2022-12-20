# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Groups::DeployTokensController, feature_category: :continuous_delivery do
  let_it_be(:group) { create(:group) }
  let_it_be(:user) { create(:user) }
  let_it_be(:deploy_token) { create(:deploy_token, :group, groups: [group]) }
  let_it_be(:params) do
    { id: deploy_token.id, group_id: group }
  end

  before do
    group.add_owner(user)

    sign_in(user)
  end

  describe 'PUT /groups/:group_path_with_namespace/-/deploy_tokens/:id/revoke' do
    subject(:put_revoke) do
      put "/groups/#{group.full_path}/-/deploy_tokens/#{deploy_token.id}/revoke", params: params
    end

    it 'invokes the Groups::DeployTokens::RevokeService' do
      expect(deploy_token.revoked).to eq(false)
      expect(Groups::DeployTokens::RevokeService).to receive(:new).and_call_original

      put_revoke

      expect(deploy_token.reload.revoked).to eq(true)
    end

    it 'redirects to group repository settings with correct anchor' do
      put_revoke

      expect(response).to have_gitlab_http_status(:redirect)
      expect(response).to redirect_to(group_settings_repository_path(group, anchor: 'js-deploy-tokens'))
    end
  end
end
