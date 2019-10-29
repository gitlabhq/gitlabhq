# frozen_string_literal: true

require 'spec_helper'

describe Gitlab::Graphql::Connections::Keyset::Conditions::NotNullCondition do
  describe '#build' do
    let(:condition) { described_class.new(Issue.arel_table, %w(relative_position id), [1500, 500], ['>', '>'], before_or_after) }

    context 'when there is only one ordering field' do
      let(:condition) { described_class.new(Issue.arel_table, ['id'], [500], ['>'], :after) }

      it 'generates a single condition sql' do
        expected_sql = <<~SQL
          ("issues"."id" > 500)
        SQL

        expect(condition.build.squish).to eq expected_sql.squish
      end
    end

    context 'when :after' do
      let(:before_or_after) { :after }

      it 'generates :after sql' do
        expected_sql = <<~SQL
          ("issues"."relative_position" > 1500)
          OR (
            "issues"."relative_position" = 1500
            AND
            "issues"."id" > 500
          )
          OR ("issues"."relative_position" IS NULL)
        SQL

        expect(condition.build.squish).to eq expected_sql.squish
      end
    end

    context 'when :before' do
      let(:before_or_after) { :before }

      it 'generates :before sql' do
        expected_sql = <<~SQL
          ("issues"."relative_position" > 1500)
          OR (
            "issues"."relative_position" = 1500
            AND
            "issues"."id" > 500
          )
        SQL

        expect(condition.build.squish).to eq expected_sql.squish
      end
    end
  end
end
