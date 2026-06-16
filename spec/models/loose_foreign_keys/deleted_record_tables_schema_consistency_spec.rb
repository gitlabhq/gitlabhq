# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Loose Foreign Keys deleted record tables schema consistency', feature_category: :database do
  # Columns that differ by design across the tables:
  # - sharding key columns: each table has exactly one (organization_id, namespace_id, etc.)
  # - id: the base table uses bigint (with a sequence) while the sharding key tables
  #   use uuid (gitlab_shared_org tables cannot have auto-incrementing sequences)
  let(:excluded_columns) { %w[id organization_id namespace_id project_id user_id] }

  let(:base_model) { LooseForeignKeys::DeletedRecord }

  let(:sharding_key_models) do
    [
      LooseForeignKeys::OrganizationDeletedRecord,
      LooseForeignKeys::NamespaceDeletedRecord,
      LooseForeignKeys::ProjectDeletedRecord,
      LooseForeignKeys::UserDeletedRecord
    ]
  end

  def shared_columns_for(model)
    model.columns
      .reject { |col| excluded_columns.include?(col.name) }
      .to_h { |col| [col.name, col.sql_type] }
  end

  it 'all tables have identical shared columns and types (excluding id and sharding key)' do
    reference = shared_columns_for(base_model)

    (sharding_key_models + [base_model]).each do |model|
      expect(shared_columns_for(model)).to(
        eq(reference), "#{model.table_name} schema diverges from #{base_model.table_name}"
      )
    end
  end

  it 'sharding key tables use uuid for the id column' do
    sharding_key_models.each do |model|
      id_column = model.columns.find { |col| col.name == 'id' }

      expect(id_column.sql_type).to(
        eq('uuid'), "#{model.table_name} id column should be uuid, got #{id_column.sql_type}"
      )
    end
  end

  it 'base table uses bigint for the id column' do
    id_column = base_model.columns.find { |col| col.name == 'id' }

    expect(id_column.sql_type).to eq('bigint')
  end
end
