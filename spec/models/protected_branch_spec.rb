require 'spec_helper'

describe ProtectedBranch do
  describe 'Associations' do
    it { should belong_to(:project) }
  end

  describe "Mass assignment" do
    it { should_not allow_mass_assignment_of(:project_id) }
  end

  describe 'Validation' do
    it { should validate_presence_of(:project_id) }
    it { should validate_presence_of(:name) }
  end

  describe 'Callbacks' do
    let(:branch) { build(:protected_branch) }

    it 'call update_repository after save' do
      branch.should_receive(:update_repository)
      branch.save
    end

    it 'call update_repository after destroy' do
      branch.save
      branch.should_receive(:update_repository)
      branch.destroy
    end
  end

  describe '#commit' do
    let(:branch) { create(:protected_branch) }

    it 'commits itself to its project' do
      branch.project.should_receive(:commit).with(branch.name)
      branch.commit
    end
  end
end
