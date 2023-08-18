# frozen_string_literal: true

require 'spec_helper'
require_migration!

RSpec.describe CleanupConversionBigIntCiBuildNeedsSelfManaged, feature_category: :database do
  after do
    connection = described_class.new.connection
    connection.execute('ALTER TABLE ci_build_needs DROP COLUMN IF EXISTS id_convert_to_bigint')
  end

  describe '#up' do
    context 'when it is GitLab.com, dev, or test but not JiHu' do
      before do
        # As we call `schema_migrate_down!` before each example, and for this migration
        # `#down` is same as `#up`, we need to ensure we start from the expected state.
        connection = described_class.new.connection
        connection.execute('ALTER TABLE ci_build_needs DROP COLUMN IF EXISTS id_convert_to_bigint')
      end

      it 'does nothing' do
        # rubocop: disable RSpec/AnyInstanceOf
        allow_any_instance_of(described_class).to receive(:com_or_dev_or_test_but_not_jh?).and_return(true)
        # rubocop: enable RSpec/AnyInstanceOf

        ci_build_needs = table(:ci_build_needs)

        disable_migrations_output do
          reversible_migration do |migration|
            migration.before -> {
              ci_build_needs.reset_column_information

              expect(ci_build_needs.columns.find { |c| c.name == 'id_convert_to_bigint' }).to be nil
            }

            migration.after -> {
              ci_build_needs.reset_column_information

              expect(ci_build_needs.columns.find { |c| c.name == 'id_convert_to_bigint' }).to be nil
            }
          end
        end
      end
    end

    context 'when there is a self-managed instance with the temporary column already dropped' do
      before do
        # As we call `schema_migrate_down!` before each example, and for this migration
        # `#down` is same as `#up`, we need to ensure we start from the expected state.
        connection = described_class.new.connection
        connection.execute('ALTER TABLE ci_build_needs ALTER COLUMN id TYPE bigint')
        connection.execute('ALTER TABLE ci_build_needs DROP COLUMN IF EXISTS id_convert_to_bigint')
      end

      it 'does nothing' do
        # rubocop: disable RSpec/AnyInstanceOf
        allow_any_instance_of(described_class).to receive(:com_or_dev_or_test_but_not_jh?).and_return(false)
        # rubocop: enable RSpec/AnyInstanceOf

        ci_build_needs = table(:ci_build_needs)

        migrate!

        expect(ci_build_needs.columns.find { |c| c.name == 'id' }.sql_type).to eq('bigint')
        expect(ci_build_needs.columns.find { |c| c.name == 'id_convert_to_bigint' }).to be nil
      end
    end

    context 'when there is a self-managed instance with the temporary columns' do
      before do
        # As we call `schema_migrate_down!` before each example, and for this migration
        # `#down` is same as `#up`, we need to ensure we start from the expected state.
        connection = described_class.new.connection
        connection.execute('ALTER TABLE ci_build_needs ALTER COLUMN id TYPE bigint')
        connection.execute('ALTER TABLE ci_build_needs ADD COLUMN IF NOT EXISTS id_convert_to_bigint integer')
      end

      it 'drops the temporary column' do
        # rubocop: disable RSpec/AnyInstanceOf
        allow_any_instance_of(described_class).to receive(:com_or_dev_or_test_but_not_jh?).and_return(false)
        # rubocop: enable RSpec/AnyInstanceOf

        ci_build_needs = table(:ci_build_needs)

        disable_migrations_output do
          reversible_migration do |migration|
            migration.before -> {
              ci_build_needs.reset_column_information

              expect(ci_build_needs.columns.find { |c| c.name == 'id' }.sql_type).to eq('bigint')
              expect(ci_build_needs.columns.find do |c|
                       c.name == 'id_convert_to_bigint'
                     end.sql_type).to eq('integer')
            }

            migration.after -> {
              ci_build_needs.reset_column_information

              expect(ci_build_needs.columns.find { |c| c.name == 'id' }.sql_type).to eq('bigint')
              expect(ci_build_needs.columns.find { |c| c.name == 'id_convert_to_bigint' }).to be nil
            }
          end
        end
      end
    end
  end
end
