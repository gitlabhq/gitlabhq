# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::Reflections::Relationships::Relationship, feature_category: :database do
  describe 'validations' do
    context 'for required attributes' do
      it 'requires parent_table' do
        relationship = described_class.new(child_table: 'posts', foreign_key: 'user_id')
        expect(relationship).not_to be_valid
        expect(relationship.errors[:parent_table]).to include("can't be blank")
      end

      it 'requires foreign_key' do
        relationship = described_class.new(parent_table: 'users', child_table: 'posts')
        expect(relationship).not_to be_valid
        expect(relationship.errors[:foreign_key]).to include("can't be blank")
      end

      it 'requires child_table for non-polymorphic relationships' do
        relationship = described_class.new(parent_table: 'users', foreign_key: 'user_id')
        expect(relationship).not_to be_valid
        expect(relationship.errors[:child_table]).to include("can't be blank")
      end
    end

    it 'does not require child_table for polymorphic relationships' do
      relationship = described_class.new(
        parent_table: 'users',
        foreign_key: 'commentable_id',
        polymorphic: true
      )
      expect(relationship).to be_valid
    end

    context 'for polymorphic belongs_to' do
      let(:base_attributes) do
        {
          foreign_key: 'commentable_id',
          polymorphic: true,
          relationship_type: 'many_to_one'
        }
      end

      it 'requires child_table but not parent_table' do
        relationship = described_class.new(
          base_attributes.merge(child_table: 'comments')
        )
        expect(relationship).to be_valid
      end

      it 'is invalid without child_table' do
        relationship = described_class.new(
          base_attributes.merge(parent_table: 'users')
        )
        expect(relationship).not_to be_valid
        expect(relationship.errors[:child_table]).to include("can't be blank")
      end

      it 'is valid with both parent_table and child_table' do
        relationship = described_class.new(
          base_attributes.merge(parent_table: 'users', child_table: 'comments')
        )
        expect(relationship).to be_valid
      end
    end

    context 'for polymorphic has_many/has_one' do
      let(:base_attributes) do
        {
          foreign_key: 'imageable_id',
          polymorphic: true,
          relationship_type: 'one_to_many'
        }
      end

      it 'requires parent_table but not child_table' do
        relationship = described_class.new(
          base_attributes.merge(parent_table: 'users')
        )
        expect(relationship).to be_valid
      end

      it 'is invalid without parent_table' do
        relationship = described_class.new(
          base_attributes.merge(child_table: 'images')
        )
        expect(relationship).not_to be_valid
        expect(relationship.errors[:parent_table]).to include("can't be blank")
      end

      it 'is valid with both parent_table and child_table' do
        relationship = described_class.new(
          base_attributes.merge(parent_table: 'users', child_table: 'images')
        )
        expect(relationship).to be_valid
      end
    end
  end

  describe 'attributes' do
    let(:relationship) do
      described_class.new(
        parent_table: 'users',
        child_table: 'posts',
        foreign_key: 'user_id',
        primary_key: 'id',
        relationship_type: 'one_to_many'
      )
    end

    it 'has core table relationship attributes' do
      expect(relationship.parent_table).to eq('users')
      expect(relationship.child_table).to eq('posts')
      expect(relationship.foreign_key).to eq('user_id')
      expect(relationship.primary_key).to eq('id')
      expect(relationship.relationship_type).to eq('one_to_many')
    end

    context 'for default values' do
      it 'defaults primary_key to "id"' do
        relationship = described_class.new
        expect(relationship.primary_key).to eq('id')
      end

      it 'defaults boolean attributes to false' do
        relationship = described_class.new(parent_table: 'users', child_table: 'posts', foreign_key: 'user_id')

        expect(relationship.polymorphic).to be(false)
        expect(relationship.is_through_association).to be(false)
      end
    end
  end

  describe 'relationship_type enum' do
    it 'accepts valid relationship types' do
      %w[one_to_one one_to_many many_to_one many_to_many].each do |type|
        relationship = described_class.new(
          parent_table: 'users',
          child_table: 'posts',
          foreign_key: 'user_id',
          relationship_type: type
        )
        expect(relationship.relationship_type).to eq(type)
      end
    end
  end

  describe '#polymorphic?' do
    let(:base_attributes) do
      {
        parent_table: 'users',
        child_table: 'posts',
        foreign_key: 'user_id'
      }
    end

    it 'returns true when polymorphic is true' do
      relationship = described_class.new(
        base_attributes.merge(
          foreign_key: 'commentable_id',
          polymorphic: true
        )
      )
      expect(relationship.polymorphic?).to be(true)
    end

    it 'returns false when polymorphic is false' do
      relationship = described_class.new(
        base_attributes.merge(polymorphic: false)
      )
      expect(relationship.polymorphic?).to be(false)
    end

    it 'returns false by default' do
      relationship = described_class.new(base_attributes)
      expect(relationship.polymorphic?).to be(false)
    end
  end

  describe '#to_h' do
    it 'returns a hash of compacted attributes' do
      relationship = described_class.new(
        parent_table: 'users',
        child_table: 'posts',
        foreign_key: 'user_id',
        primary_key: 'id',
        parent_association: { name: 'posts', type: 'has_many', model: 'User' },
        polymorphic: false,
        through_table: nil # explicitly nil to test compaction
      )

      hash = relationship.to_h

      expect(hash).to eq(
        parent_table: 'users',
        child_table: 'posts',
        foreign_key: 'user_id',
        primary_key: 'id',
        parent_association: { name: 'posts', type: 'has_many', model: 'User' },
        polymorphic: false,
        is_through_association: false
      )
    end
  end

  describe '#to_json' do
    it 'returns JSON representation' do
      relationship = described_class.new(
        parent_table: 'users',
        child_table: 'posts',
        foreign_key: 'user_id'
      )

      json = Gitlab::Json.parse(relationship.to_json)

      expect(json['parent_table']).to eq('users')
      expect(json['child_table']).to eq('posts')
      expect(json['foreign_key']).to eq('user_id')
    end
  end

  describe 'association validation' do
    let(:base_attributes) do
      {
        parent_table: 'users',
        child_table: 'posts',
        foreign_key: 'user_id'
      }
    end

    it 'validates parent association structure' do
      relationship = described_class.new(
        base_attributes.merge(
          parent_association: { name: '', type: 'has_many', model: 'User' }
        )
      )

      expect(relationship).not_to be_valid
      expect(relationship.errors[:parent_association]).to include('name cannot be blank')
    end

    it 'validates child association structure' do
      relationship = described_class.new(
        base_attributes.merge(
          child_association: { name: 'user', type: '', model: 'Post' }
        )
      )

      expect(relationship).not_to be_valid
      expect(relationship.errors[:child_association]).to include('type cannot be blank')
    end

    it 'allows nil associations' do
      relationship = described_class.new(
        base_attributes.merge(
          parent_association: nil,
          child_association: nil
        )
      )

      expect(relationship).to be_valid
    end

    it 'validates association must be a hash' do
      relationship = described_class.new(
        base_attributes.merge(parent_association: 'invalid')
      )

      expect(relationship).not_to be_valid
      expect(relationship.errors[:parent_association]).to include('must be a hash')
    end
  end
end
