require 'spec_helper'

describe Issue, 'RelativePositioning' do
  let(:project) { create(:empty_project) }
  let(:issue) { create(:issue, project: project) }
  let(:issue1) { create(:issue, project: project) }
  let(:new_issue) { create(:issue, project: project) }

  before do
    [issue, issue1].each do |issue|
      issue.move_to_end && issue.save
    end
  end

  describe '#min_relative_position' do
    it 'returns maximum position' do
      expect(issue.min_relative_position).to eq issue.relative_position
    end
  end

  describe '#max_relative_position' do
    it 'returns maximum position' do
      expect(issue.max_relative_position).to eq issue1.relative_position
    end
  end

  describe '#prev_relative_position' do
    it 'returns previous position if there is an issue above' do
      expect(issue1.prev_relative_position).to eq issue.relative_position
    end

    it 'returns minimum position if there is no issue above' do
      expect(issue.prev_relative_position).to eq RelativePositioning::MIN_POSITION
    end
  end

  describe '#next_relative_position' do
    it 'returns next position if there is an issue below' do
      expect(issue.next_relative_position).to eq issue1.relative_position
    end

    it 'returns next position if there is no issue below' do
      expect(issue1.next_relative_position).to eq RelativePositioning::MAX_POSITION
    end
  end


  describe '#move_before' do
    it 'moves issue before' do
      [issue1, issue].each(&:move_to_end)

      issue.move_before(issue1)

      expect(issue.relative_position).to be < issue1.relative_position
    end
  end

  describe '#move_after' do
    it 'moves issue after' do
      [issue, issue1].each(&:move_to_end)

      issue.move_after(issue1)

      expect(issue.relative_position).to be > issue1.relative_position
    end
  end

  describe '#move_to_end' do
    it 'moves issue to the end' do
      new_issue.move_to_end

      expect(new_issue.relative_position).to be > issue1.relative_position
    end
  end

  describe '#move_between' do
    it 'positions issue between two other' do
      new_issue.move_between(issue, issue1)

      expect(new_issue.relative_position).to be > issue.relative_position
      expect(new_issue.relative_position).to be < issue1.relative_position
    end

    it 'positions issue between on top' do
      new_issue.move_between(nil, issue)

      expect(new_issue.relative_position).to be < issue.relative_position
    end

    it 'positions issue between to end' do
      new_issue.move_between(issue1, nil)

      expect(new_issue.relative_position).to be > issue1.relative_position
    end

    it 'positions issues even when after and before positions are the same' do
      issue1.update relative_position: issue.relative_position

      new_issue.move_between(issue, issue1)

      expect(new_issue.relative_position).to be > issue.relative_position
      expect(issue.relative_position).to be < issue1.relative_position
    end
  end
end
