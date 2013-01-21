# == Schema Information
#
# Table name: protected_branches
#
#  id         :integer          not null, primary key
#  project_id :integer          not null
#  name       :string(255)      not null
#  created_at :datetime         not null
#  updated_at :datetime         not null
#

require 'spec_helper'

describe ProtectedBranch do
  describe 'Associations' do
    it { should belong_to(:project) }
  end

  describe "Mass assignment" do
    it { should_not allow_mass_assignment_of(:project_id) }
  end

  describe 'Validation' do
    it { should validate_presence_of(:project) }
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
end
