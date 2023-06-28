# frozen_string_literal: true

require 'spec_helper'
require_migration!

RSpec.describe SwapCiBuildNeedsToBigIntForSelfHosts, feature_category: :continuous_integration do
  after do
    connection = described_class.new.connection
    connection.execute('ALTER TABLE ci_build_needs DROP COLUMN IF EXISTS id_convert_to_bigint')
  end

  describe '#up' do
    context 'when on GitLab.com, dev, or test' do
      before do
        connection = described_class.new.connection
        connection.execute('ALTER TABLE ci_build_needs ALTER COLUMN id TYPE bigint')
        connection.execute('ALTER TABLE ci_build_needs DROP COLUMN IF EXISTS id_convert_to_bigint')
      end

      it 'does not swap the columns' do
        # rubocop: disable RSpec/AnyInstanceOf
        allow_any_instance_of(described_class).to receive(:com_or_dev_or_test_but_not_jh?).and_return(true)
        # rubocop: enable RSpec/AnyInstanceOf

        ci_build_needs = table(:ci_build_needs)

        disable_migrations_output do
          reversible_migration do |migration|
            migration.before -> {
              ci_build_needs.reset_column_information

              expect(ci_build_needs.columns.find { |c| c.name == 'id' }.sql_type).to eq('bigint')
              expect(ci_build_needs.columns.find { |c| c.name == 'id_convert_to_bigint' }).to be nil
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

    context 'when a self-hosted installation has already completed the swap' do
      before do
        connection = described_class.new.connection
        connection.execute('ALTER TABLE ci_build_needs ALTER COLUMN id TYPE bigint')
        connection.execute('ALTER TABLE ci_build_needs ADD COLUMN IF NOT EXISTS id_convert_to_bigint integer')
      end

      it 'does not swap the columns' do
        # rubocop: disable RSpec/AnyInstanceOf
        allow_any_instance_of(described_class).to receive(:com_or_dev_or_test_but_not_jh?).and_return(false)
        # rubocop: enable RSpec/AnyInstanceOf

        ci_build_needs = table(:ci_build_needs)

        migrate!

        expect(ci_build_needs.columns.find { |c| c.name == 'id' }.sql_type).to eq('bigint')
        expect(ci_build_needs.columns.find do |c|
          c.name == 'id_convert_to_bigint'
        end.sql_type).to eq('integer')
      end
    end

    context 'when a self-hosted installation has the `id_convert_to_bigint` column already dropped' do
      before do
        connection = described_class.new.connection
        connection.execute('ALTER TABLE ci_build_needs ALTER COLUMN id TYPE bigint')
        connection.execute('ALTER TABLE ci_build_needs DROP COLUMN IF EXISTS id_convert_to_bigint')
      end

      it 'does not swap the columns' do
        # rubocop: disable RSpec/AnyInstanceOf
        allow_any_instance_of(described_class).to receive(:com_or_dev_or_test_but_not_jh?).and_return(false)
        # rubocop: enable RSpec/AnyInstanceOf

        ci_build_needs = table(:ci_build_needs)

        disable_migrations_output do
          reversible_migration do |migration|
            migration.before -> {
              ci_build_needs.reset_column_information

              expect(ci_build_needs.columns.find { |c| c.name == 'id' }.sql_type).to eq('bigint')
              expect(ci_build_needs.columns.find { |c| c.name == 'id_convert_to_bigint' }).to be nil
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

    context 'when an installation is self-hosted' do
      before do
        connection = described_class.new.connection
        connection.execute('ALTER TABLE ci_build_needs ALTER COLUMN id TYPE integer')
        connection.execute('ALTER TABLE ci_build_needs ADD COLUMN IF NOT EXISTS id_convert_to_bigint bigint')
        connection.execute('ALTER TABLE ci_build_needs ALTER COLUMN id_convert_to_bigint TYPE bigint')
        connection.execute('DROP INDEX IF EXISTS index_ci_build_needs_on_id_convert_to_bigint')
        connection.execute('CREATE OR REPLACE FUNCTION trigger_3207b8d0d6f3() RETURNS trigger LANGUAGE plpgsql AS $$
          BEGIN NEW."id_convert_to_bigint" := NEW."id"; RETURN NEW; END; $$;')
      end

      it 'swaps the columns' do
        # rubocop: disable RSpec/AnyInstanceOf
        allow_any_instance_of(described_class).to receive(:com_or_dev_or_test_but_not_jh?).and_return(false)
        # rubocop: enable RSpec/AnyInstanceOf

        ci_build_needs = table(:ci_build_needs)

        disable_migrations_output do
          reversible_migration do |migration|
            migration.before -> {
              ci_build_needs.reset_column_information

              expect(ci_build_needs.columns.find { |c| c.name == 'id' }.sql_type).to eq('integer')
              expect(ci_build_needs.columns.find do |c|
                       c.name == 'id_convert_to_bigint'
                     end.sql_type).to eq('bigint')
            }

            migration.after -> {
              ci_build_needs.reset_column_information

              expect(ci_build_needs.columns.find { |c| c.name == 'id' }.sql_type).to eq('bigint')
              expect(ci_build_needs.columns.find do |c|
                       c.name == 'id_convert_to_bigint'
                     end.sql_type).to eq('integer')
            }
          end
        end
      end
    end
  end
end
