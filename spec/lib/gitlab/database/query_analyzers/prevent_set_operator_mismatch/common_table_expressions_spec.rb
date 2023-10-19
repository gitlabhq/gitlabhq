# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::Database::QueryAnalyzers::PreventSetOperatorMismatch::CommonTableExpressions,
  feature_category: :cell do
  include PreventSetOperatorMismatchHelper

  describe '.references' do
    let(:node) { sql_select_node(sql) }
    let(:cte_refs) { {} }

    subject { described_class.references(node, cte_refs) }

    context 'when standard CTE' do
      let(:sql) do
        <<-SQL
          WITH some_cte AS (#{cte})
          SELECT 1
          FROM some_cte
        SQL
      end

      context 'with static SELECT' do
        let(:cte) { 'SELECT 1' }

        it do
          exp = { "some_cte" => Set.new([Type::STATIC]) }
          expect(subject).to eq(exp)
        end
      end

      context 'with dynamic SELECT' do
        let(:cte) { 'SELECT * FROM namespaces' }

        it do
          exp = { "some_cte" => Set.new([Type::DYNAMIC]) }
          expect(subject).to eq(exp)
        end
      end
    end

    context 'when recursive CTE' do
      let(:sql) do
        <<-SQL
          WITH RECURSIVE some_cte AS (#{cte})
          SELECT 1
          FROM some_cte
        SQL
      end

      context 'with static SELECT' do
        let(:cte) { 'SELECT 1 UNION SELECT 2' }

        it do
          exp = { "some_cte" => Set.new([Type::STATIC]) }
          expect(subject).to eq(exp)
        end
      end

      context 'with dynamic SELECT' do
        let(:cte) { 'SELECT * FROM namespaces UNION SELECT * FROM namespaces' }

        it do
          exp = { "some_cte" => Set.new([Type::DYNAMIC]) }
          expect(subject).to eq(exp)
        end
      end

      context 'with error SELECT' do
        let(:cte) { 'SELECT * FROM namespaces UNION SELECT id FROM namespaces' }

        it do
          exp = { "some_cte" => Set.new([Type::DYNAMIC, Type::STATIC, Type::INVALID]) }
          expect(subject).to eq(exp)
        end
      end
    end

    context 'with inherited CTE references' do
      let(:sql) do
        <<-SQL
          WITH some_cte AS (SELECT 1)
          SELECT 1
          FROM some_cte
        SQL
      end

      let(:cte_refs) { { 'some_reference' => 123 } }

      it 'maintains inherited CTE references' do
        subject_ref_names = subject.keys
        expect(subject_ref_names).to eq(cte_refs.keys + ['some_cte'])
      end
    end
  end
end
