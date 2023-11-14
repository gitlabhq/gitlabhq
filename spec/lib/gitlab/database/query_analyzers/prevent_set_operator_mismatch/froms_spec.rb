# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::Database::QueryAnalyzers::PreventSetOperatorMismatch::Froms,
  feature_category: :cell do
  include PreventSetOperatorMismatchHelper

  describe '.references' do
    let(:node) { sql_select_node(sql) }
    let(:cte_refs) { {} }

    subject { described_class.references(node, cte_refs) }

    context 'when node is nil' do
      let(:node) { nil }

      it { is_expected.to eq({}) }
    end

    context 'when range_var' do
      let(:sql) { 'SELECT 1 FROM namespaces' }

      it { is_expected.to match({ 'namespaces' => an_instance_of(PgQuery::RangeVar) }) }
    end

    context 'when range_var with alias' do
      let(:sql) { 'SELECT 1 FROM namespaces ns' }

      it { is_expected.to match({ 'ns' => an_instance_of(PgQuery::RangeVar) }) }
    end

    context 'when join expression' do
      let(:sql) do
        <<-SQL
          SELECT 1 FROM namespaces
          INNER JOIN organizations ON namespaces.organization_id = organization.id
        SQL
      end

      it do
        is_expected.to match({
          'namespaces' => an_instance_of(PgQuery::RangeVar),
          'organizations' => an_instance_of(PgQuery::RangeVar)
        })
      end
    end

    context 'when join expression with alias' do
      let(:sql) do
        <<-SQL
          SELECT 1 FROM namespaces ns
          INNER JOIN organizations o ON ns.organization_id = o.id
        SQL
      end

      it do
        is_expected.to match({
          'ns' => an_instance_of(PgQuery::RangeVar),
          'o' => an_instance_of(PgQuery::RangeVar)
        })
      end
    end

    context 'when sub-query' do
      let(:sql) do
        <<-SQL
          SELECT 1
          FROM (SELECT 1) some_subquery
        SQL
      end

      it { is_expected.to match({ 'some_subquery' => [Type::STATIC].to_set }) }
    end
  end
end
