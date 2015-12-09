# == Schema Information
#
# Table name: protected_branches
#
#  id                  :integer          not null, primary key
#  project_id          :integer          not null
#  name                :string(255)      not null
#  created_at          :datetime
#  updated_at          :datetime
#  developers_can_push :boolean          default(FALSE), not null
#

require 'spec_helper'

describe ProtectedBranch, models: true do
  describe 'Associations' do
    it { is_expected.to belong_to(:project) }
  end

  describe "Mass assignment" do
  end

  describe 'Validation' do
    it { is_expected.to validate_presence_of(:project) }
    it { is_expected.to validate_presence_of(:name) }
  end
end
