# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Profiles::AvatarsController, feature_category: :user_profile do
  let(:user) { create(:user, avatar: fixture_file_upload("spec/fixtures/dk.png")) }

  before do
    sign_in(user)
  end

  it 'removes avatar from DB by calling destroy' do
    delete profile_avatar_path

    expect(response).to redirect_to(user_settings_profile_path)
    expect(user.reload.avatar.present?).to be_falsey
    expect(user).to be_valid
  end
end
