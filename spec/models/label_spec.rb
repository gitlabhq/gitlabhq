# == Schema Information
#
# Table name: labels
#
#  id         :integer          not null, primary key
#  title      :string(255)
#  color      :string(255)
#  project_id :integer
#  created_at :datetime
#  updated_at :datetime
#

require 'spec_helper'

describe Label do
  let(:label) { create(:label) }
  it { expect(label).to be_valid }

  it { is_expected.to belong_to(:project) }

  describe 'Validation' do
    it 'should validate color code' do
      expect(build(:label, color: 'G-ITLAB')).not_to be_valid
      expect(build(:label, color: 'AABBCC')).not_to be_valid
      expect(build(:label, color: '#AABBCCEE')).not_to be_valid
      expect(build(:label, color: '#GGHHII')).not_to be_valid
      expect(build(:label, color: '#')).not_to be_valid
      expect(build(:label, color: '')).not_to be_valid

      expect(build(:label, color: '#AABBCC')).to be_valid
    end

    it 'should validate title' do
      expect(build(:label, title: 'G,ITLAB')).not_to be_valid
      expect(build(:label, title: 'G?ITLAB')).not_to be_valid
      expect(build(:label, title: 'G&ITLAB')).not_to be_valid
      expect(build(:label, title: '')).not_to be_valid

      expect(build(:label, title: 'GITLAB')).to be_valid
      expect(build(:label, title: 'gitlab')).to be_valid
    end
  end
end
