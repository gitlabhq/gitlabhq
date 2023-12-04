# frozen_string_literal: true

require 'spec_helper'

RSpec.describe "UserSettings", type: :request, feature_category: :system_access do
  let(:user) { create(:user) }

  describe 'GET authentication_log' do
    let(:auth_event) { create(:authentication_event, user: user) }

    it 'tracks search event', :snowplow do
      sign_in(user)

      get '/-/user_settings/authentication_log'

      expect_snowplow_event(
        category: 'UserSettings::UserSettingsController',
        action: 'search_audit_event',
        user: user
      )
    end

    it 'loads page correctly' do
      sign_in(user)

      get '/-/user_settings/authentication_log'

      expect(response).to have_gitlab_http_status(:success)
    end
  end
end
