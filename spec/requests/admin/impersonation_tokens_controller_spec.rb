# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Admin::ImpersonationTokensController, :enable_admin_mode, feature_category: :system_access do
  let(:admin) { create(:admin, organizations: [build(:organization)]) }
  let!(:user) { create(:user) }

  before do
    sign_in(admin)
  end

  context 'when impersonation is enabled' do
    before do
      stub_config_setting(impersonation_enabled: true)
    end

    it 'responds ok' do
      get admin_user_impersonation_tokens_path(user_id: user.username)

      expect(response).to have_gitlab_http_status(:ok)
    end

    # Only makes sense while expose_last_used_ips_for_access_tokens is rolled out per-actor.
    # Delete this whole context when the flag is removed - there's no more requester-vs-token-owner
    # mismatch to guard against once everyone is on the same (unconditional) code path.
    context 'when the flag differs between the requester and the token owner' do
      let(:impersonation_tokens_path) { admin_user_impersonation_tokens_path(user_id: user.username) }

      it 'avoids N+1 queries when rendering last_used_ips' do
        # Enables the flag only for the token owner, not for the signed-in admin.
        stub_feature_flags(expose_last_used_ips_for_access_tokens: user)
        token = create(:personal_access_token, :impersonation, user: user)
        token.last_used_ips.create!(organization: token.organization, ip_address: '192.0.2.30')

        get impersonation_tokens_path # warm-up

        control = ActiveRecord::QueryRecorder.new(skip_cached: false) { get impersonation_tokens_path }

        extra_token = create(:personal_access_token, :impersonation, user: user)
        extra_token.last_used_ips.create!(organization: extra_token.organization, ip_address: '192.0.2.31')

        recorder = ActiveRecord::QueryRecorder.new(skip_cached: false) { get impersonation_tokens_path }

        expect(recorder.log.grep(/personal_access_token_last_used_ips/).size)
          .to eq(control.log.grep(/personal_access_token_last_used_ips/).size)
      end
    end
  end

  context 'when impersonation is disabled' do
    before do
      stub_config_setting(impersonation_enabled: false)
    end

    it 'shows error page for index page' do
      get admin_user_impersonation_tokens_path(user_id: user.username)

      expect(response).to have_gitlab_http_status(:not_found)
    end

    it 'responds with 404 for create action' do
      post admin_user_impersonation_tokens_path(user_id: user.username)

      expect(response).to have_gitlab_http_status(:not_found)
    end

    it 'responds with 404 for revoke action' do
      token = create(:personal_access_token, :impersonation, user: user)

      put revoke_admin_user_impersonation_token_path(user_id: user.username, id: token.id)

      expect(response).to have_gitlab_http_status(:not_found)
    end

    it 'responds with 404 for rotate action' do
      token = create(:personal_access_token, :impersonation, user: user)

      put rotate_admin_user_impersonation_token_path(user_id: user.username, id: token.id)

      expect(response).to have_gitlab_http_status(:not_found)
    end
  end

  describe '#create', :with_current_organization do
    # Replace to `it_behaves_like 'create access token'` once we migrate the legacy UI to use initSharedAccessTokenApp.
    it_behaves_like 'create access token - legacy' do
      let(:url) { admin_user_impersonation_tokens_path(user_id: user.username) }
      let(:token_attributes) { attributes_for(:personal_access_token, impersonation: true) }
    end
  end

  describe '#rotate', :with_current_organization do
    let(:token) { create(:personal_access_token, :impersonation, user: user) }

    it 'passes creation_source ui to the service' do
      expect(::PersonalAccessTokens::RotateService).to receive(:new)
        .with(admin, token, nil,
          hash_including(creation_source: PersonalAccessToken::CREATION_SOURCE_UI, keep_token_lifetime: true))
        .and_call_original

      put rotate_admin_user_impersonation_token_path(user_id: user.username, id: token.id)
    end
  end

  describe '#index', :with_current_organization do
    let(:dependency_proxy_enabled) { true }

    before do
      stub_config(dependency_proxy: { enabled: dependency_proxy_enabled })

      get admin_user_impersonation_tokens_path(user_id: user.username)
    end

    it 'sets available scopes' do
      expect(assigns(:scopes)).to include(::Gitlab::Auth::API_SCOPE)
    end

    it 'includes the virtual registry scopes' do
      expect(assigns(:scopes)).to include(
        ::Gitlab::Auth::READ_VIRTUAL_REGISTRY_SCOPE,
        ::Gitlab::Auth::WRITE_VIRTUAL_REGISTRY_SCOPE
      )
    end

    context 'with dependency proxy disabled' do
      let(:dependency_proxy_enabled) { false }

      it 'does not include the virtual registry scopes' do
        expect(assigns(:scopes)).not_to include(Gitlab::Auth::READ_VIRTUAL_REGISTRY_SCOPE)
        expect(assigns(:scopes)).not_to include(Gitlab::Auth::WRITE_VIRTUAL_REGISTRY_SCOPE)
      end
    end
  end
end
