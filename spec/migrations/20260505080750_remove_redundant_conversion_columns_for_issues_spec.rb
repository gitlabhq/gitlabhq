# frozen_string_literal: true

require 'spec_helper'
require_migration!

RSpec.describe RemoveRedundantConversionColumnsForIssues, feature_category: :database do
  let(:connection) { described_class.new.connection }
  let(:integer_column) { "updated_by_id" }
  let(:conversion_column_names) do
    described_class::COLUMNS.map { |col, _| "#{col}_convert_to_bigint" }
  end

  def column_names_for_issues
    connection.columns(:issues).map(&:name)
  end

  def change_column_to_integer!
    connection.execute("ALTER TABLE issues ALTER COLUMN #{integer_column} TYPE integer")
  end

  def restore_column_to_bigint!
    connection.execute("ALTER TABLE issues ALTER COLUMN #{integer_column} TYPE bigint")
  end

  context 'when columns are already bigint' do
    it 'removes the conversion columns' do
      reversible_migration do |migration|
        migration.before -> {
          conversion_column_names.each do |col|
            expect(column_names_for_issues).to include(col)
          end
        }

        migration.after -> {
          conversion_column_names.each do |col|
            expect(column_names_for_issues).not_to include(col)
          end
        }
      end
    end
  end

  context 'when integer columns still exist' do
    before do
      change_column_to_integer!
    end

    after do
      restore_column_to_bigint!
    end

    it 'does not remove conversion columns' do
      reversible_migration do |migration|
        migration.before -> {
          conversion_column_names.each do |col|
            expect(column_names_for_issues).to include(col)
          end
        }

        migration.after -> {
          conversion_column_names.each do |col|
            expect(column_names_for_issues).to include(col)
          end
        }
      end
    end
  end
end
