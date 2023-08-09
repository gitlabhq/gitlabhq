# frozen_string_literal: true

require 'spec_helper'

require_migration!

RSpec.describe RetryCleanupBigintConversionForEventsForGitlabCom, :migration, feature_category: :database do
  let(:migration) { described_class.new }
  let(:connection) { migration.connection }
  let(:column_name) { 'target_id_convert_to_bigint' }
  let(:events_table) { table(:events) }

  before do
    allow(migration).to receive(:should_run?).and_return(should_run?)
  end

  shared_examples 'skips the up migration' do
    it "doesn't calls cleanup_conversion_of_integer_to_bigint method" do
      disable_migrations_output do
        expect(migration).not_to receive(:cleanup_conversion_of_integer_to_bigint)

        migration.up
      end
    end
  end

  shared_examples 'skips the down migration' do
    it "doesn't calls restore_conversion_of_integer_to_bigint method" do
      disable_migrations_output do
        expect(migration).not_to receive(:restore_conversion_of_integer_to_bigint)

        migration.down
      end
    end
  end

  describe '#up' do
    context 'when column still exists' do
      before do
        # Ensures the correct state of db before the test
        connection.execute('ALTER TABLE events ADD COLUMN IF NOT EXISTS target_id_convert_to_bigint integer')
        connection.execute('CREATE OR REPLACE FUNCTION trigger_cd1aeb22b34a() RETURNS trigger LANGUAGE plpgsql AS $$
          BEGIN NEW."target_id_convert_to_bigint" := NEW."target_id"; RETURN NEW; END; $$;')
        connection.execute('DROP TRIGGER IF EXISTS trigger_cd1aeb22b34a ON events')
        connection.execute('CREATE TRIGGER trigger_cd1aeb22b34a BEFORE INSERT OR UPDATE ON events FOR EACH ROW EXECUTE
          FUNCTION trigger_cd1aeb22b34a()')
      end

      context 'when is GitLab.com, dev, or test' do
        let(:should_run?) { true }

        it 'drop the temporary columns' do
          disable_migrations_output do
            reversible_migration do |migration|
              migration.before -> {
                events_table.reset_column_information
                expect(events_table.columns.find { |c| c.name == 'target_id_convert_to_bigint' }).not_to be_nil
              }

              migration.after -> {
                events_table.reset_column_information
                expect(events_table.columns.find { |c| c.name == 'target_id_convert_to_bigint' }).to be_nil
              }
            end
          end
        end
      end

      context 'when is a self-managed instance' do
        let(:should_run?) { false }

        it_behaves_like 'skips the up migration'
      end
    end

    context 'when column not exists' do
      before do
        connection.execute('ALTER TABLE events DROP COLUMN IF EXISTS target_id_convert_to_bigint')
      end

      context 'when is GitLab.com, dev, or test' do
        let(:should_run?) { true }

        it_behaves_like 'skips the up migration'
      end

      context 'when is a self-managed instance' do
        let(:should_run?) { false }

        it_behaves_like 'skips the up migration'
      end
    end
  end

  describe '#down' do
    context 'when column still exists' do
      before do
        # Ensures the correct state of db before the test
        connection.execute('ALTER TABLE events ADD COLUMN IF NOT EXISTS target_id_convert_to_bigint integer')
        connection.execute('CREATE OR REPLACE FUNCTION trigger_cd1aeb22b34a() RETURNS trigger LANGUAGE plpgsql AS $$
          BEGIN NEW."target_id_convert_to_bigint" := NEW."target_id"; RETURN NEW; END; $$;')
        connection.execute('DROP TRIGGER IF EXISTS trigger_cd1aeb22b34a ON events')
        connection.execute('CREATE TRIGGER trigger_cd1aeb22b34a BEFORE INSERT OR UPDATE ON events FOR EACH ROW EXECUTE
          FUNCTION trigger_cd1aeb22b34a()')
      end

      context 'when is GitLab.com, dev, or test' do
        let(:should_run?) { true }

        it_behaves_like 'skips the down migration'
      end

      context 'when is a self-managed instance' do
        let(:should_run?) { false }

        it_behaves_like 'skips the down migration'
      end
    end

    context 'when column not exists' do
      before do
        connection.execute('ALTER TABLE events DROP COLUMN IF EXISTS target_id_convert_to_bigint')
      end

      context 'when is GitLab.com, dev, or test' do
        let(:should_run?) { true }

        it 'restore the temporary columns' do
          disable_migrations_output do
            migration.down

            column = events_table.columns.find { |c| c.name == 'target_id_convert_to_bigint' }

            expect(column).not_to be_nil
            expect(column.sql_type).to eq('integer')
          end
        end
      end

      context 'when is a self-managed instance' do
        let(:should_run?) { false }

        it_behaves_like 'skips the down migration'
      end
    end
  end
end
