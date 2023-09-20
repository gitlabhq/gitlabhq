# frozen_string_literal: true

require 'spec_helper'
require_migration!

RSpec.describe SwapNotesIdToBigintForSelfManaged, feature_category: :database do
  let(:connection) { described_class.new.connection }

  shared_examples 'column `id_convert_to_bigint` is already dropped' do
    before do
      connection.execute('ALTER TABLE notes ALTER COLUMN id TYPE bigint')
      connection.execute('ALTER TABLE notes DROP COLUMN IF EXISTS id_convert_to_bigint')
    end

    after do
      connection.execute('ALTER TABLE notes DROP COLUMN IF EXISTS id_convert_to_bigint')
    end

    it 'does not swaps the columns' do
      disable_migrations_output do
        reversible_migration do |migration|
          migration.before -> {
            notes_table.reset_column_information

            expect(notes_table.columns.find { |c| c.name == 'id' }.sql_type).to eq('bigint')
            expect(notes_table.columns.find { |c| c.name == 'id_convert_to_bigint' }).to be_nil
          }

          migration.after -> {
            notes_table.reset_column_information

            expect(notes_table.columns.find { |c| c.name == 'id' }.sql_type).to eq('bigint')
            expect(notes_table.columns.find { |c| c.name == 'id_convert_to_bigint' }).to be_nil
          }
        end
      end
    end
  end

  describe '#up' do
    let!(:notes_table) { table(:notes) }

    before do
      # rubocop:disable RSpec/AnyInstanceOf
      allow_any_instance_of(described_class).to(
        receive(:com_or_dev_or_test_but_not_jh?).and_return(com_or_dev_or_test_but_not_jh?)
      )
      # rubocop:enable RSpec/AnyInstanceOf
    end

    context 'when GitLab.com, dev, or test' do
      let(:com_or_dev_or_test_but_not_jh?) { true }

      it_behaves_like 'column `id_convert_to_bigint` is already dropped'
    end

    context 'when self-managed instance with the `id_convert_to_bigint` column already dropped' do
      let(:com_or_dev_or_test_but_not_jh?) { false }

      it_behaves_like 'column `id_convert_to_bigint` is already dropped'
    end

    context 'when self-managed instance columns already swapped' do
      let(:com_or_dev_or_test_but_not_jh?) { false }

      before do
        connection.execute('ALTER TABLE notes ALTER COLUMN id TYPE bigint')
        connection.execute('ALTER TABLE notes ADD COLUMN IF NOT EXISTS id_convert_to_bigint integer')

        disable_migrations_output { migrate! }
      end

      after do
        connection.execute('ALTER TABLE notes DROP COLUMN IF EXISTS id_convert_to_bigint')
      end

      it 'does not swaps the columns' do
        expect(notes_table.columns.find { |c| c.name == 'id' }.sql_type).to eq('bigint')
        expect(notes_table.columns.find { |c| c.name == 'id_convert_to_bigint' }.sql_type).to eq('integer')
      end
    end

    context 'when self-managed instance' do
      let(:com_or_dev_or_test_but_not_jh?) { false }

      before do
        connection.execute('ALTER TABLE notes ALTER COLUMN id TYPE integer')
        connection.execute('ALTER TABLE notes ADD COLUMN IF NOT EXISTS id_convert_to_bigint bigint')
        connection.execute('ALTER TABLE notes ALTER COLUMN id_convert_to_bigint TYPE bigint')
        connection.execute('DROP INDEX IF EXISTS index_notes_on_id_convert_to_bigint CASCADE')
        connection.execute('CREATE OR REPLACE FUNCTION trigger_080e73845bfd() RETURNS trigger LANGUAGE plpgsql AS $$
          BEGIN NEW."id_convert_to_bigint" := NEW."id"; RETURN NEW; END; $$;')
      end

      after do
        connection.execute('ALTER TABLE notes DROP COLUMN IF EXISTS id_convert_to_bigint')
      end

      it 'swaps the columns' do
        disable_migrations_output do
          reversible_migration do |migration|
            migration.before -> {
              notes_table.reset_column_information

              expect(notes_table.columns.find { |c| c.name == 'id' }.sql_type).to eq('integer')
              expect(notes_table.columns.find { |c| c.name == 'id_convert_to_bigint' }.sql_type).to eq('bigint')
            }

            migration.after -> {
              notes_table.reset_column_information

              expect(notes_table.columns.find { |c| c.name == 'id' }.sql_type).to eq('bigint')
              expect(notes_table.columns.find { |c| c.name == 'id_convert_to_bigint' }.sql_type).to eq('integer')
            }
          end
        end
      end
    end
  end
end
