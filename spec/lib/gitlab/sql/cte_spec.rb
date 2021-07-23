# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::SQL::CTE do
  describe '#to_arel' do
    it 'generates an Arel relation for the CTE body' do
      relation = User.where(id: 1)
      cte = described_class.new(:cte_name, relation)
      sql = cte.to_arel.to_sql
      name = ApplicationRecord.connection.quote_table_name(:cte_name)

      sql1 = ApplicationRecord.connection.unprepared_statement do
        relation.except(:order).to_sql
      end

      expected = [
        "#{name} AS ",
        Gitlab::Database::AsWithMaterialized.materialized_if_supported,
        (' ' unless Gitlab::Database::AsWithMaterialized.materialized_if_supported.blank?),
        "(#{sql1})"
      ].join

      expect(sql).to eq(expected)
    end
  end

  describe '#alias_to' do
    it 'returns an alias for the CTE' do
      cte = described_class.new(:cte_name, nil)
      table = Arel::Table.new(:kittens)

      source_name = ApplicationRecord.connection.quote_table_name(:cte_name)
      alias_name = ApplicationRecord.connection.quote_table_name(:kittens)

      expect(cte.alias_to(table).to_sql).to eq("#{source_name} AS #{alias_name}")
    end
  end

  describe '#apply_to' do
    it 'applies a CTE to an ActiveRecord::Relation' do
      user = create(:user)
      cte = described_class.new(:cte_name, User.where(id: user.id))

      relation = cte.apply_to(User.all)

      expect(relation.to_sql).to match(/WITH .+cte_name/)
      expect(relation.to_a).to eq(User.where(id: user.id).to_a)
    end
  end

  it_behaves_like 'CTE with MATERIALIZED keyword examples' do
    let(:expected_query_block_with_materialized) { 'WITH "some_cte" AS MATERIALIZED (' }
    let(:expected_query_block_without_materialized) { 'WITH "some_cte" AS (' }

    let(:query) do
      cte = described_class.new(:some_cte, User.active, **options)

      User.with(cte.to_arel).to_sql
    end
  end
end
