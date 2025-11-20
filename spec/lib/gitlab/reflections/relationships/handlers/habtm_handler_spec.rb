# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::Reflections::Relationships::Handlers::HabtmHandler, feature_category: :database do
  # rubocop:disable RSpec/VerifiedDoubles -- Using generic mock objects
  let(:model) { double('Model', table_name: 'users', name: 'User') }
  let(:association_name) { :tags }
  let(:reflection) do
    double('Reflection',
      macro: :has_and_belongs_to_many,
      klass: double('Klass', table_name: 'tags'),
      join_table: 'tags_users',
      foreign_key: 'user_id',
      active_record_primary_key: 'id'
    )
  end
  # rubocop:enable RSpec/VerifiedDoubles

  subject(:handler) { described_class.new(model, association_name, reflection) }

  describe '#build_relationships' do
    it 'creates habtm relationship' do
      relationships = handler.build_relationships

      expect(relationships.size).to eq(1)
      relationship = relationships.first

      expect(relationship).to have_attributes(
        parent_table: 'users',
        child_table: 'tags',
        foreign_key: 'user_id',
        primary_key: 'id',
        relationship_type: 'many_to_many',
        through_table: 'tags_users'
      )
    end

    it 'includes parent association metadata' do
      relationships = handler.build_relationships
      relationship = relationships.first

      expect(relationship.parent_association).to eq({
        name: 'tags',
        type: 'has_and_belongs_to_many',
        model: 'User'
      })
    end

    it 'handles standard habtm association' do
      # has_and_belongs_to_many :tags
      relationships = handler.build_relationships

      expect(relationships.size).to eq(1)
      relationship = relationships.first
      expect(relationship).to have_attributes(
        relationship_type: 'many_to_many',
        through_table: 'tags_users'
      )
    end

    it 'handles habtm with custom join_table' do
      # has_and_belongs_to_many :users, join_table: 'project_users'
      # rubocop:disable RSpec/VerifiedDoubles -- Using generic mock objects
      allow(reflection).to receive_messages(
        join_table: 'project_users',
        klass: double('Klass', table_name: 'users')
      )
      # rubocop:enable RSpec/VerifiedDoubles

      relationships = handler.build_relationships
      relationship = relationships.first

      expect(relationship).to have_attributes(
        through_table: 'project_users',
        child_table: 'users'
      )
    end
  end
end
