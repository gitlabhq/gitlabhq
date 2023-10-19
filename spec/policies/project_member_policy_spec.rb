# frozen_string_literal: true

require 'spec_helper'

RSpec.describe ProjectMemberPolicy, feature_category: :groups_and_projects do
  let_it_be(:project) { create(:project) }
  let_it_be(:maintainer) { create(:user) }
  let(:member) { create(:project_member, project: project, user: member_user) }
  let(:current_user) { maintainer }

  subject { described_class.new(current_user, member) }

  before do
    create(:project_member, :maintainer, project: project, user: maintainer)
  end

  context 'with regular member' do
    let(:member_user) { create(:user) }

    it { is_expected.to be_allowed(:read_project) }
    it { is_expected.to be_allowed(:update_project_member) }
    it { is_expected.to be_allowed(:destroy_project_member) }

    it { is_expected.not_to be_allowed(:destroy_project_bot_member) }
  end

  context 'when user is the holder of personal namespace in which the project resides' do
    let(:namespace_holder) { project.namespace.owner }
    let(:member) { project.members.find_by!(user: namespace_holder) }

    it { is_expected.to be_allowed(:read_project) }
    it { is_expected.to be_disallowed(:update_project_member) }
    it { is_expected.to be_disallowed(:destroy_project_member) }
  end

  context 'with a bot member' do
    let(:member_user) { create(:user, :project_bot) }

    it { is_expected.to be_allowed(:destroy_project_bot_member) }

    it { is_expected.not_to be_allowed(:update_project_member) }
    it { is_expected.not_to be_allowed(:destroy_project_member) }
  end

  context 'for access requests' do
    let_it_be(:project) { create(:project, :public) }
    let_it_be(:user) { create(:user) }

    let(:current_user) { user }

    context 'for own access request' do
      let(:member) { create(:project_member, :access_request, project: project, user: user) }

      specify { expect_allowed(:withdraw_member_access_request) }
    end

    context "for another user's access request" do
      let(:member) { create(:project_member, :access_request, project: project, user: create(:user)) }

      specify { expect_disallowed(:withdraw_member_access_request) }
    end

    context 'for own, valid membership' do
      let(:member) { create(:project_member, :developer, project: project, user: user) }

      specify { expect_disallowed(:withdraw_member_access_request) }
    end
  end
end
