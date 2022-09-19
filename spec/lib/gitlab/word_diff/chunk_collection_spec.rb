# frozen_string_literal: true

require 'fast_spec_helper'

RSpec.describe Gitlab::WordDiff::ChunkCollection do
  subject(:collection) { described_class.new }

  describe '#add' do
    it 'adds elements to the chunk collection' do
      collection.add('Hello')
      collection.add(' World')

      expect(collection.content).to eq('Hello World')
    end
  end

  describe '#content' do
    subject { collection.content }

    context 'when no elements in the collection' do
      it { is_expected.to eq('') }
    end

    context 'when elements exist' do
      before do
        collection.add('Hi')
        collection.add(' GitLab!')
      end

      it { is_expected.to eq('Hi GitLab!') }
    end
  end

  describe '#reset' do
    it 'clears the collection' do
      collection.add('1')
      collection.add('2')

      collection.reset

      expect(collection.content).to eq('')
    end
  end

  describe '#marker_ranges' do
    let(:chunks) do
      [
        Gitlab::WordDiff::Segments::Chunk.new(' Hello '),
        Gitlab::WordDiff::Segments::Chunk.new('-World'),
        Gitlab::WordDiff::Segments::Chunk.new('+GitLab'),
        Gitlab::WordDiff::Segments::Chunk.new('+!!!')
      ]
    end

    it 'returns marker ranges for every chunk with changes' do
      chunks.each { |chunk| collection.add(chunk) }

      expect(collection.marker_ranges).to eq(
        [
          Gitlab::MarkerRange.new(6, 10, mode: :deletion),
          Gitlab::MarkerRange.new(11, 16, mode: :addition),
          Gitlab::MarkerRange.new(17, 19, mode: :addition)
        ]
      )
    end
  end
end
