# frozen_string_literal: true

require 'spec_helper'

RSpec.describe ProjectMemberPolicy do
  let(:project) { create(:project) }
  let(:maintainer_user) { create(:user) }
  let(:member) { create(:project_member, project: project, user: member_user) }

  subject { described_class.new(maintainer_user, member) }

  before do
    create(:project_member, :maintainer, project: project, user: maintainer_user)
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
end
