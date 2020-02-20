# frozen_string_literal: true

RSpec.shared_examples 'Gitlab::Verify::BatchVerifier subclass' do
  describe 'batching' do
    let(:first_batch) { objects[0].id..objects[0].id }
    let(:second_batch) { objects[1].id..objects[1].id }
    let(:third_batch) { objects[2].id..objects[2].id }

    it 'iterates through objects in batches' do
      expect(collect_ranges).to eq([first_batch, second_batch, third_batch])
    end

    it 'allows the starting ID to be specified' do
      expect(collect_ranges(start: second_batch.first)).to eq([second_batch, third_batch])
    end

    it 'allows the finishing ID to be specified' do
      expect(collect_ranges(finish: second_batch.last)).to eq([first_batch, second_batch])
    end
  end
end
