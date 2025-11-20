# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::Reflections::Relationships::Handlers::ActiveStorageHandler, feature_category: :database do
  # rubocop:disable RSpec/VerifiedDoubles -- Using generic mock objects
  let(:model) { double('Model', table_name: 'users', name: 'User') }
  let(:association_name) { :images }
  let(:reflection) do
    double('Reflection',
      macro: reflection_macro,
      klass: double('Klass', table_name: 'active_storage_attachments')
    )
  end
  # rubocop:enable RSpec/VerifiedDoubles

  subject(:handler) { described_class.new(model, association_name, reflection) }

  describe '#build_relationships' do
    context 'with has_many_attached association' do
      let(:reflection_macro) { :has_many_attached }

      it 'creates Active Storage relationship' do
        relationships = handler.build_relationships

        expect(relationships.size).to eq(1)
        relationship = relationships.first

        expect(relationship).to have_attributes(
          parent_table: 'users',
          child_table: 'active_storage_attachments',
          foreign_key: 'record_id',
          relationship_type: 'one_to_many',
          parent_association: {
            name: 'images',
            type: 'has_many_attached',
            model: 'User'
          }
        )
      end
    end

    context 'with has_one_attached association' do
      let(:reflection_macro) { :has_one_attached }

      it 'creates Active Storage relationship' do
        relationships = handler.build_relationships

        expect(relationships.size).to eq(1)
        relationship = relationships.first

        expect(relationship).to have_attributes(
          parent_table: 'users',
          child_table: 'active_storage_attachments',
          foreign_key: 'record_id',
          relationship_type: 'one_to_one',
          parent_association: {
            name: 'images',
            type: 'has_one_attached',
            model: 'User'
          }
        )
      end
    end

    context 'with unsupported macro' do
      let(:reflection_macro) { :belongs_to }

      it 'returns nil for relationship_type' do
        relationships = handler.build_relationships
        relationship = relationships.first

        expect(relationship.relationship_type).to be_nil
      end
    end
  end
end
