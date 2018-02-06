require 'rails_helper'

describe List do
  describe 'relationships' do
    it { is_expected.to belong_to(:board) }
    it { is_expected.to belong_to(:label) }
  end

  describe 'validations' do
    it { is_expected.to validate_presence_of(:board) }
    it { is_expected.to validate_presence_of(:label) }
    it { is_expected.to validate_presence_of(:list_type) }
    it { is_expected.to validate_presence_of(:position) }
    it { is_expected.to validate_numericality_of(:position).only_integer.is_greater_than_or_equal_to(0) }

    context 'when list_type is set to closed' do
      subject { described_class.new(list_type: :closed) }

      it { is_expected.not_to validate_presence_of(:label) }
      it { is_expected.not_to validate_presence_of(:position) }
    end
  end

  describe '#destroy' do
    it 'can be destroyed when when list_type is set to label' do
      subject = create(:list)

      expect(subject.destroy).to be_truthy
    end

    it 'can not be destroyed when when list_type is set to closed' do
      subject = create(:closed_list)

      expect(subject.destroy).to be_falsey
    end
  end

  describe '#destroyable?' do
    it 'returns true when list_type is set to label' do
      subject.list_type = :label

      expect(subject).to be_destroyable
    end

    it 'returns false when list_type is set to closed' do
      subject.list_type = :closed

      expect(subject).not_to be_destroyable
    end
  end

  describe '#movable?' do
    it 'returns true when list_type is set to label' do
      subject.list_type = :label

      expect(subject).to be_movable
    end

    it 'returns false when list_type is set to closed' do
      subject.list_type = :closed

      expect(subject).not_to be_movable
    end
  end

  describe '#title' do
    it 'returns label name when list_type is set to label' do
      subject.list_type = :label
      subject.label = Label.new(name: 'Development')

      expect(subject.title).to eq 'Development'
    end

    it 'returns Closed when list_type is set to closed' do
      subject.list_type = :closed

      expect(subject.title).to eq 'Closed'
    end
  end
end
