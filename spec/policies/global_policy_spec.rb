require 'spec_helper'

describe GlobalPolicy do
  let(:current_user) { create(:user) }
  let(:user) { create(:user) }

  subject { described_class.new(current_user, [user]) }

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
end
