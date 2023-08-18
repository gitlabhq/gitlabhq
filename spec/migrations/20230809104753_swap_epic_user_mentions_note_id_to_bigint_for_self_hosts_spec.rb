# frozen_string_literal: true

require 'spec_helper'
require_migration!

RSpec.describe SwapEpicUserMentionsNoteIdToBigintForSelfHosts, feature_category: :database do
  describe '#up' do
    context 'when GitLab.com, dev, or test' do
      before do
        # As we call `schema_migrate_down!` before each example, and for this migration
        # `#down` is same as `#up`, we need to ensure we start from the expected state.
        connection = described_class.new.connection
        connection.execute('ALTER TABLE epic_user_mentions ALTER COLUMN note_id TYPE bigint')
        connection.execute('ALTER TABLE epic_user_mentions DROP COLUMN IF EXISTS note_id_convert_to_bigint')
      end

      it 'does not swap the columns' do
        # rubocop: disable RSpec/AnyInstanceOf
        allow_any_instance_of(described_class).to receive(:com_or_dev_or_test_but_not_jh?).and_return(true)
        # rubocop: enable RSpec/AnyInstanceOf

        epic_user_mentions = table(:epic_user_mentions)

        disable_migrations_output do
          reversible_migration do |migration|
            migration.before -> {
              epic_user_mentions.reset_column_information

              expect(epic_user_mentions.columns.find { |c| c.name == 'note_id' }.sql_type).to eq('bigint')
              expect(epic_user_mentions.columns.find { |c| c.name == 'note_id_convert_to_bigint' }).to be nil
            }

            migration.after -> {
              epic_user_mentions.reset_column_information

              expect(epic_user_mentions.columns.find { |c| c.name == 'note_id' }.sql_type).to eq('bigint')
              expect(epic_user_mentions.columns.find { |c| c.name == 'note_id_convert_to_bigint' }).to be nil
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
        connection.execute('ALTER TABLE epic_user_mentions ALTER COLUMN note_id TYPE bigint')
        connection.execute('ALTER TABLE epic_user_mentions ADD COLUMN IF NOT EXISTS note_id_convert_to_bigint integer')
      end

      after do
        connection = described_class.new.connection
        connection.execute('ALTER TABLE epic_user_mentions DROP COLUMN IF EXISTS note_id_convert_to_bigint')
      end

      it 'does not swap the columns' do
        # rubocop: disable RSpec/AnyInstanceOf
        allow_any_instance_of(described_class).to receive(:com_or_dev_or_test_but_not_jh?).and_return(false)
        # rubocop: enable RSpec/AnyInstanceOf

        epic_user_mentions = table(:epic_user_mentions)

        migrate!

        expect(epic_user_mentions.columns.find { |c| c.name == 'note_id' }.sql_type).to eq('bigint')
        expect(epic_user_mentions.columns.find do |c|
          c.name == 'note_id_convert_to_bigint'
        end.sql_type).to eq('integer')
      end
    end

    context 'when self-managed instance with the `note_id_convert_to_bigint` column already dropped ' do
      before do
        # As we call `schema_migrate_down!` before each example, and for this migration
        # `#down` is same as `#up`, we need to ensure we start from the expected state.
        connection = described_class.new.connection
        connection.execute('ALTER TABLE epic_user_mentions ALTER COLUMN note_id TYPE bigint')
        connection.execute('ALTER TABLE epic_user_mentions DROP COLUMN IF EXISTS note_id_convert_to_bigint')
      end

      it 'does not swap the columns' do
        # rubocop: disable RSpec/AnyInstanceOf
        allow_any_instance_of(described_class).to receive(:com_or_dev_or_test_but_not_jh?).and_return(false)
        # rubocop: enable RSpec/AnyInstanceOf

        epic_user_mentions = table(:epic_user_mentions)

        disable_migrations_output do
          reversible_migration do |migration|
            migration.before -> {
              epic_user_mentions.reset_column_information

              expect(epic_user_mentions.columns.find { |c| c.name == 'note_id' }.sql_type).to eq('bigint')
              expect(epic_user_mentions.columns.find { |c| c.name == 'note_id_convert_to_bigint' }).to be nil
            }

            migration.after -> {
              epic_user_mentions.reset_column_information

              expect(epic_user_mentions.columns.find { |c| c.name == 'note_id' }.sql_type).to eq('bigint')
              expect(epic_user_mentions.columns.find { |c| c.name == 'note_id_convert_to_bigint' }).to be nil
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
        connection.execute('ALTER TABLE epic_user_mentions ALTER COLUMN note_id TYPE integer')
        connection.execute('ALTER TABLE epic_user_mentions ADD COLUMN IF NOT EXISTS note_id_convert_to_bigint bigint')
        connection.execute('ALTER TABLE epic_user_mentions ALTER COLUMN note_id_convert_to_bigint TYPE bigint')
        connection.execute('DROP INDEX IF EXISTS index_epic_user_mentions_on_note_id_convert_to_bigint')
        connection.execute('CREATE OR REPLACE FUNCTION trigger_c5a5f48f12b0() RETURNS trigger LANGUAGE plpgsql AS $$
          BEGIN NEW."note_id_convert_to_bigint" := NEW."note_id"; RETURN NEW; END; $$;')
      end

      after do
        connection = described_class.new.connection
        connection.execute('ALTER TABLE epic_user_mentions DROP COLUMN IF EXISTS note_id_convert_to_bigint')
      end

      it 'swaps the columns' do
        # rubocop: disable RSpec/AnyInstanceOf
        allow_any_instance_of(described_class).to receive(:com_or_dev_or_test_but_not_jh?).and_return(false)
        # rubocop: enable RSpec/AnyInstanceOf

        epic_user_mentions = table(:epic_user_mentions)

        disable_migrations_output do
          reversible_migration do |migration|
            migration.before -> {
              epic_user_mentions.reset_column_information

              expect(epic_user_mentions.columns.find { |c| c.name == 'note_id' }.sql_type).to eq('integer')
              expect(epic_user_mentions.columns.find do |c|
                       c.name == 'note_id_convert_to_bigint'
                     end.sql_type).to eq('bigint')
            }

            migration.after -> {
              epic_user_mentions.reset_column_information

              expect(epic_user_mentions.columns.find { |c| c.name == 'note_id' }.sql_type).to eq('bigint')
              expect(epic_user_mentions.columns.find do |c|
                       c.name == 'note_id_convert_to_bigint'
                     end.sql_type).to eq('integer')
            }
          end
        end
      end
    end
  end
end
