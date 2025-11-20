# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::Reflections::Relationships::Transformers::Validate, feature_category: :database do
  let(:valid_relationship) do
    Gitlab::Reflections::Relationships::Relationship.new(
      parent_table: 'users',
      child_table: 'posts',
      foreign_key: 'user_id'
    )
  end

  let(:invalid_relationship) do
    Gitlab::Reflections::Relationships::Relationship.new(
      parent_table: 'users',
      child_table: nil,
      foreign_key: 'user_id'
    )
  end

  describe '.call' do
    it 'creates an instance and calls transform' do
      relationships = [valid_relationship]
      expect(described_class).to receive(:new).with(relationships).and_call_original
      result = described_class.call(relationships)

      expect(result).to be_an(Array)
      expect(result.length).to eq(1)
      expect(result.first).to be_a(Gitlab::Reflections::Relationships::Relationship)
      expect(result.first.parent_table).to eq('users')
      expect(result.first.child_table).to eq('posts')
      expect(result.first.foreign_key).to eq('user_id')
    end
  end

  describe '#transform' do
    context 'with all valid relationships' do
      it 'returns all valid relationships' do
        relationships = [valid_relationship, valid_relationship]
        transformer = described_class.new(relationships)
        result = transformer.transform

        expect(result).to be_an(Array)
        expect(result.length).to eq(2)
        expect(result).to all(be_a(Gitlab::Reflections::Relationships::Relationship))
        expect(result).to all(satisfy { |rel| rel.parent_table == 'users' && rel.child_table == 'posts' })
      end
    end

    context 'with all invalid relationships' do
      it 'returns an empty array' do
        relationships = [invalid_relationship, invalid_relationship]
        transformer = described_class.new(relationships)
        result = transformer.transform

        expect(result).to eq([])
      end
    end

    context 'with mixed valid and invalid relationships' do
      it 'filters out invalid relationships and returns only valid ones' do
        relationships = [valid_relationship, invalid_relationship, valid_relationship]
        transformer = described_class.new(relationships)
        result = transformer.transform

        expect(result).to be_an(Array)
        expect(result.length).to eq(2)
        expect(result).to all(be_a(Gitlab::Reflections::Relationships::Relationship))
        expect(result).to all(satisfy { |rel| rel.parent_table == 'users' && rel.child_table == 'posts' })
      end
    end

    context 'with empty relationships array' do
      it 'returns an empty array' do
        relationships = []
        transformer = described_class.new(relationships)
        result = transformer.transform

        expect(result).to eq([])
      end
    end
  end
end
