# frozen_string_literal: true

require 'spec_helper'

describe Gitlab::Graphql::Connections::Keyset::Conditions::NullCondition do
  describe '#build' do
    let(:condition) { described_class.new(Issue.arel_table, %w(relative_position id), [nil, 500], [nil, '>'], before_or_after) }

    context 'when :after' do
      let(:before_or_after) { :after }

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
  end
end
