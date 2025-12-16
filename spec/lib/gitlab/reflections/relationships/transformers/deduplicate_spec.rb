# frozen_string_literal: true

require 'fast_spec_helper'

RSpec.describe Gitlab::Reflections::Relationships::Transformers::Deduplicate, feature_category: :database do
  let(:relationship1) do
    Gitlab::Reflections::Relationships::Relationship.new(
      parent_table: 'users',
      child_table: 'posts',
      primary_key: 'id',
      foreign_key: 'user_id',
      relationship_type: 'one_to_many'
    )
  end

  let(:relationship2) do
    Gitlab::Reflections::Relationships::Relationship.new(
      parent_table: 'users',
      child_table: 'comments',
      primary_key: 'id',
      foreign_key: 'user_id',
      relationship_type: 'one_to_many'
    )
  end

  let(:duplicate_relationship) do
    Gitlab::Reflections::Relationships::Relationship.new(
      parent_table: 'users',
      child_table: 'posts',
      primary_key: 'id',
      foreign_key: 'user_id',
      relationship_type: 'one_to_many'
    )
  end

  let(:polymorphic_relationship) do
    Gitlab::Reflections::Relationships::Relationship.new(
      parent_table: 'users',
      child_table: 'comments',
      primary_key: 'id',
      foreign_key: 'commentable_id',
      relationship_type: 'one_to_many',
      polymorphic_type_value: 'User'
    )
  end

  describe '.call' do
    it 'creates an instance and calls transform' do
      relationships = [relationship1]
      expect(described_class).to receive(:new).with(relationships).and_call_original

      result = described_class.call(relationships)

      expect(result).to eq([relationship1])
    end
  end

  describe '#transform' do
    context 'with no duplicates' do
      it 'returns all relationships unchanged' do
        relationships = [relationship1, relationship2]
        transformer = described_class.new(relationships)

        result = transformer.transform

        expect(result).to match_array([relationship1, relationship2])
      end
    end

    context 'with exact duplicates' do
      it 'removes duplicate relationships keeping only the first occurrence' do
        relationships = [relationship1, duplicate_relationship, relationship2]
        transformer = described_class.new(relationships)

        result = transformer.transform

        expect(result).to match_array([relationship1, relationship2])
      end
    end

    context 'with multiple duplicates' do
      it 'removes all duplicates keeping only the first occurrence' do
        relationships = [relationship1, duplicate_relationship, relationship2, duplicate_relationship]
        transformer = described_class.new(relationships)

        result = transformer.transform

        expect(result).to match_array([relationship1, relationship2])
      end
    end

    context 'with polymorphic relationships' do
      it 'treats polymorphic relationships with different type values as unique' do
        # Same as polymorphic_relationship but with 'Post' instead of 'User' type value
        polymorphic_relationship2 = Gitlab::Reflections::Relationships::Relationship.new(
          parent_table: 'users',
          child_table: 'comments',
          primary_key: 'id',
          foreign_key: 'commentable_id',
          relationship_type: 'one_to_many',
          polymorphic_type_value: 'Post'
        )

        relationships = [polymorphic_relationship, polymorphic_relationship2]
        transformer = described_class.new(relationships)

        result = transformer.transform

        expect(result).to match_array([polymorphic_relationship, polymorphic_relationship2])
      end

      it 'removes duplicates of polymorphic relationships with same type value' do
        duplicate_polymorphic = Gitlab::Reflections::Relationships::Relationship.new(
          parent_table: 'users',
          child_table: 'comments',
          primary_key: 'id',
          foreign_key: 'commentable_id',
          relationship_type: 'one_to_many',
          polymorphic_type_value: 'User'
        )

        relationships = [polymorphic_relationship, duplicate_polymorphic]
        transformer = described_class.new(relationships)

        result = transformer.transform

        expect(result).to match_array([polymorphic_relationship])
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

    context 'with nil polymorphic_type_value' do
      it 'handles nil values in signature generation' do
        rel_with_nil = Gitlab::Reflections::Relationships::Relationship.new(
          parent_table: 'users',
          child_table: 'posts',
          primary_key: 'id',
          foreign_key: 'user_id',
          relationship_type: 'one_to_many'
        )

        relationships = [rel_with_nil, relationship1]
        transformer = described_class.new(relationships)

        result = transformer.transform

        expect(result).to eq([rel_with_nil])
      end
    end
  end

  describe '#relationship_signature' do
    it 'creates unique signatures for different relationships' do
      transformer = described_class.new([])

      sig1 = transformer.send(:relationship_signature, relationship1)
      sig2 = transformer.send(:relationship_signature, relationship2)

      expect(sig1).not_to eq(sig2)
    end

    it 'creates identical signatures for duplicate relationships' do
      transformer = described_class.new([])

      sig1 = transformer.send(:relationship_signature, relationship1)
      sig2 = transformer.send(:relationship_signature, duplicate_relationship)

      expect(sig1).to eq(sig2)
    end

    it 'includes all relevant attributes in the signature' do
      transformer = described_class.new([])

      signature = transformer.send(:relationship_signature, relationship1)

      expect(signature).to include('users')
      expect(signature).to include('posts')
      expect(signature).to include('id')
      expect(signature).to include('user_id')
      expect(signature).to include('one_to_many')
    end

    it 'handles compact operation for nil values' do
      rel_with_nils = Gitlab::Reflections::Relationships::Relationship.new(
        parent_table: 'users',
        child_table: nil,
        primary_key: 'id',
        foreign_key: 'user_id',
        relationship_type: 'one_to_many'
      )

      transformer = described_class.new([])

      expect { transformer.send(:relationship_signature, rel_with_nils) }.not_to raise_error
    end
  end
end
