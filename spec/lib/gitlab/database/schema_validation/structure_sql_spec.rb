# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::Database::SchemaValidation::StructureSql, feature_category: :database do
  let(:structure_file_path) { Rails.root.join('spec/fixtures/structure.sql') }

  subject(:structure_sql) { described_class.new(structure_file_path) }

  describe '#index_exists?' do
    subject(:index_exists) { structure_sql.index_exists?(index_name) }

    context 'when the index does not exist' do
      let(:index_name) { 'non-existent-index' }

      it 'returns false' do
        expect(index_exists).to be_falsey
      end
    end

    context 'when the index exists' do
      let(:index_name) { 'index' }

      it 'returns true' do
        expect(index_exists).to be_truthy
      end
    end
  end

  describe '#indexes' do
    it 'returns indexes' do
      indexes = structure_sql.indexes

      expected_indexes = %w[
        missing_index
        wrong_index
        index
        index_namespaces_public_groups_name_id
        index_on_deploy_keys_id_and_type_and_public
        index_users_on_public_email_excluding_null_and_empty
      ]

      expect(indexes).to all(be_a(Gitlab::Database::SchemaValidation::Index))
      expect(indexes.map(&:name)).to eq(expected_indexes)
    end
  end
end
