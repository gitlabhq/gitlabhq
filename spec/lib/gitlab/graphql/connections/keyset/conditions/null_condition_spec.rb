# frozen_string_literal: true

require 'spec_helper'

describe Gitlab::Graphql::Connections::Keyset::Conditions::NullCondition do
  describe '#build' do
    let(:values) { [nil, 500] }
    let(:operators) { [nil, '>'] }
    let(:before_or_after) { :after }
    let(:condition) { described_class.new(arel_table, order_list, values, operators, before_or_after) }

    context 'when ordering by a column attribute' do
      let(:arel_table) { Issue.arel_table }
      let(:order_list) { %w(relative_position id) }

      shared_examples ':after condition' do
        it 'generates sql' do
          expected_sql = <<~SQL
            (
              "issues"."relative_position" IS NULL
              AND
              "issues"."id" > 500
            )
          SQL

          expect(condition.build.squish).to eq expected_sql.squish
        end
      end

      context 'when :after' do
        it_behaves_like ':after condition'
      end

      context 'when :before' do
        let(:before_or_after) { :before }

        it 'generates :before sql' do
          expected_sql = <<~SQL
            (
              "issues"."relative_position" IS NULL
              AND
              "issues"."id" > 500
            )
            OR ("issues"."relative_position" IS NOT NULL)
          SQL

          expect(condition.build.squish).to eq expected_sql.squish
        end
      end

      context 'when :foo' do
        let(:before_or_after) { :foo }

        it_behaves_like ':after condition'
      end
    end
  end
end
