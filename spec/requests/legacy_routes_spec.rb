# frozen_string_literal: true

require 'spec_helper'

RSpec.describe "Legacy routes", type: :request, feature_category: :system_access do
  let(:user) { create(:user) }
  let(:token) { create(:personal_access_token, user: user) }

  before do
    login_as(user)
  end

  it "/-/profile/audit_log" do
    get "/-/profile/audit_log"
    expect(response).to redirect_to('/-/user_settings/authentication_log')
  end

  it "/-/profile/active_sessions" do
    get "/-/profile/active_sessions"
    expect(response).to redirect_to('/-/user_settings/active_sessions')
  end

  it "/-/profile/personal_access_tokens" do
    get "/-/profile/personal_access_tokens"
    expect(response).to redirect_to('/-/user_settings/personal_access_tokens')

    get "/-/profile/personal_access_tokens?name=GitLab+Dangerbot&scopes=api"
    expect(response).to redirect_to('/-/user_settings/personal_access_tokens?name=GitLab+Dangerbot&scopes=api')
  end

  it "/-/profile/personal_access_tokens/:id/revoke" do
    put "/-/profile/personal_access_tokens/#{token.id}/revoke"
    expect(token.reload).to be_revoked
  end

  it "/-/profile/applications" do
    get "/-/profile/applications"
    expect(response).to redirect_to('/-/user_settings/applications')
  end

  it "/-/profile/password/new" do
    get "/-/profile/password/new"
    expect(response).to redirect_to('/-/user_settings/password/new')

    get "/-/profile/password/new?abc=xyz"
    expect(response).to redirect_to('/-/user_settings/password/new?abc=xyz')
  end

  it "/-/profile/password/edit" do
    get "/-/profile/password/edit"
    expect(response).to redirect_to('/-/user_settings/password/edit')

    get "/-/profile/password/edit?abc=xyz"
    expect(response).to redirect_to('/-/user_settings/password/edit?abc=xyz')
  end
end
