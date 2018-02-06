require 'spec_helper'

describe LabelPriority do
  describe 'relationships' do
    it { is_expected.to belong_to(:project) }
    it { is_expected.to belong_to(:label) }
  end

  describe 'validations' do
    it { is_expected.to validate_presence_of(:project) }
    it { is_expected.to validate_presence_of(:label) }
    it { is_expected.to validate_numericality_of(:priority).only_integer.is_greater_than_or_equal_to(0) }

    it 'validates uniqueness of label_id scoped to project_id' do
      create(:label_priority)

      expect(subject).to validate_uniqueness_of(:label_id).scoped_to(:project_id)
    end
  end
end
