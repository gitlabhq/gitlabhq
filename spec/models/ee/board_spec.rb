require 'spec_helper'

describe Board do
  describe 'milestone' do
    subject { build(:board) }

    context 'when the feature is available' do
      before do
        stub_licensed_features(issue_board_milestone: true)
      end

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

    it 'returns nil when the feature is not available' do
      stub_licensed_features(issue_board_milestone: false)
      milestone = create(:milestone)
      subject.milestone_id = milestone.id

      expect(subject.milestone).to be_nil
    end
  end
end
