# frozen_string_literal: true

require 'fast_spec_helper'

RSpec.describe Gitlab::Reflections::Relationships::Handlers::PolymorphicBelongsToHandler, feature_category: :database do
  # rubocop:disable RSpec/VerifiedDoubles -- Using generic mock objects
  let(:model) { double('Model', table_name: 'comments', name: 'Comment', primary_key: 'id') }
  let(:association_name) { :commentable }
  let(:reflection) do
    double('Reflection',
      macro: :belongs_to,
      name: :commentable,
      foreign_key: 'commentable_id',
      foreign_type: 'commentable_type',
      association_primary_key: 'id'
    )
  end
  # rubocop:enable RSpec/VerifiedDoubles

  subject(:handler) { described_class.new(model, association_name, reflection) }

  describe '#build_relationships' do
    it 'creates polymorphic belongs_to relationship' do
      relationships = handler.build_relationships

      expect(relationships.size).to eq(1)
      relationship = relationships.first

      expect(relationship).to have_attributes(
        parent_table: nil,
        child_table: 'comments',
        foreign_key: 'commentable_id',
        primary_key: 'id',
        relationship_type: 'many_to_one',
        polymorphic: true,
        polymorphic_type_column: 'commentable_type',
        polymorphic_name: 'commentable'
      )
    end

    it 'includes child association metadata' do
      relationships = handler.build_relationships
      relationship = relationships.first

      expect(relationship.child_association).to eq({
        name: 'commentable',
        type: 'belongs_to',
        model: 'Comment'
      })
    end

    it 'handles polymorphic belongs_to association' do
      # belongs_to :commentable, polymorphic: true
      relationships = handler.build_relationships

      expect(relationships.size).to eq(1)
      relationship = relationships.first
      expect(relationship).to have_attributes(
        polymorphic: true,
        polymorphic_name: 'commentable'
      )
    end

    it 'handles polymorphic belongs_to with custom foreign_key' do
      # belongs_to :imageable, polymorphic: true, foreign_key: 'image_id'
      allow(reflection).to receive_messages(
        foreign_key: 'image_id',
        foreign_type: 'image_type',
        name: :imageable
      )

      relationships = handler.build_relationships
      relationship = relationships.first

      expect(relationship).to have_attributes(
        foreign_key: 'image_id',
        polymorphic_type_column: 'image_type',
        polymorphic_name: 'imageable'
      )
    end
  end
end
