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
  context 'when current size is below or equal to the limit' do
    let(:current_size) { 50 }

    it 'returns zero' do
      expect(subject.exceeded_size).to eq(0)
    end
  end

  context 'when current size is over the limit' do
    let(:current_size) { 51 }

    it 'returns zero' do
      expect(subject.exceeded_size).to eq(1.megabytes)
    end
  end

  context 'when change size will be over the limit' do
    let(:current_size) { 50 }

    it 'returns zero' do
      expect(subject.exceeded_size(1.megabytes)).to eq(1.megabytes)
    end
  end

  context 'when change size will not be over the limit' do
    let(:current_size) { 49 }

    it 'returns zero' do
      expect(subject.exceeded_size(1.megabytes)).to eq(0)
    end
  end
end
