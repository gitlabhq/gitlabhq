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
end
