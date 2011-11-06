require 'spec_helper'

describe "Users Security" do
  describe "Project" do
    before do
      @u1 = Factory :user
    end

    describe "GET /login" do
      #it { new_user_session_path.should be_denied_for @u1 }
      #it { new_user_session_path.should be_denied_for :admin }
      #it { new_user_session_path.should be_denied_for :user }
      it { new_user_session_path.should_not be_404_for :visitor }
    end

    describe "GET /keys" do
      it { keys_path.should be_allowed_for @u1 }
      it { keys_path.should be_allowed_for :admin }
      it { keys_path.should be_allowed_for :user }
      it { keys_path.should be_denied_for :visitor }
    end

    describe "GET /profile" do
      it { profile_path.should be_allowed_for @u1 }
      it { profile_path.should be_allowed_for :admin }
      it { profile_path.should be_allowed_for :user }
      it { profile_path.should be_denied_for :visitor }
    end

    describe "GET /profile/password" do
      it { profile_password_path.should be_allowed_for @u1 }
      it { profile_password_path.should be_allowed_for :admin }
      it { profile_password_path.should be_allowed_for :user }
      it { profile_password_path.should be_denied_for :visitor }
    end
  end
end
