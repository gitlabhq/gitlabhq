# frozen_string_literal: true

require 'spec_helper'
require_migration!

RSpec.describe CleanupBigintConversionForMergeRequestMetricsForSelfHosts, feature_category: :database do
  after do
    connection = described_class.new.connection
    connection.execute('ALTER TABLE merge_request_metrics DROP COLUMN IF EXISTS id_convert_to_bigint')
  end

  describe '#up' do
    context 'when is GitLab.com, dev, or test' do
      before do
        # As we call `schema_migrate_down!` before each example, and for this migration
        # `#down` is same as `#up`, we need to ensure we start from the expected state.
        connection = described_class.new.connection
        connection.execute('ALTER TABLE merge_request_metrics DROP COLUMN IF EXISTS id_convert_to_bigint')
      end

      it 'does nothing' do
        # rubocop: disable RSpec/AnyInstanceOf
        allow_any_instance_of(described_class).to receive(:com_or_dev_or_test_but_not_jh?).and_return(true)
        # rubocop: enable RSpec/AnyInstanceOf

        merge_request_metrics = table(:merge_request_metrics)

        disable_migrations_output do
          reversible_migration do |migration|
            migration.before -> {
              merge_request_metrics.reset_column_information

              expect(merge_request_metrics.columns.find { |c| c.name == 'id_convert_to_bigint' }).to be nil
            }

            migration.after -> {
              merge_request_metrics.reset_column_information

              expect(merge_request_metrics.columns.find { |c| c.name == 'id_convert_to_bigint' }).to be nil
            }
          end
        end
      end
    end

    context 'when is a self-host customer with the temporary column already dropped' do
      before do
        # As we call `schema_migrate_down!` before each example, and for this migration
        # `#down` is same as `#up`, we need to ensure we start from the expected state.
        connection = described_class.new.connection
        connection.execute('ALTER TABLE merge_request_metrics ALTER COLUMN id TYPE bigint')
        connection.execute('ALTER TABLE merge_request_metrics DROP COLUMN IF EXISTS id_convert_to_bigint')
      end

      it 'does nothing' do
        # rubocop: disable RSpec/AnyInstanceOf
        allow_any_instance_of(described_class).to receive(:com_or_dev_or_test_but_not_jh?).and_return(false)
        # rubocop: enable RSpec/AnyInstanceOf

        merge_request_metrics = table(:merge_request_metrics)

        migrate!

        expect(merge_request_metrics.columns.find { |c| c.name == 'id' }.sql_type).to eq('bigint')
        expect(merge_request_metrics.columns.find { |c| c.name == 'id_convert_to_bigint' }).to be nil
      end
    end

    context 'when is a self-host with the temporary columns' do
      before do
        # As we call `schema_migrate_down!` before each example, and for this migration
        # `#down` is same as `#up`, we need to ensure we start from the expected state.
        connection = described_class.new.connection
        connection.execute('ALTER TABLE merge_request_metrics ALTER COLUMN id TYPE bigint')
        connection.execute('ALTER TABLE merge_request_metrics ADD COLUMN IF NOT EXISTS id_convert_to_bigint integer')
      end

      it 'drop the temporary columns' do
        # rubocop: disable RSpec/AnyInstanceOf
        allow_any_instance_of(described_class).to receive(:com_or_dev_or_test_but_not_jh?).and_return(false)
        # rubocop: enable RSpec/AnyInstanceOf

        merge_request_metrics = table(:merge_request_metrics)

        disable_migrations_output do
          reversible_migration do |migration|
            migration.before -> {
              merge_request_metrics.reset_column_information

              expect(merge_request_metrics.columns.find { |c| c.name == 'id' }.sql_type).to eq('bigint')
              expect(merge_request_metrics.columns.find do |c|
                       c.name == 'id_convert_to_bigint'
                     end.sql_type).to eq('integer')
            }

            migration.after -> {
              merge_request_metrics.reset_column_information

              expect(merge_request_metrics.columns.find { |c| c.name == 'id' }.sql_type).to eq('bigint')
              expect(merge_request_metrics.columns.find { |c| c.name == 'id_convert_to_bigint' }).to be nil
            }
          end
        end
      end
    end
  end
end
