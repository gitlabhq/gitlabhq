require 'spec_helper'

describe UserPolicy do
  let(:current_user) { create(:user) }
  let(:user) { create(:user) }

  subject { described_class.new(current_user, user) }

  describe "reading a user's information" do
    it { is_expected.to be_allowed(:read_user) }
  end

  describe "destroying a user" do
    context "when a regular user tries to destroy another regular user" do
      it { is_expected.not_to be_allowed(:destroy_user) }
    end

    context "when a regular user tries to destroy themselves" do
      let(:current_user) { user }

      it { is_expected.to be_allowed(:destroy_user) }
    end

    context "when an admin user tries to destroy a regular user" do
      let(:current_user) { create(:user, :admin) }

      it { is_expected.to be_allowed(:destroy_user) }
    end

    context "when an admin user tries to destroy a ghost user" do
      let(:current_user) { create(:user, :admin) }
      let(:user) { create(:user, :ghost) }

      it { is_expected.not_to be_allowed(:destroy_user) }
    end
  end
end
