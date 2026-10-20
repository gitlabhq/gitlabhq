# frozen_string_literal: true

require 'spec_helper'

RSpec.describe UserSettings::ActiveSessionsController, feature_category: :user_profile do
  describe 'DELETE destroy' do
    let_it_be_with_reload(:user) { create(:user, :with_namespace) }

    before do
      sign_in(user)
    end

    it 'invalidates all remember user tokens' do
      # The first request authenticates the user. ActiveSession is only stored on the next one (a Warden fetch).
      2.times { get user_settings_active_sessions_path }
      session_id = ActiveSession.list(user).first.session_private_id
      user.remember_me!

      delete user_settings_active_session_path(session_id)

      expect(user.reload.remember_created_at).to be_nil
    end
  end
end
