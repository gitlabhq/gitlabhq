# frozen_string_literal: true

require 'spec_helper'

describe UserPolicy do
  let(:current_user) { create(:user) }
  let(:user) { create(:user) }

  subject { described_class.new(current_user, user) }

  describe "reading a user's information" do
    it { is_expected.to be_allowed(:read_user) }
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

      it { is_expected.to be_allowed(ability) }
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

  describe "updating a user's name" do
    context 'when the ability to update their name is not disabled for users' do
      before do
        stub_application_setting(updating_name_disabled_for_users: false)
      end

      it_behaves_like 'changing a user', :update_name
    end

    context 'when the ability to update their name is disabled for users' do
      before do
        stub_application_setting(updating_name_disabled_for_users: true)
      end

      context 'for a regular user' do
        it { is_expected.not_to be_allowed(:update_name) }
      end

      context 'for a ghost user' do
        let(:current_user) { create(:user, :ghost) }

        it { is_expected.not_to be_allowed(:update_name) }
      end

      context 'for an admin user' do
        let(:current_user) { create(:admin) }

        it { is_expected.to be_allowed(:update_name) }
      end
    end
  end
end
