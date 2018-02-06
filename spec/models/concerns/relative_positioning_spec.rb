require 'spec_helper'

describe RelativePositioning do
  let(:project) { create(:project) }
  let(:issue) { create(:issue, project: project) }
  let(:issue1) { create(:issue, project: project) }
  let(:new_issue) { create(:issue, project: project) }

  before do
    [issue, issue1].each do |issue|
      issue.move_to_end && issue.save
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

    it 'returns nil if there is no issue above' do
      expect(issue.prev_relative_position).to eq nil
    end
  end

  describe '#next_relative_position' do
    it 'returns next position if there is an issue below' do
      expect(issue.next_relative_position).to eq issue1.relative_position
    end

    it 'returns nil if there is no issue below' do
      expect(issue1.next_relative_position).to eq nil
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

  describe '#shift_after?' do
    it 'returns true' do
      issue.update(relative_position: issue1.relative_position - 1)

      expect(issue.shift_after?).to be_truthy
    end

    it 'returns false' do
      issue.update(relative_position: issue1.relative_position - 2)

      expect(issue.shift_after?).to be_falsey
    end
  end

  describe '#shift_before?' do
    it 'returns true' do
      issue.update(relative_position: issue1.relative_position + 1)

      expect(issue.shift_before?).to be_truthy
    end

    it 'returns false' do
      issue.update(relative_position: issue1.relative_position + 2)

      expect(issue.shift_before?).to be_falsey
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

    it 'positions issues between other two if distance is 1' do
      issue1.update relative_position: issue.relative_position + 1

      new_issue.move_between(issue, issue1)

      expect(new_issue.relative_position).to be > issue.relative_position
      expect(issue.relative_position).to be < issue1.relative_position
    end

    it 'positions issue in the middle of other two if distance is big enough' do
      issue.update relative_position: 6000
      issue1.update relative_position: 10000

      new_issue.move_between(issue, issue1)

      expect(new_issue.relative_position).to eq(8000)
    end

    it 'positions issue closer to the middle if we are at the very top' do
      issue1.update relative_position: 6000

      new_issue.move_between(nil, issue1)

      expect(new_issue.relative_position).to eq(6000 - RelativePositioning::IDEAL_DISTANCE)
    end

    it 'positions issue closer to the middle if we are at the very bottom' do
      issue.update relative_position: 6000
      issue1.update relative_position: nil

      new_issue.move_between(issue, nil)

      expect(new_issue.relative_position).to eq(6000 + RelativePositioning::IDEAL_DISTANCE)
    end

    it 'positions issue in the middle of other two if distance is not big enough' do
      issue.update relative_position: 100
      issue1.update relative_position: 400

      new_issue.move_between(issue, issue1)

      expect(new_issue.relative_position).to eq(250)
    end

    it 'positions issue in the middle of other two is there is no place' do
      issue.update relative_position: 100
      issue1.update relative_position: 101

      new_issue.move_between(issue, issue1)

      expect(new_issue.relative_position).to be_between(issue.relative_position, issue1.relative_position)
    end

    it 'uses rebalancing if there is no place' do
      issue.update relative_position: 100
      issue1.update relative_position: 101
      issue2 = create(:issue, relative_position: 102, project: project)
      new_issue.update relative_position: 103

      new_issue.move_between(issue1, issue2)
      new_issue.save!

      expect(new_issue.relative_position).to be_between(issue1.relative_position, issue2.relative_position)
      expect(issue.reload.relative_position).not_to eq(100)
    end

    it 'positions issue right if we pass none-sequential parameters' do
      issue.update relative_position: 99
      issue1.update relative_position: 101
      issue2 = create(:issue, relative_position: 102, project: project)
      new_issue.update relative_position: 103

      new_issue.move_between(issue, issue2)
      new_issue.save!

      expect(new_issue.relative_position).to be(100)
    end
  end
end
