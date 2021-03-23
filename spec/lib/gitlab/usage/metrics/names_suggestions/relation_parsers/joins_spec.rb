# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::Usage::Metrics::NamesSuggestions::RelationParsers::Joins do
  describe '#accept' do
    let(:collector) { Arel::Collectors::SubstituteBinds.new(ActiveRecord::Base.connection, Arel::Collectors::SQLString.new) }

    context 'with join added via string' do
      it 'collects join parts' do
        arel = Issue.joins('LEFT JOIN projects ON projects.id = issue.project_id')

        arel = arel.arel
        result = described_class.new(ApplicationRecord.connection).accept(arel)

        expect(result).to match_array [{ source: "projects", constraints: "projects.id = issue.project_id" }]
      end
    end

    context 'with join added via arel node' do
      it 'collects join parts' do
        source_table = Arel::Table.new('records')
        joined_table = Arel::Table.new('joins')
        second_level_joined_table = Arel::Table.new('second_level_joins')

        arel = source_table
                 .from
                 .project(source_table['id'].count)
                 .join(joined_table, Arel::Nodes::OuterJoin)
                 .on(source_table[:id].eq(joined_table[:records_id]))
                 .join(second_level_joined_table, Arel::Nodes::OuterJoin)
                 .on(joined_table[:id].eq(second_level_joined_table[:joins_id]))

        result = described_class.new(ApplicationRecord.connection).accept(arel)

        expect(result).to match_array [{ source: "joins", constraints: "records.id = joins.records_id" }, { source: "second_level_joins", constraints: "joins.id = second_level_joins.joins_id" }]
      end
    end
  end
end
