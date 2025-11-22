# frozen_string_literal: true

require 'fast_spec_helper'

RSpec.describe Gitlab::Reflections::Relationships::Handlers::ThroughAssociationHandler, feature_category: :database do
  # rubocop:disable RSpec/VerifiedDoubles -- Using generic mock objects
  let(:model) { double('Model', table_name: 'users', name: 'User') }
  let(:association_name) { :comments }
  let(:through_reflection) do
    double('ThroughReflection',
      macro: :has_many,
      foreign_key: 'user_id',
      table_name: 'posts'
    )
  end

  let(:source_reflection) do
    double('SourceReflection',
      foreign_key: 'post_id'
    )
  end

  let(:reflection) do
    double('Reflection',
      macro: :has_many,
      klass: double('Klass', table_name: 'comments'),
      active_record_primary_key: 'id',
      through_reflection: through_reflection,
      source_reflection: source_reflection
    )
  end
  # rubocop:enable RSpec/VerifiedDoubles

  subject(:handler) { described_class.new(model, association_name, reflection) }

  describe '#build_relationships' do
    it 'creates through association relationship' do
      relationships = handler.build_relationships

      expect(relationships.size).to eq(1)
      relationship = relationships.first

      expect(relationship).to have_attributes(
        parent_table: 'users',
        child_table: 'comments',
        foreign_key: 'user_id',
        primary_key: 'id',
        relationship_type: 'one_to_many',
        through_table: 'posts',
        through_target_key: 'post_id',
        is_through_association: true
      )
    end

    it 'includes parent association metadata' do
      relationships = handler.build_relationships
      relationship = relationships.first

      expect(relationship.parent_association).to eq({
        name: 'comments',
        type: 'has_many',
        model: 'User'
      })
    end

    it 'handles habtm through association' do
      allow(through_reflection).to receive_messages(macro: :has_and_belongs_to_many, join_table: 'users_posts')

      relationships = handler.build_relationships
      relationship = relationships.first

      expect(relationship.through_table).to eq('users_posts')
    end

    it 'handles has_many through association' do
      # has_many :comments, through: :posts
      relationships = handler.build_relationships

      expect(relationships.size).to eq(1)
      relationship = relationships.first
      expect(relationship).to have_attributes(
        is_through_association: true,
        through_table: 'posts'
      )
    end

    it 'handles has_one through association' do
      # has_one :profile, through: :user
      # rubocop:disable RSpec/VerifiedDoubles -- Using generic mock objects
      allow(reflection).to receive_messages(macro: :has_one, klass: double('Klass', table_name: 'profiles'))
      # rubocop:enable RSpec/VerifiedDoubles

      relationships = handler.build_relationships
      relationship = relationships.first

      expect(relationship).to have_attributes(
        relationship_type: 'one_to_one',
        child_table: 'profiles'
      )
    end

    it 'handles through habtm association' do
      # has_many :users, through: :some_habtm_relation
      allow(through_reflection).to receive_messages(macro: :has_and_belongs_to_many, join_table: 'project_users')

      relationships = handler.build_relationships
      relationship = relationships.first

      expect(relationship.through_table).to eq('project_users')
    end

    context 'when through_reflection is nil' do
      it 'handles missing through_reflection gracefully' do
        allow(reflection).to receive(:through_reflection).and_return(nil)

        relationships = handler.build_relationships

        expect(relationships).to eq([])
      end
    end

    context 'when source_reflection is nil' do
      it 'handles missing source_reflection gracefully' do
        allow(reflection).to receive(:source_reflection).and_return(nil)

        relationships = handler.build_relationships
        relationship = relationships.first

        expect(relationship.through_target_key).to be_nil
      end
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
