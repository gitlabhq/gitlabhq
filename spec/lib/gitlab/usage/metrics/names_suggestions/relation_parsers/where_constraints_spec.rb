# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::Usage::Metrics::NamesSuggestions::RelationParsers::WhereConstraints do
  describe '#accept' do
    let(:connection) { ApplicationRecord.connection }
    let(:collector) { Arel::Collectors::SubstituteBinds.new(connection, Arel::Collectors::SQLString.new) }

    it 'builds correct constraints description' do
      table = Arel::Table.new('records')
      arel = table.from.project(table['id'].count).where(table[:attribute].eq(true).and(table[:some_value].gt(5)))
      described_class.new(connection).accept(arel, collector)

      expect(collector.value).to eql '(records.attribute = true AND records.some_value > 5)'
    end
  end
end
