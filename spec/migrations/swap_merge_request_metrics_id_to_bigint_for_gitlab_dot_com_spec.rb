# frozen_string_literal: true

require 'spec_helper'
require_migration!

RSpec.describe SwapMergeRequestMetricsIdToBigintForGitlabDotCom, feature_category: :database do
  describe '#up' do
    before do
      # As we call `schema_migrate_down!` before each example, and for this migration
      # `#down` is same as `#up`, we need to ensure we start from the expected state.
      connection = described_class.new.connection
      connection.execute('ALTER TABLE merge_request_metrics ALTER COLUMN id TYPE integer')
      connection.execute('ALTER TABLE merge_request_metrics ALTER COLUMN id_convert_to_bigint TYPE bigint')
    end

    it 'swaps the integer and bigint columns for GitLab.com, dev, or test' do
      # rubocop: disable RSpec/AnyInstanceOf
      allow_any_instance_of(described_class).to receive(:com_or_dev_or_test_but_not_jh?).and_return(true)
      # rubocop: enable RSpec/AnyInstanceOf

      merge_request_metrics = table(:merge_request_metrics)

      disable_migrations_output do
        reversible_migration do |migration|
          migration.before -> {
            merge_request_metrics.reset_column_information

            expect(merge_request_metrics.columns.find { |c| c.name == 'id' }.sql_type).to eq('integer')
            expect(merge_request_metrics.columns.find do |c|
                     c.name == 'id_convert_to_bigint'
                   end.sql_type).to eq('bigint')
          }

          migration.after -> {
            merge_request_metrics.reset_column_information

            expect(merge_request_metrics.columns.find { |c| c.name == 'id' }.sql_type).to eq('bigint')
            expect(merge_request_metrics.columns.find do |c|
                     c.name == 'id_convert_to_bigint'
                   end.sql_type).to eq('integer')
          }
        end
      end
    end

    it 'is a no-op for other instances' do
      # rubocop: disable RSpec/AnyInstanceOf
      allow_any_instance_of(described_class).to receive(:com_or_dev_or_test_but_not_jh?).and_return(false)
      # rubocop: enable RSpec/AnyInstanceOf

      merge_request_metrics = table(:merge_request_metrics)

      disable_migrations_output do
        reversible_migration do |migration|
          migration.before -> {
            merge_request_metrics.reset_column_information

            expect(merge_request_metrics.columns.find { |c| c.name == 'id' }.sql_type).to eq('integer')
            expect(merge_request_metrics.columns.find do |c|
                     c.name == 'id_convert_to_bigint'
                   end.sql_type).to eq('bigint')
          }

          migration.after -> {
            merge_request_metrics.reset_column_information

            expect(merge_request_metrics.columns.find { |c| c.name == 'id' }.sql_type).to eq('integer')
            expect(merge_request_metrics.columns.find do |c|
                     c.name == 'id_convert_to_bigint'
                   end.sql_type).to eq('bigint')
          }
        end
      end
    end
  end
end
