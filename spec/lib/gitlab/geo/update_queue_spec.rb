require 'spec_helper'

describe Gitlab::Geo::UpdateQueue do
  subject { described_class.new('test_queue') }
  let(:dummy_data) { { 'id' => 1, 'clone_url' => 'git@localhost:repo/path.git' } }
  let(:dummy_data2) { { 'id' => 99, 'clone_url' => 'git@localhost:other_repo/path.git' } }
  let(:multiple_dummy_data) { [dummy_data, dummy_data2] * 10 }

  before(:each) { subject.empty! }

  describe '#store' do
    before(:each) { subject.store(dummy_data) }

    it 'stores data to the queue' do
      expect(subject).not_to be_empty
    end

    it 'stored data is equal to original' do
      expect(subject.first).to eq(dummy_data)
    end
  end

  context 'when queue has elements' do
    before(:each) do
      subject.store(dummy_data)
      subject.store(dummy_data2)
    end

    describe '#first' do
      it { expect(subject.first).to eq(dummy_data) }
    end

    describe '#last' do
      it { expect(subject.last).to eq(dummy_data2) }
    end
  end

  describe '#fetch_batched_data' do
    before(:each) { subject.store_batched_data(multiple_dummy_data) }

    it 'returns same stored data' do
      expect(subject.fetch_batched_data).to eq(multiple_dummy_data)
    end
  end

  describe '#store_batched_data' do
    let(:ordered_data) { [{ 'a' => 1 }, { 'a' => 2 }, { 'a' => 3 }, { 'a' => 4 }, { 'a' => 5 }] }

    it 'stores multiple items to the queue' do
      expect { subject.store_batched_data(multiple_dummy_data) }.to change { subject.batch_size }.by(multiple_dummy_data.size)
    end

    it 'returns data in equal order to original' do
      subject.store_batched_data(ordered_data)

      expect(subject.first).to eq(ordered_data.first)
      expect(subject.last).to eq(ordered_data.last)
    end
  end

  describe '#batch_size' do
    before(:each) { allow(subject).to receive(:queue_size) { queue_size } }

    context 'when queue size is smaller than BATCH_SIZE' do
      let(:queue_size) { described_class::BATCH_SIZE - 20 }

      it 'equals to the queue size' do
        expect(subject.batch_size).to eq(queue_size)
      end
    end

    context 'when queue size is bigger than BATCH_SIZE' do
      let(:queue_size) { described_class::BATCH_SIZE + 20 }

      it 'equals to the BATCH_SIZE' do
        expect(subject.batch_size).to eq(described_class::BATCH_SIZE)
      end
    end
  end

  describe '#queue_size' do
    it 'returns the ammount of items in queue' do
      expect { subject.store(dummy_data) }.to change { subject.queue_size }.by(1)
    end
  end

  describe '#empty?' do
    it 'returns true when empty' do
      is_expected.to be_empty
    end

    it 'returns false when there are enqueue data' do
      subject.store(dummy_data)
      is_expected.not_to be_empty
    end
  end
end
