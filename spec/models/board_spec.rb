require 'rails_helper'

describe Board do
  describe 'relationships' do
    it { is_expected.to belong_to(:project) }
    it { is_expected.to belong_to(:milestone) }

    it { is_expected.to have_many(:lists).order(list_type: :asc, position: :asc).dependent(:delete_all) }
  end

  describe 'validations' do
    it { is_expected.to validate_presence_of(:name) }
    it { is_expected.to validate_presence_of(:project) }
  end

  describe 'milestone' do
    subject { described_class.new }

    it 'returns Milestone::Upcoming for upcoming milestone id' do
      subject.milestone_id = Milestone::Upcoming.id

      expect(subject.milestone).to eq Milestone::Upcoming
    end

    it 'returns milestone for valid milestone id' do
      milestone = create(:milestone)
      subject.milestone_id = milestone.id

      expect(subject.milestone).to eq milestone
    end

    it 'returns nil for invalid milestone id' do
      subject.milestone_id = -1

      expect(subject.milestone).to be_nil
    end
  end
end
