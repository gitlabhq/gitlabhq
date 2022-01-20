# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Projects::Settings::AccessTokensController do
  let_it_be(:user) { create(:user) }
  let_it_be(:group) { create(:group) }
  let_it_be(:resource) { create(:project, group: group) }
  let_it_be(:bot_user) { create(:user, :project_bot) }

  before_all do
    resource.add_maintainer(user)
    resource.add_maintainer(bot_user)
  end

  before do
    sign_in(user)
  end

  shared_examples 'feature unavailable' do
    context 'user is not a maintainer' do
      before do
        resource.add_developer(user)
      end

      it { expect(subject).to have_gitlab_http_status(:not_found) }
    end
  end

  describe 'GET /:namespace/:project/-/settings/access_tokens' do
    subject do
      get project_settings_access_tokens_path(resource)
      response
    end

    it_behaves_like 'feature unavailable'
    it_behaves_like 'GET resource access tokens available'
  end

  describe 'POST /:namespace/:project/-/settings/access_tokens' do
    let(:access_token_params) { { name: 'Nerd bot', scopes: ["api"], expires_at: Date.today + 1.month } }

    subject do
      post project_settings_access_tokens_path(resource), params: { resource_access_token: access_token_params }
      response
    end

    it_behaves_like 'feature unavailable'
    it_behaves_like 'POST resource access tokens available'

    context 'when project access token creation is disabled' do
      before do
        group.namespace_settings.update_column(:resource_access_token_creation_allowed, false)
      end

      it { expect(subject).to have_gitlab_http_status(:not_found) }

      it 'does not create the token' do
        expect { subject }.not_to change { PersonalAccessToken.count }
      end

      it 'does not add the project bot as a member' do
        expect { subject }.not_to change { Member.count }
      end

      it 'does not create the project bot user' do
        expect { subject }.not_to change { User.count }
      end
    end

    context 'with custom access level' do
      let(:access_token_params) { { name: 'Nerd bot', scopes: ["api"], expires_at: Date.today + 1.month, access_level: 20 } }

      subject { post project_settings_access_tokens_path(resource), params: { resource_access_token: access_token_params } }

      it_behaves_like 'POST resource access tokens available'
    end
  end

  describe 'PUT /:namespace/:project/-/settings/access_tokens/:id', :sidekiq_inline do
    let(:resource_access_token) { create(:personal_access_token, user: bot_user) }

    subject do
      put revoke_project_settings_access_token_path(resource, resource_access_token)
      response
    end

    it_behaves_like 'feature unavailable'
    it_behaves_like 'PUT resource access tokens available'
  end
end
