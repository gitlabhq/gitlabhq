# frozen_string_literal: true

require 'spec_helper'
require_migration!

RSpec.describe SyncFkReferencingPCiPipelines, migration: :gitlab_ci, feature_category: :continuous_integration do
  let(:all_tmp_fk_names) do
    (described_class::FOREIGN_KEYS + described_class::P_FOREIGN_KEYS).pluck(:name)
  end

  let(:all_fk_names) do
    all_tmp_fk_names.map { |name| name.to_s.gsub('_tmp', '') }
  end

  it 'validates and renames the fks' do
    reversible_migration do |migration|
      migration.before -> {
        expect(fk_count_for(:p_ci_pipelines, all_tmp_fk_names, is_valid: false)).to eq(16)
        expect(fk_count_for(:p_ci_pipelines, all_fk_names)).to eq(0)
        expect(fk_count_for(:ci_pipelines, all_fk_names)).to eq(16)
      }
      migration.after -> {
        expect(fk_count_for(:p_ci_pipelines, all_tmp_fk_names, is_valid: false)).to eq(0)
        expect(fk_count_for(:p_ci_pipelines, all_fk_names)).to eq(16)
        expect(fk_count_for(:ci_pipelines, all_fk_names)).to eq(0)
      }
    end
  end

  private

  def fk_count_for(referenced_table, names, is_valid: true)
    Gitlab::Database::PostgresForeignKey
      .by_referenced_table_name(referenced_table)
      .where(name: names)
      .where(is_valid: is_valid)
      .count('DISTINCT name')
  end
end
