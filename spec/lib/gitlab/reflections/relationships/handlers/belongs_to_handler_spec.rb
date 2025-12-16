# frozen_string_literal: true

require 'fast_spec_helper'

RSpec.describe Gitlab::Reflections::Relationships::Handlers::BelongsToHandler, feature_category: :database do
  # rubocop:disable RSpec/VerifiedDoubles -- Using generic mock objects
  let(:model) { double('Model', table_name: 'posts', name: 'Post') }
  let(:association_name) { :user }
  let(:reflection) do
    double('Reflection',
      macro: :belongs_to,
      klass: double('Klass', table_name: 'users'),
      foreign_key: 'user_id',
      association_primary_key: 'id'
    )
  end
  # rubocop:enable RSpec/VerifiedDoubles

  subject(:handler) { described_class.new(model, association_name, reflection) }

  describe '#build_relationships' do
    it 'creates belongs_to relationship' do
      relationships = handler.build_relationships

      expect(relationships.size).to eq(1)
      relationship = relationships.first

      expect(relationship).to have_attributes(
        parent_table: 'users',
        child_table: 'posts',
        foreign_key: 'user_id',
        primary_key: 'id',
        relationship_type: 'many_to_one'
      )
    end

    it 'includes child association metadata' do
      relationships = handler.build_relationships
      relationship = relationships.first

      expect(relationship.child_association).to eq({
        name: 'user',
        type: 'belongs_to',
        model: 'Post'
      })
    end

    it 'sets foreign key' do
      allow(reflection).to receive(:foreign_key).and_return('author_id')

      relationships = handler.build_relationships
      relationship = relationships.first

      expect(relationship.foreign_key).to eq('author_id')
    end

    it 'handles standard belongs_to association' do
      # belongs_to :user
      relationships = handler.build_relationships

      expect(relationships.size).to eq(1)
      expect(relationships.first).to have_attributes(
        parent_table: 'users',
        child_table: 'posts'
      )
    end

    it 'handles belongs_to with custom class_name' do
      # belongs_to :author, class_name: 'User'
      # rubocop:disable RSpec/VerifiedDoubles -- Using generic mock objects
      allow(reflection).to receive(:klass).and_return(double('Klass', table_name: 'users'))
      # rubocop:enable RSpec/VerifiedDoubles

      relationships = handler.build_relationships

      expect(relationships.first.parent_table).to eq('users')
    end

    it 'handles belongs_to with custom foreign_key' do
      # belongs_to :project, foreign_key: 'project_uuid'
      allow(reflection).to receive(:foreign_key).and_return('project_uuid_id')

      relationships = handler.build_relationships

      expect(relationships.first.foreign_key).to eq('project_uuid_id')
    end
  end
end
