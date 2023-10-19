# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::Database::QueryAnalyzers::PreventSetOperatorMismatch::Columns,
  feature_category: :cell do
  include PreventSetOperatorMismatchHelper

  let_it_be(:namespace_columns) { Namespace.column_names.join(',') }

  describe '.types' do
    let(:node) { sql_select_node(sql) }
    let(:cte_refs) { {} }
    let(:select_stmt) do
      Gitlab::Database::QueryAnalyzers::PreventSetOperatorMismatch::SelectStmt.new(node, cte_refs)
    end

    subject { described_class.types(select_stmt) }

    context 'when static column' do
      let(:sql) { 'SELECT id FROM namespaces' }

      it do
        expect(subject).to contain_exactly(Type::STATIC)
      end

      context 'with dynamic reference' do
        let(:sql) { 'SELECT id FROM (SELECT * FROM namespaces) AS xyz' }

        it do
          expect(subject).to contain_exactly(Type::STATIC)
        end
      end
    end

    context 'when dynamic column' do
      let(:sql) { 'SELECT * FROM namespaces' }

      it do
        expect(subject).to contain_exactly(Type::DYNAMIC)
      end

      context 'with static reference' do
        let(:sql) { 'SELECT * FROM (SELECT 1) AS xyz' }

        it do
          expect(subject).to contain_exactly(Type::STATIC)
        end
      end
    end

    context 'when reference has errors' do
      let(:cte_refs) { { 'namespaces' => [Type::INVALID].to_set } }
      let(:sql) { 'SELECT * FROM namespaces' }

      it 'forward through error state' do
        expect(subject).to include(Type::INVALID)
      end
    end

    context 'when static and dynamic columns' do
      let(:sql) { 'SELECT *, users.id FROM namespaces, users' }

      it do
        expect(subject).to contain_exactly(Type::DYNAMIC, Type::STATIC)
      end
    end

    context 'when static column and error' do
      let(:error_column) { "SELECT #{namespace_columns} FROM namespaces UNION SELECT * FROM namespaces" }
      let(:sql) { "SELECT id, (#{error_column}) FROM namespaces" }

      it do
        expect(subject).to contain_exactly(Type::STATIC, Type::INVALID)
      end
    end

    context 'when dynamic column and error' do
      let(:error_column) { "SELECT #{namespace_columns} FROM namespaces UNION SELECT * FROM namespaces" }
      let(:sql) { "SELECT *, (#{error_column}) FROM namespaces" }

      it do
        # The sub-select is treated as a Type::STATIC column for now. This could do with some refinement.
        expect(subject).to contain_exactly(Type::DYNAMIC, Type::STATIC, Type::INVALID)
      end
    end
  end
end
