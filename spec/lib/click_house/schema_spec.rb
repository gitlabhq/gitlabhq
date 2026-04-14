# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'ClickHouse schema', :click_house, feature_category: :database do
  let(:connection) { ClickHouse::Connection.new(:main) }

  describe 'column default values' do
    it "uses now64(6, 'UTC') for every column whose default starts with 'now'" do
      query = ClickHouse::Client::Query.new(
        raw_query: <<~SQL,
          SELECT table, name, default_expression
          FROM system.columns
          WHERE database = {database:String}
            AND default_expression LIKE 'now%'
          ORDER BY table, name
        SQL
        placeholders: { database: connection.database_name }
      )

      violations = connection.select(query).reject do |row|
        row['default_expression'].to_s.delete(' ') == "now64(6,'UTC')"
      end

      expect(violations).to be_empty, -> {
        lines = violations.map do |row|
          "  - #{row['table']}.#{row['name']}: " \
            "found `#{row['default_expression']}`, expected `now64(6, 'UTC')`"
        end

        <<~MSG
          #{violations.size} column(s) use a non-UTC now() default.
          UTC is required so that default values are database-config agnostic.
          ClickHouse's now() uses the server timezone, now64(6, 'UTC') does not.

          #{lines.join("\n")}
        MSG
      }
    end
  end
end
