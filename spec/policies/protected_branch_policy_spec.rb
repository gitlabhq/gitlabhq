require 'spec_helper'

describe ProtectedBranchPolicy do
  let(:user) { create(:user) }
  let(:name) { 'feature' }
  let(:protected_branch) { create(:protected_branch, name: name) }
  let(:project) { protected_branch.project }

  subject { described_class.new(user, protected_branch) }

  context 'when unprotection restriction feature is disabled' do
    it "branches can't be updated by guests" do
      project.add_guest(user)

      is_expected.to be_disallowed(:update_protected_branch)
    end

    it 'branches can be updated via access to project settings' do
      project.add_master(user)

      is_expected.to be_allowed(:update_protected_branch)
    end
  end

  context 'when unprotection restriction feature is enabled' do
    before do
      # stub_licensed_features(unprotection_restrictions: true)
    end

    context 'and unprotection is limited to admins' do #TODO: remove this is temporary exploration
      before do
        stub_ee_application_setting(only_admins_can_unprotect_master_branch: true)
      end

      context 'and the protection is for master' do
        let(:name) { 'master' }

        it 'project owners cannot remove protections' do
          project.add_master(user)

          is_expected.not_to be_allowed(:update_protected_branch)
        end

        it 'admins can remove protections' do
          user.update!(admin: true)

          is_expected.to be_allowed(:update_protected_branch)
        end
      end

      context "and the protection isn't for master" do
        it 'project owners can remove protections' do
          project.add_master(user)

          is_expected.to be_allowed(:update_protected_branch)
        end
      end
    end
  end
end
