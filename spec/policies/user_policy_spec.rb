# frozen_string_literal: true

require 'spec_helper'

RSpec.describe UserPolicy do
  let(:current_user) { create(:user) }
  let(:user) { create(:user) }

  subject { described_class.new(current_user, user) }

  describe "reading a user's information" do
    it { is_expected.to be_allowed(:read_user) }
  end

  describe "reading a different user's Personal Access Tokens" do
    let(:token) { create(:personal_access_token, user: user) }

    context 'when user is admin' do
      let(:current_user) { create(:user, :admin) }

      context 'when admin mode is enabled', :enable_admin_mode do
        it { is_expected.to be_allowed(:read_user_personal_access_tokens) }
      end

      context 'when admin mode is disabled' do
        it { is_expected.not_to be_allowed(:read_user_personal_access_tokens) }
      end
    end

    context 'when user is not an admin' do
      context 'requesting their own personal access tokens' do
        subject { described_class.new(current_user, current_user) }

        it { is_expected.to be_allowed(:read_user_personal_access_tokens) }
      end

      context "requesting a different user's personal access tokens" do
        it { is_expected.not_to be_allowed(:read_user_personal_access_tokens) }
      end
    end
  end

  describe "creating a different user's Personal Access Tokens" do
    context 'when current_user is admin' do
      let(:current_user) { create(:user, :admin) }

      context 'when admin mode is enabled and current_user is not blocked', :enable_admin_mode do
        it { is_expected.to be_allowed(:create_user_personal_access_token) }
      end

      context 'when admin mode is enabled and current_user is blocked', :enable_admin_mode do
        let(:current_user) { create(:admin, :blocked) }

        it { is_expected.not_to be_allowed(:create_user_personal_access_token) }
      end

      context 'when admin mode is disabled' do
        it { is_expected.not_to be_allowed(:create_user_personal_access_token) }
      end
    end

    context 'when current_user is not an admin' do
      context 'creating their own personal access tokens' do
        subject { described_class.new(current_user, current_user) }

        context 'when current_user is not blocked' do
          it { is_expected.to be_allowed(:create_user_personal_access_token) }
        end

        context 'when current_user is blocked' do
          let(:current_user) { create(:user, :blocked) }

          it { is_expected.not_to be_allowed(:create_user_personal_access_token) }
        end
      end

      context "creating a different user's personal access tokens" do
        it { is_expected.not_to be_allowed(:create_user_personal_access_token) }
      end
    end
  end

  shared_examples 'changing a user' do |ability|
    context "when a regular user tries to destroy another regular user" do
      it { is_expected.not_to be_allowed(ability) }
    end

    context "when a regular user tries to destroy themselves" do
      let(:current_user) { user }

      it { is_expected.to be_allowed(ability) }
    end

    context "when an admin user tries to destroy a regular user" do
      let(:current_user) { create(:user, :admin) }

      context 'when admin mode is enabled', :enable_admin_mode do
        it { is_expected.to be_allowed(ability) }
      end

      context 'when admin mode is disabled' do
        it { is_expected.to be_disallowed(ability) }
      end
    end

    context "when an admin user tries to destroy a ghost user" do
      let(:current_user) { create(:user, :admin) }
      let(:user) { create(:user, :ghost) }

      it { is_expected.not_to be_allowed(ability) }
    end
  end

  describe "updating a user's status" do
    it_behaves_like 'changing a user', :update_user_status
  end

  describe "destroying a user" do
    it_behaves_like 'changing a user', :destroy_user
  end

  describe "updating a user" do
    it_behaves_like 'changing a user', :update_user
  end

  describe 'disabling two-factor authentication' do
    context 'disabling their own two-factor authentication' do
      let(:user) { current_user }

      it { is_expected.to be_allowed(:disable_two_factor) }
    end

    context 'disabling the two-factor authentication of another user' do
      context 'when the executor is an admin', :enable_admin_mode do
        let(:current_user) { create(:user, :admin) }

        it { is_expected.to be_allowed(:disable_two_factor) }
      end

      context 'when the executor is not an admin' do
        it { is_expected.not_to be_allowed(:disable_two_factor) }
      end
    end
  end

  describe "reading a user's group count" do
    context "when current_user is an admin", :enable_admin_mode do
      let(:current_user) { create(:user, :admin) }

      it { is_expected.to be_allowed(:read_group_count) }
    end

    context "for self users" do
      let(:user) { current_user }

      it { is_expected.to be_allowed(:read_group_count) }
    end

    context "when accessing a different user's group count" do
      it { is_expected.not_to be_allowed(:read_group_count) }
    end
  end

  describe ':read_user_profile' do
    context 'when the user is unconfirmed' do
      let(:user) { create(:user, :unconfirmed) }

      it { is_expected.not_to be_allowed(:read_user_profile) }
    end

    context 'when the user is confirmed' do
      it { is_expected.to be_allowed(:read_user_profile) }
    end
  end
end
