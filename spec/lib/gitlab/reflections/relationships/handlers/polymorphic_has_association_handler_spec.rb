# frozen_string_literal: true

require 'fast_spec_helper'

RSpec.describe Gitlab::Reflections::Relationships::Handlers::PolymorphicHasAssociationHandler, feature_category: :database do
  # rubocop:disable RSpec/VerifiedDoubles -- Using generic mock objects
  let(:model) { double('Model', table_name: 'posts', name: 'Post') }
  let(:association_name) { :comments }
  let(:reflection) do
    double('Reflection',
      macro: :has_many,
      options: { as: :commentable },
      active_record_primary_key: 'id'
    )
  end
  # rubocop:enable RSpec/VerifiedDoubles

  subject(:handler) { described_class.new(model, association_name, reflection) }

  describe '#build_relationships' do
    it 'creates polymorphic has_many relationship' do
      relationships = handler.build_relationships

      expect(relationships.size).to eq(1)
      relationship = relationships.first

      expect(relationship).to have_attributes(
        parent_table: 'posts',
        child_table: nil,
        foreign_key: 'commentable_id',
        primary_key: 'id',
        relationship_type: 'one_to_many',
        polymorphic: true,
        polymorphic_type_column: 'commentable_type',
        polymorphic_name: 'commentable'
      )
    end

    it 'includes parent association metadata' do
      relationships = handler.build_relationships
      relationship = relationships.first

      expect(relationship.parent_association).to eq({
        name: 'comments',
        type: 'has_many',
        model: 'Post'
      })
    end

    it 'handles has_one polymorphic association' do
      allow(reflection).to receive_messages(macro: :has_one, options: { as: :imageable })

      relationships = handler.build_relationships
      relationship = relationships.first

      expect(relationship).to have_attributes(
        relationship_type: 'one_to_one',
        foreign_key: 'imageable_id',
        polymorphic_type_column: 'imageable_type',
        polymorphic_name: 'imageable'
      )
    end

    it 'handles polymorphic has_many association' do
      # has_many :comments, as: :commentable
      relationships = handler.build_relationships

      expect(relationships.size).to eq(1)
      relationship = relationships.first
      expect(relationship).to have_attributes(
        polymorphic: true,
        polymorphic_name: 'commentable',
        relationship_type: 'one_to_many'
      )
    end

    it 'handles polymorphic has_one association' do
      # has_one :image, as: :imageable
      allow(reflection).to receive_messages(macro: :has_one, options: { as: :imageable })

      relationships = handler.build_relationships
      relationship = relationships.first

      expect(relationship).to have_attributes(
        relationship_type: 'one_to_one',
        polymorphic_name: 'imageable'
      )
    end

    context 'with unsupported macro' do
      it 'returns nil relationship_type when macro is not has_many or has_one' do
        allow(reflection).to receive(:macro).and_return(:belongs_to)

        relationships = handler.build_relationships
        relationship = relationships.first

        expect(relationship.relationship_type).to be_nil
      end
    end
  end
end
