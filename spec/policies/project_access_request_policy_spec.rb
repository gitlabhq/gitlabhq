require 'spec_helper'

describe ProjectAccessRequestPolicy do
  let(:access_request_user) { create(:user) }
  let(:project) { create(:project) }
  let(:access_request) { project.access_requests.create(user: access_request_user) }

  subject { described_class.new(current_user, access_request) }

  describe "destroying an access request" do
    context "when a regular user tries to destroy an access request" do
      let(:current_user) { create(:user) }

      it { is_expected.not_to be_allowed(:destroy_project_access_request) }
    end

    context "when a regular user tries to destroy their own access request" do
      let(:current_user) { access_request_user }

      it { is_expected.to be_allowed(:destroy_project_access_request) }
    end

    context "when an admin user tries to destroy an access request" do
      let(:current_user) { create(:user, :admin) }

      it { is_expected.to be_allowed(:destroy_project_access_request) }
    end

    context "when a project master tries to destroy an access request" do
      let(:current_user) { create(:user) }

      before do
        project.team << [current_user, :master]
      end

      it { is_expected.to be_allowed(:destroy_project_access_request) }
    end

    context "when a project developer tries to destroy an access request" do
      let(:current_user) { create(:user) }

      before do
        project.team << [current_user, :developer]
      end

      it { is_expected.not_to be_allowed(:destroy_project_access_request) }
    end
  end
end
