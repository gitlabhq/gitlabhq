require 'spec_helper'

describe GlobalPolicy, models: true do
  let(:current_user) { create(:user) }

  subject { GlobalPolicy.new(current_user, :global) }

  describe "reading the list of users" do
    context "for a logged in user" do
      it { is_expected.to be_allowed(:read_users_list) }
    end

    context "for an anonymous user" do
      let(:current_user) { nil }

      context "when the public level is restricted" do
        before do
          stub_application_setting(restricted_visibility_levels: [Gitlab::VisibilityLevel::PUBLIC])
        end

        it { is_expected.not_to be_allowed(:read_users_list) }
      end

      context "when the public level is not restricted" do
        before do
          stub_application_setting(restricted_visibility_levels: [])
        end

        it { is_expected.to be_allowed(:read_users_list) }
      end
    end
  end

  describe "receive_notifications" do
    it { is_expected.to be_allowed(:receive_notifications) }

    context "a blocked user" do
      let(:current_user) { create(:user, state: :blocked) }

      it { is_expected.to be_disallowed(:receive_notifications) }
    end

    context "an internal user" do
      let(:current_user) { User.ghost }

      it { is_expected.to be_disallowed(:receive_notifications) }
    end

    context "a user with globally disabled notification settings" do
      before do
        current_user.global_notification_setting.level = :disabled
        current_user.global_notification_setting.save!
      end

      it { is_expected.to be_disallowed(:receive_notifications) }
    end
  end
end
