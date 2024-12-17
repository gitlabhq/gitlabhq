# frozen_string_literal: true

require 'spec_helper'

RSpec.describe ProjectAccessTokenEntity do
  let_it_be(:project) { create(:project) }
  let_it_be(:bot) { create(:user, :project_bot) }
  let_it_be(:token) { create(:personal_access_token, user: bot) }

  let(:expected_revoke_path) do
    Gitlab::Routing.url_helpers
      .revoke_namespace_project_settings_access_token_path(
        { id: token,
          namespace_id: project.namespace.full_path,
          project_id: project.path })
  end

  let(:expected_rotate_path) do
    Gitlab::Routing.url_helpers
      .rotate_namespace_project_settings_access_token_path(
        { id: token,
          namespace_id: project.namespace.full_path,
          project_id: project.path })
  end

  subject(:json) {  described_class.new(token, project: project).as_json }

  context 'when bot is a member of the project' do
    before do
      project.add_developer(bot)
    end

    it 'has the correct attributes' do
      expect(json).to(
        include(
          id: token.id,
          name: token.name,
          scopes: token.scopes,
          user_id: token.user_id,
          revoke_path: expected_revoke_path,
          rotate_path: expected_rotate_path,
          role: 'Developer'
        ))

      expect(json).not_to include(:token)
    end
  end

  context 'when bot is unrelated to the project' do
    let_it_be(:project) { create(:project) }

    it 'has the correct attributes' do
      expect(json).to(
        include(
          id: token.id,
          name: token.name,
          scopes: token.scopes,
          user_id: token.user_id,
          revoke_path: expected_revoke_path,
          rotate_path: expected_rotate_path,
          role: nil
        ))

      expect(json).not_to include(:token)
    end
  end
end
