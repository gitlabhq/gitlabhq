# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::Usage::Metrics::NamesSuggestions::RelationParsers::HavingConstraints do
  describe '#accept' do
    let(:connection) { ApplicationRecord.connection }
    let(:collector) { Arel::Collectors::SubstituteBinds.new(connection, Arel::Collectors::SQLString.new) }

    it 'builds correct constraints description' do
      table = Arel::Table.new('records')
      havings = table[:attribute].sum.eq(6).and(table[:attribute].count.gt(5))
      arel = table.from.project(table['id'].count).having(havings).group(table[:attribute2])
      described_class.new(connection).accept(arel, collector)

      expect(collector.value).to eql '(SUM(records.attribute) = 6 AND COUNT(records.attribute) > 5)'
    end
  end
end
