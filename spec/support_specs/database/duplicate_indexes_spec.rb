# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Database::DuplicateIndexes, feature_category: :database do
  index_class = ActiveRecord::ConnectionAdapters::IndexDefinition
  let(:default_index_options) do
    { using: :btree, orders: {}, unique: false, opclasses: {}, where: nil, include: [] }
  end

  let(:table_name) { 'foobar' }
  let(:index1) { instance_double(index_class, default_index_options.merge(name: 'index1', columns: %w[user_id])) }
  let(:index1_copy) { instance_double(index_class, default_index_options.merge(name: 'index1b', columns: %w[user_id])) }
  let(:index2) { instance_double(index_class, default_index_options.merge(name: 'index2', columns: %w[project_id])) }
  let(:index3) do
    instance_double(index_class, default_index_options.merge(name: 'index3', columns: %w[user_id project_id]))
  end

  let(:index3_inverse) do
    instance_double(index_class, default_index_options.merge(name: 'index3_inverse', columns: %w[project_id user_id]))
  end

  let(:index1_unique) do
    instance_double(index_class, default_index_options.merge(name: 'index1_unique', columns: %w[user_id], unique: true))
  end

  let(:index1_desc) do
    instance_double(
      index_class,
      default_index_options.merge(name: 'index1', columns: %w[user_id], orders: { user_id: 'desc' })
    )
  end

  let(:index3_with_where) do
    instance_double(
      index_class,
      default_index_options.merge(name: 'index3_with_where', columns: %w[user_id project_id], where: "id > 100")
    )
  end

  let(:index1_with_where) do
    instance_double(
      index_class,
      default_index_options.merge(name: 'index1_with_where', columns: %w[user_id], where: "id > 100")
    )
  end

  let(:index1_with_different_where) do
    instance_double(
      index_class,
      default_index_options.merge(name: 'index1_with_different_where', columns: %w[user_id], where: "id > 200")
    )
  end

  let(:primary_key_index) do
    instance_double(index_class, default_index_options.merge(name: 'table_pkey', columns: %w[id], unique: true))
  end

  let(:primary_key_index_copy) do
    instance_double(index_class, default_index_options.merge(name: 'table_pkey_copy', columns: %w[id]))
  end

  let(:primary_key_index_with_extra_columns) do
    instance_double(index_class, default_index_options.merge(name: 'table_pkey_with_user_id', columns: %w[id user_id]))
  end

  subject(:duplicate_indexes) do
    described_class.new(table_name, indexes).duplicate_indexes
  end

  context 'when there are no duplicate indexes' do
    let(:indexes) { [index1, index2] }

    it { expect(duplicate_indexes).to be_empty }
  end

  context 'when overlapping indexes' do
    let(:indexes) { [index1, index3] }

    it 'detects a duplicate index between index1 and index3' do
      expected_duplicate_indexes = { index_struct(index3) => [index_struct(index1)] }

      expect(duplicate_indexes).to eq(expected_duplicate_indexes)
    end
  end

  context 'when the indexes have the inverse order of columns' do
    let(:indexes) { [index3, index3_inverse] }

    it 'does not detect duplicate indexes between index3 and index3_inverse' do
      expect(duplicate_indexes).to eq({})
    end
  end

  # For now we ignore other indexes that are UNIQUE and have a matching columns subset of
  # the btree_index columns, as UNIQUE indexes are still needed to enforce uniqueness
  # constraints on subset of the columns.
  context 'when the index with matching sub-columns is unique' do
    let(:indexes) { [index3, index1_unique] }

    it 'does not detect duplicate indexes between index3 and index1_unique' do
      expect(duplicate_indexes).to eq({})
    end
  end

  context 'when the one of the indexes is a conditional index' do
    let(:indexes) { [index3, index3_with_where] }

    it 'does not detect duplicate indexes between index3 and index3_with_where' do
      expect(duplicate_indexes).to eq({})
    end
  end

  context 'when both indexes have the same WHERE clause' do
    let(:indexes) { [index3_with_where, index1_with_where] }

    it 'detects a duplicate index between index3_with_where and index1_with_where' do
      expected_duplicate_indexes = { index_struct(index3_with_where) => [index_struct(index1_with_where)] }

      expect(duplicate_indexes).to eq(expected_duplicate_indexes)
    end
  end

  context 'when indexes have the same columns but different WHERE clauses' do
    let(:indexes) { [index1_with_where, index1_with_different_where] }

    it 'does not detect duplicate indexes' do
      expect(duplicate_indexes).to eq({})
    end
  end

  context 'when identical indexes' do
    let(:indexes) { [index1, index1_copy] }

    it 'detects a duplicate index between index1 and index3' do
      expected_duplicate_indexes = {
        index_struct(index1) => [index_struct(index1_copy)],
        index_struct(index1_copy) => [index_struct(index1)]
      }

      expect(duplicate_indexes).to eq(expected_duplicate_indexes)
    end
  end

  context 'when indexes have the same columns but with different order' do
    let(:indexes) { [index1, index1_desc] }

    it { expect(duplicate_indexes).to be_empty }
  end

  context 'with a copy of the primary key index' do
    let(:indexes) { [primary_key_index, primary_key_index_copy] }

    it 'detects duplicate indexes' do
      expected_duplicate_indexes = {
        index_struct(primary_key_index) => [index_struct(primary_key_index_copy)],
        index_struct(primary_key_index_copy) => [index_struct(primary_key_index)]
      }

      expect(duplicate_indexes).to eq(expected_duplicate_indexes)
    end
  end

  context 'with a copy of primary key index with extra columns' do
    let(:indexes) { [primary_key_index, primary_key_index_with_extra_columns] }

    it { is_expected.to be_empty }
  end

  def index_struct(index)
    Database::DuplicateIndexes.btree_index_struct(index)
  end
end
