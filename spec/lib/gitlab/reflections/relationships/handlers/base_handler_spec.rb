# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::Reflections::Relationships::Handlers::BaseHandler, feature_category: :database do
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

  describe '#initialize' do
    it 'sets model, association_name, and reflection' do
      expect(handler.model).to eq(model)
      expect(handler.association_name).to eq(association_name)
      expect(handler.reflection).to eq(reflection)
    end
  end

  describe '#build_relationships' do
    it 'returns array with single relationship for non-polymorphic associations' do
      allow(handler).to receive(:relationship_attributes).and_return({
        parent_table: 'users',
        child_table: 'posts',
        foreign_key: 'user_id'
      })

      relationships = handler.build_relationships

      expect(relationships).to be_an(Array)
      expect(relationships.size).to eq(1)
      expect(relationships.first).to be_a(Gitlab::Reflections::Relationships::Relationship)
    end

    it 'returns empty array when required fields are missing' do
      allow(handler).to receive(:relationship_attributes).and_return({
        parent_table: 'users',
        child_table: nil,
        foreign_key: 'user_id'
      })

      relationships = handler.build_relationships

      expect(relationships).to eq([])
    end

    it 'returns empty array when target class does not exist' do
      allow(reflection).to receive(:klass).and_raise(NameError, "uninitialized constant Admin::AbuseReportAssignee")

      relationships = handler.build_relationships

      expect(relationships).to eq([])
    end
  end

  describe '#relationship_type' do
    it 'raises NotImplementedError with class name' do
      expect { handler.send(:relationship_type) }.to raise_error(
        NotImplementedError,
        "Gitlab::Reflections::Relationships::Handlers::BaseHandler must implement #relationship_type"
      )
    end
  end
end
