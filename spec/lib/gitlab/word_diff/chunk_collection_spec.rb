# frozen_string_literal: true

require 'spec_helper'

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
end
