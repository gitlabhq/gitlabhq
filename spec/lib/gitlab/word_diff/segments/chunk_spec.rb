# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::WordDiff::Segments::Chunk do
  subject(:chunk) { described_class.new(line) }

  let(:line) { ' Hello' }

  describe '#removed?' do
    subject { chunk.removed? }

    it { is_expected.to be_falsey }

    context 'when line starts with "-"' do
      let(:line) { '-Removed' }

      it { is_expected.to be_truthy }
    end
  end

  describe '#added?' do
    subject { chunk.added? }

    it { is_expected.to be_falsey }

    context 'when line starts with "+"' do
      let(:line) { '+Added' }

      it { is_expected.to be_truthy }
    end
  end

  describe '#to_s' do
    subject { chunk.to_s }

    it 'removes lead string modifier' do
      is_expected.to eq('Hello')
    end

    context 'when chunk is empty' do
      let(:line) { '' }

      it { is_expected.to eq('') }
    end
  end

  describe '#length' do
    subject { chunk.length }

    it { is_expected.to eq('Hello'.length) }
  end
end
