# frozen_string_literal: true

require 'spec_helper'
require_migration!

RSpec.describe SwapNoteDiffFilesNoteIdToBigintForSelfHosts, feature_category: :database do
  describe '#up' do
    after(:all) do
      connection = described_class.new.connection
      connection.execute('ALTER TABLE note_diff_files DROP COLUMN IF EXISTS diff_note_id_convert_to_bigint')
    end

    context 'when GitLab.com, dev, or test' do
      before do
        # As we call `schema_migrate_down!` before each example, and for this migration
        # `#down` is same as `#up`, we need to ensure we start from the expected state.
        connection = described_class.new.connection
        connection.execute('ALTER TABLE note_diff_files ALTER COLUMN diff_note_id TYPE bigint')
        connection.execute('ALTER TABLE note_diff_files DROP COLUMN IF EXISTS diff_note_id_convert_to_bigint')
      end

      it 'does not swap the columns' do
        # rubocop: disable RSpec/AnyInstanceOf
        allow_any_instance_of(described_class).to receive(:com_or_dev_or_test_but_not_jh?).and_return(true)
        # rubocop: enable RSpec/AnyInstanceOf

        note_diff_files = table(:note_diff_files)

        disable_migrations_output do
          reversible_migration do |migration|
            migration.before -> {
              note_diff_files.reset_column_information

              expect(note_diff_files.columns.find { |c| c.name == 'diff_note_id' }.sql_type).to eq('bigint')
              expect(note_diff_files.columns.find { |c| c.name == 'diff_note_id_convert_to_bigint' }).to be nil
            }

            migration.after -> {
              note_diff_files.reset_column_information

              expect(note_diff_files.columns.find { |c| c.name == 'diff_note_id' }.sql_type).to eq('bigint')
              expect(note_diff_files.columns.find { |c| c.name == 'diff_note_id_convert_to_bigint' }).to be nil
            }
          end
        end
      end
    end

    context 'when self-managed instance with the columns already swapped' do
      before do
        # As we call `schema_migrate_down!` before each example, and for this migration
        # `#down` is same as `#up`, we need to ensure we start from the expected state.
        connection = described_class.new.connection
        connection.execute('ALTER TABLE note_diff_files ALTER COLUMN diff_note_id TYPE bigint')
        connection.execute(
          'ALTER TABLE note_diff_files ADD COLUMN IF NOT EXISTS diff_note_id_convert_to_bigint integer'
        )
      end

      it 'does not swap the columns' do
        # rubocop: disable RSpec/AnyInstanceOf
        allow_any_instance_of(described_class).to receive(:com_or_dev_or_test_but_not_jh?).and_return(false)
        # rubocop: enable RSpec/AnyInstanceOf

        note_diff_files = table(:note_diff_files)

        migrate!

        expect(note_diff_files.columns.find { |c| c.name == 'diff_note_id' }.sql_type).to eq('bigint')
        expect(note_diff_files.columns.find do |c|
          c.name == 'diff_note_id_convert_to_bigint'
        end.sql_type).to eq('integer')
      end
    end

    context 'when self-managed instance with the `diff_note_id_convert_to_bigint` column already dropped ' do
      before do
        # As we call `schema_migrate_down!` before each example, and for this migration
        # `#down` is same as `#up`, we need to ensure we start from the expected state.
        connection = described_class.new.connection
        connection.execute('ALTER TABLE note_diff_files ALTER COLUMN diff_note_id TYPE bigint')
        connection.execute('ALTER TABLE note_diff_files DROP COLUMN IF EXISTS diff_note_id_convert_to_bigint')
      end

      it 'does not swap the columns' do
        # rubocop: disable RSpec/AnyInstanceOf
        allow_any_instance_of(described_class).to receive(:com_or_dev_or_test_but_not_jh?).and_return(false)
        # rubocop: enable RSpec/AnyInstanceOf

        note_diff_files = table(:note_diff_files)

        disable_migrations_output do
          reversible_migration do |migration|
            migration.before -> {
              note_diff_files.reset_column_information

              expect(note_diff_files.columns.find { |c| c.name == 'diff_note_id' }.sql_type).to eq('bigint')
              expect(note_diff_files.columns.find { |c| c.name == 'diff_note_id_convert_to_bigint' }).to be nil
            }

            migration.after -> {
              note_diff_files.reset_column_information

              expect(note_diff_files.columns.find { |c| c.name == 'diff_note_id' }.sql_type).to eq('bigint')
              expect(note_diff_files.columns.find { |c| c.name == 'diff_note_id_convert_to_bigint' }).to be nil
            }
          end
        end
      end
    end

    context 'when self-managed instance' do
      before do
        # As we call `schema_migrate_down!` before each example, and for this migration
        # `#down` is same as `#up`, we need to ensure we start from the expected state.
        connection = described_class.new.connection
        connection.execute('ALTER TABLE note_diff_files ALTER COLUMN diff_note_id TYPE integer')
        connection.execute('ALTER TABLE note_diff_files ADD COLUMN IF NOT EXISTS diff_note_id_convert_to_bigint bigint')
        connection.execute('ALTER TABLE note_diff_files ALTER COLUMN diff_note_id_convert_to_bigint TYPE bigint')
        connection.execute('DROP INDEX IF EXISTS index_note_diff_files_on_note_id_convert_to_bigint')
        connection.execute('CREATE OR REPLACE FUNCTION trigger_775287b6d67a() RETURNS trigger LANGUAGE plpgsql AS $$
          BEGIN NEW."diff_note_id_convert_to_bigint" := NEW."diff_note_id"; RETURN NEW; END; $$;')
      end

      it 'swaps the columns' do
        # rubocop: disable RSpec/AnyInstanceOf
        allow_any_instance_of(described_class).to receive(:com_or_dev_or_test_but_not_jh?).and_return(false)
        # rubocop: enable RSpec/AnyInstanceOf

        note_diff_files = table(:note_diff_files)

        disable_migrations_output do
          reversible_migration do |migration|
            migration.before -> {
              note_diff_files.reset_column_information

              expect(note_diff_files.columns.find { |c| c.name == 'diff_note_id' }.sql_type).to eq('integer')
              expect(note_diff_files.columns.find do |c|
                       c.name == 'diff_note_id_convert_to_bigint'
                     end.sql_type).to eq('bigint')
            }

            migration.after -> {
              note_diff_files.reset_column_information

              expect(note_diff_files.columns.find { |c| c.name == 'diff_note_id' }.sql_type).to eq('bigint')
              expect(note_diff_files.columns.find do |c|
                       c.name == 'diff_note_id_convert_to_bigint'
                     end.sql_type).to eq('integer')
            }
          end
        end
      end
    end
  end
end
