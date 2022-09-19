# frozen_string_literal: true

require 'spec_helper'

RSpec.describe ProtectedBranchAccessPolicy do
  let(:user) { create(:user) }
  let(:protected_branch_access) { create(:protected_branch_merge_access_level) }
  let(:project) { protected_branch_access.protected_branch.project }

  subject { described_class.new(user, protected_branch_access) }

  context 'as maintainers' do
    before do
      project.add_maintainer(user)
    end

    it 'can be read' do
      is_expected.to be_allowed(:read_protected_branch)
    end
  end

  context 'as guests' do
    before do
      project.add_guest(user)
    end

    it 'can not be read' do
      is_expected.to be_disallowed(:read_protected_branch)
    end
  end
end
