# frozen_string_literal: true

require 'spec_helper'

describe GlobalPolicy do
  include TermsHelper

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

    context "when user is a maintainer in a group" do
      let(:group) { create(:group) }
      let(:current_user) { create(:user, projects_limit: 0) }

      before do
        group.add_maintainer(current_user)
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

  shared_examples 'access allowed when terms accepted' do |ability|
    it { is_expected.not_to be_allowed(ability) }

    it "allows #{ability} when the user accepted the terms" do
      accept_terms(current_user)

      is_expected.to be_allowed(ability)
    end
  end

  describe 'API access' do
    context 'regular user' do
      it { is_expected.to be_allowed(:access_api) }
    end

    context 'admin' do
      let(:current_user) { create(:admin) }

      it { is_expected.to be_allowed(:access_api) }
    end

    context 'anonymous' do
      let(:current_user) { nil }

      it { is_expected.to be_allowed(:access_api) }
    end

    context 'when terms are enforced' do
      before do
        enforce_terms
      end

      context 'regular user' do
        it_behaves_like 'access allowed when terms accepted', :access_api
      end

      context 'admin' do
        let(:current_user) { create(:admin) }

        it_behaves_like 'access allowed when terms accepted', :access_api
      end

      context 'anonymous' do
        let(:current_user) { nil }

        it { is_expected.to be_allowed(:access_api) }
      end
    end
  end

  describe 'receive notifications' do
    describe 'regular user' do
      it { is_expected.to be_allowed(:receive_notifications) }
    end

    describe 'admin' do
      let(:current_user) { create(:admin) }

      it { is_expected.to be_allowed(:receive_notifications) }
    end

    describe 'anonymous' do
      let(:current_user) { nil }

      it { is_expected.not_to be_allowed(:receive_notifications) }
    end

    describe 'blocked user' do
      before do
        current_user.block
      end

      it { is_expected.not_to be_allowed(:receive_notifications) }
    end

    describe 'deactivated user' do
      before do
        current_user.deactivate
      end

      it { is_expected.not_to be_allowed(:receive_notifications) }
    end
  end

  describe 'git access' do
    describe 'regular user' do
      it { is_expected.to be_allowed(:access_git) }
    end

    describe 'admin' do
      let(:current_user) { create(:admin) }

      it { is_expected.to be_allowed(:access_git) }
    end

    describe 'anonymous' do
      let(:current_user) { nil }

      it { is_expected.to be_allowed(:access_git) }
    end

    describe 'deactivated user' do
      before do
        current_user.deactivate
      end

      it { is_expected.not_to be_allowed(:access_git) }
    end

    context 'when terms are enforced' do
      before do
        enforce_terms
      end

      context 'regular user' do
        it_behaves_like 'access allowed when terms accepted', :access_git
      end

      context 'admin' do
        let(:current_user) { create(:admin) }

        it_behaves_like 'access allowed when terms accepted', :access_git
      end

      context 'anonymous' do
        let(:current_user) { nil }

        it { is_expected.to be_allowed(:access_git) }
      end
    end
  end

  describe 'read instance metadata' do
    context 'regular user' do
      it { is_expected.to be_allowed(:read_instance_metadata) }
    end

    context 'anonymous' do
      let(:current_user) { nil }

      it { is_expected.not_to be_allowed(:read_instance_metadata) }
    end
  end

  describe 'read instance statistics' do
    context 'regular user' do
      it { is_expected.to be_allowed(:read_instance_statistics) }

      context 'when instance statistics are set to private' do
        before do
          stub_application_setting(instance_statistics_visibility_private: true)
        end

        it { is_expected.not_to be_allowed(:read_instance_statistics) }
      end
    end

    context 'admin' do
      let(:current_user) { create(:admin) }

      it { is_expected.to be_allowed(:read_instance_statistics) }

      context 'when instance statistics are set to private' do
        before do
          stub_application_setting(instance_statistics_visibility_private: true)
        end

        it { is_expected.to be_allowed(:read_instance_statistics) }
      end
    end

    context 'anonymous' do
      let(:current_user) { nil }

      it { is_expected.not_to be_allowed(:read_instance_statistics) }
    end
  end

  describe 'slash commands' do
    context 'regular user' do
      it { is_expected.to be_allowed(:use_slash_commands) }
    end

    context 'when internal' do
      let(:current_user) { User.ghost }

      it { is_expected.not_to be_allowed(:use_slash_commands) }
    end

    context 'when blocked' do
      before do
        current_user.block
      end

      it { is_expected.not_to be_allowed(:use_slash_commands) }
    end

    context 'when deactivated' do
      before do
        current_user.deactivate
      end

      it { is_expected.not_to be_allowed(:use_slash_commands) }
    end

    context 'when access locked' do
      before do
        current_user.lock_access!
      end

      it { is_expected.not_to be_allowed(:use_slash_commands) }
    end
  end

  describe 'create_personal_snippet' do
    context 'when anonymous' do
      let(:current_user) { nil }

      it { is_expected.not_to be_allowed(:create_personal_snippet) }
    end

    context 'regular user' do
      it { is_expected.to be_allowed(:create_personal_snippet) }
    end

    context 'when external' do
      let(:current_user) { build(:user, :external) }

      it { is_expected.not_to be_allowed(:create_personal_snippet) }
    end
  end
end
