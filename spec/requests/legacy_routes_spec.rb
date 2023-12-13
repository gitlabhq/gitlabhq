# frozen_string_literal: true

require 'spec_helper'

RSpec.describe "Legacy routes", type: :request, feature_category: :system_access do
  let(:user) { create(:user) }

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

  it "/-/profile/applications" do
    get "/-/profile/applications"
    expect(response).to redirect_to('/-/user_settings/applications')
  end
end
