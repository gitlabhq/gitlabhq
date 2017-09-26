require 'spec_helper'

describe BoardFilter, type: :model do
  describe 'validations' do
    it { is_expected.to validate_presence_of(:board) }
  end

  describe 'associations' do
    it { is_expected.to belong_to(:board) }
    it { is_expected.to belong_to(:milestone) }
    it { is_expected.to belong_to(:author).class_name('User') }
    it { is_expected.to belong_to(:assignee).class_name('User') }
    it { is_expected.to have_many(:board_filter_labels) }
    it { is_expected.to have_many(:labels).through(:board_filter_labels) }
  end

  describe 'milestone' do
    subject(:board_filter) { build(:board_filter) }

    context 'when the feature is available' do
      before do
        stub_licensed_features(scoped_issue_board: true)
      end

      it 'returns Milestone::Upcoming for upcoming milestone id' do
        board_filter.milestone_id = Milestone::Upcoming.id

        expect(board_filter.milestone).to eq Milestone::Upcoming
      end

      it 'returns milestone for valid milestone id' do
        milestone = create(:milestone)
        board_filter.milestone_id = milestone.id

        expect(board_filter.milestone).to eq milestone
      end

      it 'returns nil for invalid milestone id' do
        board_filter.milestone_id = -1

        expect(board_filter.milestone).to be_nil
      end
    end

    it 'returns nil when the feature is not available' do
      stub_licensed_features(scoped_issue_board: false)
      milestone = create(:milestone)
      board_filter.milestone_id = milestone.id

      expect(board_filter.milestone).to be_nil
    end
  end
end
