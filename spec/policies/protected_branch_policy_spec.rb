require 'spec_helper'

describe ProtectedBranchPolicy do
  let(:user) { create(:user) }
  let(:name) { 'feature' }
  let(:protected_branch) { create(:protected_branch, name: name) }
  let(:project) { protected_branch.project }

  subject { described_class.new(user, protected_branch) }

  it 'branches can be updated via project masters' do
    project.add_master(user)

    is_expected.to be_allowed(:update_protected_branch)
  end

  it "branches can't be updated by guests" do
    project.add_guest(user)

    is_expected.to be_disallowed(:update_protected_branch)
  end
end
