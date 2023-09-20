# frozen_string_literal: true

require 'spec_helper'
require_migration!

RSpec.describe SwapEventsTargetIdToBigintForSelfHosts, feature_category: :database do
  let(:connection) { described_class.new.connection }
  let(:events) { table(:events) }

  shared_examples 'column `target_id_convert_to_bigint` is already dropped' do
    before do
      connection.execute('ALTER TABLE events ALTER COLUMN target_id TYPE bigint')
      connection.execute('ALTER TABLE events DROP COLUMN IF EXISTS target_id_convert_to_bigint')
    end

    it 'does not swap the columns' do
      disable_migrations_output do
        reversible_migration do |migration|
          migration.before -> {
            events.reset_column_information

            expect(events.columns.find { |c| c.name == 'target_id' }.sql_type).to eq('bigint')
            expect(events.columns.find { |c| c.name == 'target_id_convert_to_bigint' }).to be_nil
          }

          migration.after -> {
            events.reset_column_information

            expect(events.columns.find { |c| c.name == 'target_id' }.sql_type).to eq('bigint')
            expect(events.columns.find { |c| c.name == 'target_id_convert_to_bigint' }).to be_nil
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

      it_behaves_like 'column `target_id_convert_to_bigint` is already dropped'
    end

    context 'when self-managed instance with the `target_id_convert_to_bigint` column already dropped' do
      let(:com_or_dev_or_test_but_not_jh?) { false }

      it_behaves_like 'column `target_id_convert_to_bigint` is already dropped'
    end

    context 'when self-managed instance columns already swapped' do
      let(:com_or_dev_or_test_but_not_jh?) { false }

      before do
        connection.execute('ALTER TABLE events ALTER COLUMN target_id TYPE bigint')
        connection.execute(
          'ALTER TABLE events ADD COLUMN IF NOT EXISTS target_id_convert_to_bigint integer'
        )

        disable_migrations_output { migrate! }
      end

      after do
        connection.execute('ALTER TABLE events DROP COLUMN IF EXISTS target_id_convert_to_bigint')
      end

      it 'does not swaps the columns' do
        expect(events.columns.find { |c| c.name == 'target_id' }.sql_type).to eq('bigint')
        expect(events.columns.find { |c| c.name == 'target_id_convert_to_bigint' }.sql_type).to(
          eq('integer')
        )
      end
    end

    context 'when self-managed instance' do
      let(:com_or_dev_or_test_but_not_jh?) { false }

      before do
        connection.execute('ALTER TABLE events ALTER COLUMN target_id TYPE integer')
        connection.execute('ALTER TABLE events ADD COLUMN IF NOT EXISTS target_id_convert_to_bigint bigint')
        connection.execute('CREATE OR REPLACE FUNCTION trigger_cd1aeb22b34a() RETURNS trigger LANGUAGE plpgsql AS $$
          BEGIN NEW."target_id_convert_to_bigint" := NEW."target_id"; RETURN NEW; END; $$;')
      end

      after do
        connection.execute('ALTER TABLE events DROP COLUMN IF EXISTS target_id_convert_to_bigint')
      end

      it 'swaps the columns' do
        disable_migrations_output do
          reversible_migration do |migration|
            migration.before -> {
              events.reset_column_information

              expect(events.columns.find { |c| c.name == 'target_id' }.sql_type).to eq('integer')
              expect(events.columns.find { |c| c.name == 'target_id_convert_to_bigint' }.sql_type).to(
                eq('bigint')
              )
            }

            migration.after -> {
              events.reset_column_information

              expect(events.columns.find { |c| c.name == 'target_id' }.sql_type).to eq('bigint')
              expect(events.columns.find { |c| c.name == 'target_id_convert_to_bigint' }.sql_type).to(
                eq('integer')
              )
            }
          end
        end
      end
    end
  end
end
