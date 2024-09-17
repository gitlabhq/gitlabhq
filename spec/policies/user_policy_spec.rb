# frozen_string_literal: true

require 'spec_helper'

RSpec.describe UserPolicy do
  let_it_be(:admin) { create(:user, :admin) }
  let_it_be(:regular_user) { create(:user) }
  let_it_be(:subject_user) { create(:user) }

  let(:current_user) { regular_user }
  let(:user) { subject_user }

  subject { described_class.new(current_user, user) }

  describe "reading a user's information" do
    it { is_expected.to be_allowed(:read_user) }
  end

  describe "reading a different user's Personal access tokens" do
    let(:token) { create(:personal_access_token, user: user) }

    context 'when user is admin' do
      let(:current_user) { admin }

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

  describe "creating a different user's Personal access tokens" do
    context 'when current_user is admin' do
      let(:current_user) { admin }

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

  describe "reading a user's associations count" do
    context 'when current_user is not an admin' do
      context 'fetching their own data' do
        subject { described_class.new(current_user, current_user) }

        context 'when current_user is not blocked' do
          it { is_expected.to be_allowed(:get_user_associations_count) }
        end

        context 'when current_user is blocked' do
          let(:current_user) { create(:user, :blocked) }

          it { is_expected.not_to be_allowed(:get_user_associations_count) }
        end
      end

      context "fetching a different user's data" do
        it { is_expected.not_to be_allowed(:get_user_associations_count) }
      end
    end

    context 'when current_user is an admin' do
      let(:current_user) { admin }

      context 'fetching their own data', :enable_admin_mode do
        subject { described_class.new(current_user, current_user) }

        context 'when current_user is not blocked' do
          it { is_expected.to be_allowed(:get_user_associations_count) }
        end

        context 'when current_user is blocked' do
          let(:current_user) { create(:admin, :blocked) }

          it { is_expected.not_to be_allowed(:get_user_associations_count) }
        end
      end

      context "fetching a different user's data", :enable_admin_mode do
        it { is_expected.to be_allowed(:get_user_associations_count) }
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
      let(:current_user) { admin }

      context 'when admin mode is enabled', :enable_admin_mode do
        it { is_expected.to be_allowed(ability) }
      end

      context 'when admin mode is disabled' do
        it { is_expected.to be_disallowed(ability) }
      end
    end

    context "when an admin user tries to destroy a ghost user" do
      let(:current_user) { admin }
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
        let(:current_user) { admin }

        it { is_expected.to be_allowed(:disable_two_factor) }
      end

      context 'when the executor is not an admin' do
        it { is_expected.not_to be_allowed(:disable_two_factor) }
      end
    end
  end

  describe "reading a user's group count" do
    context "when current_user is an admin", :enable_admin_mode do
      let(:current_user) { admin }

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

  describe ':read_user_groups' do
    context 'when user is admin' do
      let(:current_user) { admin }

      context 'when admin mode is enabled', :enable_admin_mode do
        it { is_expected.to be_allowed(:read_user_groups) }
      end

      context 'when admin mode is disabled' do
        it { is_expected.not_to be_allowed(:read_user_groups) }
      end
    end

    context 'when user is not an admin' do
      context 'requesting their own manageable groups' do
        subject { described_class.new(current_user, current_user) }

        it { is_expected.to be_allowed(:read_user_groups) }
      end

      context "requesting a different user's manageable groups" do
        it { is_expected.not_to be_allowed(:read_user_groups) }
      end
    end
  end

  describe ':read_user_organizations' do
    context 'when user is admin' do
      let(:current_user) { admin }

      context 'when admin mode is enabled', :enable_admin_mode do
        it { is_expected.to be_allowed(:read_user_organizations) }
      end

      context 'when admin mode is disabled' do
        it { is_expected.not_to be_allowed(:read_user_organizations) }
      end
    end

    context 'when user is not an admin' do
      context 'requesting their own organizations' do
        subject { described_class.new(current_user, current_user) }

        it { is_expected.to be_allowed(:read_user_organizations) }
      end

      context "requesting a different user's orgnanizations" do
        it { is_expected.not_to be_allowed(:read_user_organizations) }
      end
    end
  end

  describe ':read_user_email_address' do
    context 'when user is admin' do
      let(:current_user) { admin }

      context 'when admin mode is enabled', :enable_admin_mode do
        it { is_expected.to be_allowed(:read_user_email_address) }
        it { is_expected.to be_allowed(:admin_user_email_address) }
      end

      context 'when admin mode is disabled' do
        it { is_expected.not_to be_allowed(:read_user_email_address) }
        it { is_expected.not_to be_allowed(:admin_user_email_address) }
      end
    end

    context 'when user is not an admin' do
      context 'requesting their own' do
        subject { described_class.new(current_user, current_user) }

        it { is_expected.to be_allowed(:read_user_email_address) }
        it { is_expected.to be_allowed(:admin_user_email_address) }
      end

      context "requesting a different user's" do
        it { is_expected.not_to be_allowed(:read_user_email_address) }
        it { is_expected.not_to be_allowed(:admin_user_email_address) }
      end
    end
  end

  describe ':read_user_preference' do
    context 'when user is admin' do
      let(:current_user) { admin }

      context 'when admin mode is enabled', :enable_admin_mode do
        it { is_expected.to be_allowed(:read_user_preference) }
      end

      context 'when admin mode is disabled' do
        it { is_expected.not_to be_allowed(:read_user_preference) }
      end
    end

    context 'when user is not an admin' do
      context 'requesting their own' do
        subject { described_class.new(current_user, current_user) }

        it { is_expected.to be_allowed(:read_user_preference) }
      end

      context "requesting a different user's" do
        it { is_expected.not_to be_allowed(:read_user_preference) }
      end
    end
  end
end
