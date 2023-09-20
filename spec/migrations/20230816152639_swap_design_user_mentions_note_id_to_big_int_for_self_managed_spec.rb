# frozen_string_literal: true

require 'spec_helper'

require_migration!

RSpec.describe SwapDesignUserMentionsNoteIdToBigIntForSelfManaged, feature_category: :database do
  let(:connection) { described_class.new.connection }
  let(:design_user_mentions) { table(:design_user_mentions) }

  shared_examples 'column `note_id_convert_to_bigint` is already dropped' do
    before do
      connection.execute('ALTER TABLE design_user_mentions ALTER COLUMN note_id TYPE bigint')
      connection.execute('ALTER TABLE design_user_mentions DROP COLUMN IF EXISTS note_id_convert_to_bigint')
    end

    it 'does not swap the columns' do
      disable_migrations_output do
        reversible_migration do |migration|
          migration.before -> {
            design_user_mentions.reset_column_information

            expect(design_user_mentions.columns.find { |c| c.name == 'note_id' }.sql_type).to eq('bigint')
            expect(design_user_mentions.columns.find { |c| c.name == 'note_id_convert_to_bigint' }).to be_nil
          }

          migration.after -> {
            design_user_mentions.reset_column_information

            expect(design_user_mentions.columns.find { |c| c.name == 'note_id' }.sql_type).to eq('bigint')
            expect(design_user_mentions.columns.find { |c| c.name == 'note_id_convert_to_bigint' }).to be_nil
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
        connection.execute('ALTER TABLE design_user_mentions ALTER COLUMN note_id TYPE bigint')
        connection.execute(
          'ALTER TABLE design_user_mentions ADD COLUMN IF NOT EXISTS note_id_convert_to_bigint integer'
        )

        disable_migrations_output { migrate! }
      end

      after do
        connection.execute('ALTER TABLE design_user_mentions DROP COLUMN IF EXISTS note_id_convert_to_bigint')
      end

      it 'does not swaps the columns' do
        expect(design_user_mentions.columns.find { |c| c.name == 'note_id' }.sql_type).to eq('bigint')
        expect(design_user_mentions.columns.find { |c| c.name == 'note_id_convert_to_bigint' }.sql_type).to(
          eq('integer')
        )
      end
    end

    context 'when self-managed instance' do
      let(:com_or_dev_or_test_but_not_jh?) { false }

      before do
        connection.execute('ALTER TABLE design_user_mentions ALTER COLUMN note_id TYPE integer')
        connection.execute('ALTER TABLE design_user_mentions ADD COLUMN IF NOT EXISTS note_id_convert_to_bigint bigint')
        connection.execute('CREATE OR REPLACE FUNCTION trigger_3dc62927cae8() RETURNS trigger LANGUAGE plpgsql AS $$
          BEGIN NEW."note_id_convert_to_bigint" := NEW."note_id"; RETURN NEW; END; $$;')
      end

      after do
        connection.execute('ALTER TABLE design_user_mentions DROP COLUMN IF EXISTS note_id_convert_to_bigint')
      end

      it 'swaps the columns' do
        disable_migrations_output do
          reversible_migration do |migration|
            migration.before -> {
              design_user_mentions.reset_column_information

              expect(design_user_mentions.columns.find { |c| c.name == 'note_id' }.sql_type).to eq('integer')
              expect(design_user_mentions.columns.find { |c| c.name == 'note_id_convert_to_bigint' }.sql_type).to(
                eq('bigint')
              )
            }

            migration.after -> {
              design_user_mentions.reset_column_information

              expect(design_user_mentions.columns.find { |c| c.name == 'note_id' }.sql_type).to eq('bigint')
              expect(design_user_mentions.columns.find { |c| c.name == 'note_id_convert_to_bigint' }.sql_type).to(
                eq('integer')
              )
            }
          end
        end
      end
    end
  end
end
