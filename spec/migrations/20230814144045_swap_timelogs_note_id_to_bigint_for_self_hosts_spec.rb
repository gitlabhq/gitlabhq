# frozen_string_literal: true

require 'spec_helper'
require_migration!

RSpec.describe SwapTimelogsNoteIdToBigintForSelfHosts, feature_category: :database do
  let(:connection) { described_class.new.connection }
  let(:timelogs) { table(:timelogs) }

  shared_examples 'column `note_id_convert_to_bigint` is already dropped' do
    before do
      connection.execute('ALTER TABLE timelogs ALTER COLUMN note_id TYPE bigint')
      connection.execute('ALTER TABLE timelogs DROP COLUMN IF EXISTS note_id_convert_to_bigint')
    end

    it 'does not swaps the columns' do
      disable_migrations_output do
        reversible_migration do |migration|
          migration.before -> {
            timelogs.reset_column_information

            expect(timelogs.columns.find { |c| c.name == 'note_id' }.sql_type).to eq('bigint')
            expect(timelogs.columns.find { |c| c.name == 'note_id_convert_to_bigint' }).to be_nil
          }

          migration.after -> {
            timelogs.reset_column_information

            expect(timelogs.columns.find { |c| c.name == 'note_id' }.sql_type).to eq('bigint')
            expect(timelogs.columns.find { |c| c.name == 'note_id_convert_to_bigint' }).to be_nil
          }
        end
      end
    end
  end

  describe '#up' do
    before do
      # rubocop:disable RSpec/AnyInstanceOf
      allow_any_instance_of(described_class).to(
        receive(:com_or_dev_or_test_but_not_jh?).and_return(com_or_dev_or_test_but_not_jh?)
      )
      # rubocop:enable RSpec/AnyInstanceOf
    end

    context 'when GitLab.com, dev, or test' do
      let(:com_or_dev_or_test_but_not_jh?) { true }

      it_behaves_like 'column `note_id_convert_to_bigint` is already dropped'
    end

    context 'when self-managed instance with the `note_id_convert_to_bigint` column already dropped' do
      let(:com_or_dev_or_test_but_not_jh?) { false }

      it_behaves_like 'column `note_id_convert_to_bigint` is already dropped'
    end

    context 'when self-managed instance columns already swapped' do
      let(:com_or_dev_or_test_but_not_jh?) { false }

      before do
        connection.execute('ALTER TABLE timelogs ALTER COLUMN note_id TYPE bigint')
        connection.execute(
          'ALTER TABLE timelogs ADD COLUMN IF NOT EXISTS note_id_convert_to_bigint integer'
        )

        disable_migrations_output { migrate! }
      end

      after do
        connection.execute('ALTER TABLE timelogs DROP COLUMN IF EXISTS note_id_convert_to_bigint')
      end

      it 'does not swaps the columns' do
        expect(timelogs.columns.find { |c| c.name == 'note_id' }.sql_type).to eq('bigint')
        expect(timelogs.columns.find { |c| c.name == 'note_id_convert_to_bigint' }.sql_type).to(
          eq('integer')
        )
      end
    end

    context 'when self-managed instance' do
      let(:com_or_dev_or_test_but_not_jh?) { false }

      before do
        connection.execute('ALTER TABLE timelogs ALTER COLUMN note_id TYPE integer')
        connection.execute(
          'ALTER TABLE timelogs ADD COLUMN IF NOT EXISTS note_id_convert_to_bigint bigint'
        )
        connection.execute('ALTER TABLE timelogs ALTER COLUMN note_id_convert_to_bigint TYPE bigint')
        connection.execute('DROP INDEX IF EXISTS index_timelogs_on_note_id_convert_to_bigint CASCADE')
        connection.execute('CREATE OR REPLACE FUNCTION trigger_428d92773fe7() RETURNS trigger LANGUAGE plpgsql AS $$
          BEGIN NEW."note_id_convert_to_bigint" := NEW."note_id"; RETURN NEW; END; $$;')
      end

      after do
        connection.execute('ALTER TABLE timelogs DROP COLUMN IF EXISTS note_id_convert_to_bigint')
      end

      it 'swaps the columns' do
        disable_migrations_output do
          reversible_migration do |migration|
            migration.before -> {
              timelogs.reset_column_information

              expect(timelogs.columns.find { |c| c.name == 'note_id' }.sql_type).to eq('integer')
              expect(timelogs.columns.find { |c| c.name == 'note_id_convert_to_bigint' }.sql_type).to(
                eq('bigint')
              )
            }

            migration.after -> {
              timelogs.reset_column_information

              expect(timelogs.columns.find { |c| c.name == 'note_id' }.sql_type).to eq('bigint')
              expect(timelogs.columns.find { |c| c.name == 'note_id_convert_to_bigint' }.sql_type).to(
                eq('integer')
              )
            }
          end
        end
      end
    end
  end
end
