# frozen_string_literal: true

RSpec.shared_examples 'boards listable model' do |list_factory|
  subject { build(list_factory) }

  describe 'associations' do
    it { is_expected.to validate_presence_of(:position) }
    it { is_expected.to validate_numericality_of(:position).only_integer.is_greater_than_or_equal_to(0) }

    context 'when list_type is set to closed' do
      subject { build(list_factory, list_type: :closed) }

      it { is_expected.not_to validate_presence_of(:label) }
      it { is_expected.not_to validate_presence_of(:position) }
    end
  end

  describe 'scopes' do
    let_it_be(:list1) { create(list_factory, list_type: :backlog) }
    let_it_be(:list2) { create(list_factory, list_type: :closed) }
    let_it_be(:list3) { create(list_factory, position: 1) }
    let_it_be(:list4) { create(list_factory, position: 2) }

    describe '.ordered' do
      it 'returns lists ordered by type and position' do
        expect(described_class.where(id: [list1, list2, list3, list4]).ordered)
          .to eq([list1, list3, list4, list2])
      end
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

    it 'returns Open when list_type is set to backlog' do
      subject.list_type = :backlog

      expect(subject.title).to eq 'Open'
    end

    it 'returns Closed when list_type is set to closed' do
      subject.list_type = :closed

      expect(subject.title).to eq 'Closed'
    end
  end

  describe '#destroy' do
    it 'can be destroyed when list_type is set to label' do
      subject = create(list_factory) # rubocop:disable Rails/SaveBang

      expect(subject.destroy).to be_truthy
    end

    it 'can not be destroyed when list_type is set to closed' do
      subject = create(list_factory, list_type: :closed)

      expect(subject.destroy).to be_falsey
    end
  end
end
