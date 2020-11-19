# frozen_string_literal: true

RSpec.shared_examples 'checker size above limit' do
  context 'when size is above the limit' do
    let(:current_size) { 100 }

    it 'returns true' do
      expect(subject.above_size_limit?).to eq(true)
    end
  end
end

RSpec.shared_examples 'checker size not over limit' do
  it 'returns false when not over the limit' do
    expect(subject.above_size_limit?).to eq(false)
  end
end

RSpec.shared_examples 'checker size exceeded' do
  context 'when no change size provided' do
    context 'when current size is below the limit' do
      let(:current_size) { limit - 1 }

      it 'returns zero' do
        expect(subject.exceeded_size).to eq(0)
      end
    end

    context 'when current size is equal to the limit' do
      let(:current_size) { limit }

      it 'returns zero' do
        expect(subject.exceeded_size).to eq(0)
      end
    end

    context 'when current size is over the limit' do
      let(:current_size) { limit + 1 }
      let(:total_repository_size_excess) { 1 }

      it 'returns a positive number' do
        expect(subject.exceeded_size).to eq(1.megabyte)
      end
    end
  end

  context 'when a change size is provided' do
    let(:change_size) { 1.megabyte }

    context 'when change size will be over the limit' do
      let(:current_size) { limit }

      it 'returns a positive number' do
        expect(subject.exceeded_size(change_size)).to eq(1.megabyte)
      end
    end

    context 'when change size will be at the limit' do
      let(:current_size) { limit - 1 }

      it 'returns zero' do
        expect(subject.exceeded_size(change_size)).to eq(0)
      end
    end

    context 'when change size will be under the limit' do
      let(:current_size) { limit - 2 }

      it 'returns zero' do
        expect(subject.exceeded_size(change_size)).to eq(0)
      end
    end
  end
end
