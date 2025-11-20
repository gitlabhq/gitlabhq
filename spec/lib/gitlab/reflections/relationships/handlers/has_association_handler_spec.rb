# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::Reflections::Relationships::Handlers::HasAssociationHandler, feature_category: :database do
  # rubocop:disable RSpec/VerifiedDoubles -- Using generic mock objects
  let(:model) { double('Model', table_name: 'users', name: 'User') }
  let(:association_name) { :posts }
  let(:reflection) do
    double('Reflection',
      macro: :has_many,
      klass: double('Klass', table_name: 'posts'),
      foreign_key: 'user_id',
      active_record_primary_key: 'id'
    )
  end
  # rubocop:enable RSpec/VerifiedDoubles

  subject(:handler) { described_class.new(model, association_name, reflection) }

  describe '#build_relationships' do
    it 'creates has_many relationship' do
      relationships = handler.build_relationships

      expect(relationships.size).to eq(1)
      relationship = relationships.first

      expect(relationship).to have_attributes(
        parent_table: 'users',
        child_table: 'posts',
        foreign_key: 'user_id',
        primary_key: 'id',
        relationship_type: 'one_to_many'
      )
    end

    it 'includes parent association metadata' do
      relationships = handler.build_relationships
      relationship = relationships.first

      expect(relationship.parent_association).to eq({
        name: 'posts',
        type: 'has_many',
        model: 'User'
      })
    end

    it 'handles standard has_many association' do
      # has_many :posts
      relationships = handler.build_relationships

      expect(relationships.size).to eq(1)
      expect(relationships.first.relationship_type).to eq('one_to_many')
    end

    it 'handles has_one association' do
      # has_one :profile
      # rubocop:disable RSpec/VerifiedDoubles -- Using generic mock objects
      allow(reflection).to receive_messages(
        macro: :has_one,
        klass: double('Klass', table_name: 'profiles')
      )
      # rubocop:enable RSpec/VerifiedDoubles

      relationships = handler.build_relationships

      expect(relationships.first).to have_attributes(
        relationship_type: 'one_to_one',
        child_table: 'profiles'
      )
    end

    it 'handles has_many with custom foreign_key' do
      # has_many :comments, foreign_key: 'author_id'
      # rubocop:disable RSpec/VerifiedDoubles -- Using generic mock objects
      allow(reflection).to receive_messages(
        foreign_key: 'author_id',
        klass: double('Klass', table_name: 'comments')
      )
      # rubocop:enable RSpec/VerifiedDoubles

      relationships = handler.build_relationships

      expect(relationships.first).to have_attributes(
        foreign_key: 'author_id',
        child_table: 'comments'
      )
    end

    context 'with unsupported macro' do
      it 'returns nil relationship_type when macro is not has_many or has_one' do # -- Using generic mock objects
        allow(reflection).to receive(:macro).and_return(:belongs_to)
        relationships = handler.build_relationships
        relationship = relationships.first

        expect(relationship.relationship_type).to be_nil
      end
    end
  end
end
