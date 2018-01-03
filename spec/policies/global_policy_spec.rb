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

    context "for an admin" do
      let(:current_user) { create(:admin) }

      context "when the public level is restricted" do
        before do
          stub_application_setting(restricted_visibility_levels: [Gitlab::VisibilityLevel::PUBLIC])
        end

        it { is_expected.to be_allowed(:read_users_list) }
      end

      context "when the public level is not restricted" do
        before do
          stub_application_setting(restricted_visibility_levels: [])
        end

        it { is_expected.to be_allowed(:read_users_list) }
      end
    end
  end

  describe "create fork" do
    context "when user has not exceeded project limit" do
      it { is_expected.to be_allowed(:create_fork) }
    end

    context "when user has exceeded project limit" do
      let(:current_user) { create(:user, projects_limit: 0) }

      it { is_expected.not_to be_allowed(:create_fork) }
    end

    context "when user is a master in a group" do
      let(:group) { create(:group) }
      let(:current_user) { create(:user, projects_limit: 0) }

      before do
        group.add_master(current_user)
      end

      it { is_expected.to be_allowed(:create_fork) }
    end
  end

  describe 'custom attributes' do
    context 'regular user' do
      it { is_expected.not_to be_allowed(:read_custom_attribute) }
      it { is_expected.not_to be_allowed(:update_custom_attribute) }
    end

    context 'admin' do
      let(:current_user) { create(:user, :admin) }

      it { is_expected.to be_allowed(:read_custom_attribute) }
      it { is_expected.to be_allowed(:update_custom_attribute) }
    end
  end
end
