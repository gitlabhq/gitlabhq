# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::Pagination::Keyset::InOperatorOptimization::ColumnData do
  subject(:column_data) { described_class.new('id', 'issue_id', Issue.arel_table) }

  describe '#array_aggregated_column_name' do
    it { expect(column_data.array_aggregated_column_name).to eq('issues_id_array') }
  end

  describe '#projection' do
    it 'returns the Arel projection for the column with a new alias' do
      expect(column_data.projection.to_sql).to eq('"issues"."id" AS issue_id')
    end
  end

  it 'accepts symbols for original_column_name and as' do
    column_data = described_class.new(:id, :issue_id, Issue.arel_table)

    expect(column_data.projection.to_sql).to eq('"issues"."id" AS issue_id')
  end
end
