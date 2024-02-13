# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::Database::QueryAnalyzers::PreventSetOperatorMismatch, query_analyzers: false, feature_category: :cell do
  let(:analyzer) { described_class }
  let_it_be(:static_namespace_columns) { Namespace.column_names.join(', ') }

  def process_sql(sql, model = ApplicationRecord)
    Gitlab::Database::QueryAnalyzer.instance.within([analyzer]) do
      # Skip load balancer and retrieve connection assigned to model
      Gitlab::Database::QueryAnalyzer.instance.send(:process_sql, sql, model.retrieve_connection, 'load')
    end
  end

  shared_examples 'parses SQL' do
    it do
      expect_next_instance_of(described_class::SelectStmt) do |select_stmt|
        expect(select_stmt).to receive(:types).and_return(Set.new)
      end

      process_sql sql
    end
  end

  context 'when SQL includes a UNION' do
    let(:sql) { 'SELECT 1 UNION SELECT 2' }

    include_examples 'parses SQL'
  end

  context 'when SQL includes a INTERSECT' do
    let(:sql) { 'SELECT 1 INTERSECT SELECT 2' }

    include_examples 'parses SQL'
  end

  context 'when SQL includes a EXCEPT' do
    let(:sql) { 'SELECT 1 EXCEPT SELECT 2' }

    include_examples 'parses SQL'
  end

  context 'when SQL does not include a set operator' do
    where(:sql) do
      [
        'SELECT 1',
        'SELECT union_station',
        'SELECT intersection',
        'SELECT deny_all_requests_except_allowed from application_settings'
      ]
    end

    with_them do
      it 'does not parse SQL' do
        expect(described_class::SelectStmt).not_to receive(:new)

        process_sql sql
      end
    end
  end

  context 'when SQL is invalid' do
    it 'raises error' do
      expect do
        process_sql "SELECT #{static_namespace_columns} FROM namespaces UNION SELECT * FROM namespaces"
      end.to raise_error(described_class::SetOperatorStarError)
    end
  end

  context 'when SQL is valid' do
    it 'does not raise error' do
      expect do
        process_sql 'SELECT 1'
      end.not_to raise_error
    end
  end

  context 'when SQL has many select statements' do
    let(:sql) do
      <<-SQL
        SELECT 1 UNION SELECT 1;
        SELECT #{static_namespace_columns} FROM namespaces UNION SELECT * FROM namespaces
      SQL
    end

    it 'raises error' do
      expect do
        process_sql sql
      end.to raise_error(described_class::SetOperatorStarError)
    end
  end
end
