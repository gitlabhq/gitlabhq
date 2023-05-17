# frozen_string_literal: true

require 'spec_helper'
require_migration!

RSpec.describe SwapMergeRequestMetricsIdToBigintForSelfHosts, feature_category: :database do
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
        connection.execute('ALTER TABLE merge_request_metrics ALTER COLUMN id TYPE bigint')
        connection.execute('ALTER TABLE merge_request_metrics DROP COLUMN IF EXISTS id_convert_to_bigint')
      end

      it 'does not swap the columns' do
        # rubocop: disable RSpec/AnyInstanceOf
        allow_any_instance_of(described_class).to receive(:com_or_dev_or_test_but_not_jh?).and_return(true)
        # rubocop: enable RSpec/AnyInstanceOf

        merge_request_metrics = table(:merge_request_metrics)

        disable_migrations_output do
          reversible_migration do |migration|
            migration.before -> {
              merge_request_metrics.reset_column_information

              expect(merge_request_metrics.columns.find { |c| c.name == 'id' }.sql_type).to eq('bigint')
              expect(merge_request_metrics.columns.find { |c| c.name == 'id_convert_to_bigint' }).to be nil
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

    context 'when is a self-host customer with the swapped already completed' do
      before do
        # As we call `schema_migrate_down!` before each example, and for this migration
        # `#down` is same as `#up`, we need to ensure we start from the expected state.
        connection = described_class.new.connection
        connection.execute('ALTER TABLE merge_request_metrics ALTER COLUMN id TYPE bigint')
        connection.execute('ALTER TABLE merge_request_metrics ADD COLUMN IF NOT EXISTS id_convert_to_bigint integer')
      end

      it 'does not swap the columns' do
        # rubocop: disable RSpec/AnyInstanceOf
        allow_any_instance_of(described_class).to receive(:com_or_dev_or_test_but_not_jh?).and_return(false)
        # rubocop: enable RSpec/AnyInstanceOf

        merge_request_metrics = table(:merge_request_metrics)

        migrate!

        expect(merge_request_metrics.columns.find { |c| c.name == 'id' }.sql_type).to eq('bigint')
        expect(merge_request_metrics.columns.find do |c|
          c.name == 'id_convert_to_bigint'
        end.sql_type).to eq('integer')
      end
    end

    context 'when is a self-host customer with the `id_convert_to_bigint` column already dropped ' do
      before do
        # As we call `schema_migrate_down!` before each example, and for this migration
        # `#down` is same as `#up`, we need to ensure we start from the expected state.
        connection = described_class.new.connection
        connection.execute('ALTER TABLE merge_request_metrics ALTER COLUMN id TYPE bigint')
        connection.execute('ALTER TABLE merge_request_metrics DROP COLUMN IF EXISTS id_convert_to_bigint')
      end

      it 'does not swap the columns' do
        # rubocop: disable RSpec/AnyInstanceOf
        allow_any_instance_of(described_class).to receive(:com_or_dev_or_test_but_not_jh?).and_return(false)
        # rubocop: enable RSpec/AnyInstanceOf

        merge_request_metrics = table(:merge_request_metrics)

        disable_migrations_output do
          reversible_migration do |migration|
            migration.before -> {
              merge_request_metrics.reset_column_information

              expect(merge_request_metrics.columns.find { |c| c.name == 'id' }.sql_type).to eq('bigint')
              expect(merge_request_metrics.columns.find { |c| c.name == 'id_convert_to_bigint' }).to be nil
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

    context 'when is a self-host customer' do
      before do
        # As we call `schema_migrate_down!` before each example, and for this migration
        # `#down` is same as `#up`, we need to ensure we start from the expected state.
        connection = described_class.new.connection
        connection.execute('ALTER TABLE merge_request_metrics ALTER COLUMN id TYPE integer')
        connection.execute('ALTER TABLE merge_request_metrics ADD COLUMN IF NOT EXISTS id_convert_to_bigint bigint')
        connection.execute('ALTER TABLE merge_request_metrics ALTER COLUMN id_convert_to_bigint TYPE bigint')
        connection.execute('DROP INDEX IF EXISTS index_merge_request_metrics_on_id_convert_to_bigint')
        connection.execute('DROP INDEX IF EXISTS tmp_index_mr_metrics_on_target_project_id_merged_at_nulls_last')
        connection.execute('CREATE OR REPLACE FUNCTION trigger_c7107f30d69d() RETURNS trigger LANGUAGE plpgsql AS $$
          BEGIN NEW."id_convert_to_bigint" := NEW."id"; RETURN NEW; END; $$;')
      end

      it 'swaps the columns' do
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

              expect(merge_request_metrics.columns.find { |c| c.name == 'id' }.sql_type).to eq('bigint')
              expect(merge_request_metrics.columns.find do |c|
                       c.name == 'id_convert_to_bigint'
                     end.sql_type).to eq('integer')
            }
          end
        end
      end
    end
  end
end
