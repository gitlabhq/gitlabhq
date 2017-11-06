require 'spec_helper'

describe MilestoneArray do
  let(:object1) { instance_double("BirdMilestone", due_date: Time.now, start_date: Time.now - 15.days, title: 'v2.0') }
  let(:object2) { instance_double("CatMilestone", due_date: Time.now - 1.day, start_date: nil, title: 'v1.0') }
  let(:object3) { instance_double("DogMilestone", due_date: nil, start_date: Time.now - 30.days, title: 'v3.0') }
  let(:array) { [object1, object3, object2] }

  describe '#sort' do
    it 'reorders array with due date in ascending order with nulls last' do
      expect(described_class.sort(array, 'due_date_asc')).to eq([object2, object1, object3])
    end

    it 'reorders array with due date in desc order with nulls last' do
      expect(described_class.sort(array, 'due_date_desc')).to eq([object1, object2, object3])
    end

    it 'reorders array with start date in ascending order with nulls last' do
      expect(described_class.sort(array, 'start_date_asc')).to eq([object3, object1, object2])
    end

    it 'reorders array with start date in descending order with nulls last' do
      expect(described_class.sort(array, 'start_date_desc')).to eq([object1, object3, object2])
    end

    it 'reorders array with title in ascending order' do
      expect(described_class.sort(array, 'name_asc')).to eq([object2, object1, object3])
    end

    it 'reorders array with title in descending order' do
      expect(described_class.sort(array, 'name_desc')).to eq([object3, object1, object2])
    end
  end
end
