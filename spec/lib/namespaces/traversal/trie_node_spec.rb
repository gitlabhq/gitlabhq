# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Namespaces::Traversal::TrieNode, feature_category: :global_search do
  describe '.new' do
    it 'initializes with empty children and end set to false' do
      trie = described_class.new

      expect(trie.children).to be_empty
      expect(trie.end).to be false
    end
  end

  describe '.build' do
    it 'creates a trie from traversal IDs' do
      traversal_ids = [[1, 2], [1, 3], [2, 4]]
      trie = described_class.build(traversal_ids)

      expect(trie).to be_a(described_class)
      expect(trie.children.keys).to contain_exactly(1, 2)
      expect(trie.children[1].children.keys).to contain_exactly(2, 3)
      expect(trie.children[2].children.keys).to contain_exactly(4)
    end

    it 'does not create duplicate branches' do
      traversal_ids = [[1, 2], [1, 2]]
      trie = described_class.build(traversal_ids)

      expect(trie.children[1].children[2].end).to be true
      expect(trie.children[1].children[2].children).to be_empty
    end
  end

  describe '#prefix_search' do
    let(:trie) { described_class.build([[1, 2, 3], [1, 2, 4], [1, 3]]) }

    it 'returns all matching traversal IDs' do
      result = trie.prefix_search([1, 2])

      expect(result).to contain_exactly([1, 2, 3], [1, 2, 4])
    end

    it 'returns an empty array for non-existent prefix' do
      result = trie.prefix_search([4])

      expect(result).to be_empty
    end
  end

  describe '#covered?' do
    let(:trie) { described_class.build([[1, 2], [3, 4]]) }

    it 'returns true for covered traversal ID' do
      expect(trie.covered?([1, 2, 3])).to be true
    end

    it 'returns true for included traversal ID' do
      expect(trie.covered?([1, 2])).to be true
    end

    it 'returns false for non-covered traversal ID' do
      expect(trie.covered?([1, 3])).to be false
    end
  end

  describe '#to_a' do
    it 'returns an array of all traversal IDs in the trie' do
      trie = described_class.build([[1, 2, 3], [1, 2, 4], [1, 3], [4, 5]])

      result = trie.to_a

      expect(result).to contain_exactly([1, 2, 3], [1, 2, 4], [1, 3], [4, 5])
    end

    it 'returns an empty array for an empty trie' do
      trie = described_class.new

      result = trie.to_a

      expect(result).to be_empty
    end

    it 'handles nested branches correctly' do
      trie = described_class.build([[1, 2, 3, 4], [1, 2, 3, 5], [1, 2, 4]])

      result = trie.to_a

      expect(result).to contain_exactly([1, 2, 3, 4], [1, 2, 3, 5], [1, 2, 4])
    end
  end
end
