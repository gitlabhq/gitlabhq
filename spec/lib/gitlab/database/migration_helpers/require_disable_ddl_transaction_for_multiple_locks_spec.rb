# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::Database::MigrationHelpers::RequireDisableDdlTransactionForMultipleLocks,
  query_analyzers: false, feature_category: :database do
  let_it_be(:multiple_locks_migration_module) do
    Module.new do
      include Gitlab::Database::MigrationHelpers::LooseForeignKeyHelpers

      def partitioned_table
        :ci_runner_machines
      end

      def tables
        %i[
          instance_type_ci_runner_machines group_type_ci_runner_machines project_type_ci_runner_machines
          ci_runner_machines
        ].freeze
      end

      def up
        drop_trigger(:ci_runner_machines_archived, :ci_runner_machines_loose_fk_trigger)

        tables.each do |table|
          untrack_record_deletions(table)

          track_record_deletions_override_table_name(table, partitioned_table)
        end
      end

      def down
        tables.each do |table|
          untrack_record_deletions(table)
        end

        execute(<<~SQL.squish)
          CREATE TRIGGER #{record_deletion_trigger_name(partitioned_table)}
          AFTER DELETE ON ci_runner_machines_archived REFERENCING OLD TABLE AS old_table
          FOR EACH STATEMENT
          EXECUTE FUNCTION #{INSERT_FUNCTION_NAME}();
        SQL
      end
    end
  end

  let_it_be(:multiple_locks_on_single_table_migration_module) do
    Module.new do
      def up
        create_table :taggings do |t|
          t.bigint :tag_id
          t.string :taggable_type
          t.bigint :tagger_id
          t.string :tagger_type
          t.string :context
          t.timestamp :created_at
          t.bigint :taggable_id

          t.index :tag_id, name: 'index_taggings_on_tag_id'
          t.index [:taggable_id, :taggable_type, :context],
            name: 'index_taggings_on_taggable_id_and_taggable_type_and_context'
          t.index [:tag_id, :taggable_id, :taggable_type, :context, :tagger_id, :tagger_type],
            unique: true,
            name: 'taggings_idx'
        end
      end

      def down
        drop_table :taggings
      end
    end
  end

  let_it_be(:multiple_locks_single_statement_migration_module) do
    Module.new do
      def up
        # Simulate an operation that locks multiple tables
        execute "LOCK TABLE ci_runners, ci_runner_machines IN ACCESS EXCLUSIVE MODE"
      end

      def down; end
    end
  end

  let(:migration_base_klass) do
    Class.new(Gitlab::Database::Migration[migration_version])
  end

  before do
    stub_const('TestMultipleLocksMigrationModule', multiple_locks_migration_module)
    stub_const('TestMultipleLocksOnSingleTableMigrationModule', multiple_locks_on_single_table_migration_module)
    stub_const('TestMultipleLocksInSingleStmtMigrationModule', multiple_locks_single_statement_migration_module)

    migration.instance_variable_set(:@_defining_file, 'db/migrate/00000000000000_example.rb')
    migration.milestone '18.0'
  end

  context 'when executing migrations' do
    subject(:migrate_up) { migration.migrate(:up) }

    let(:migration_version) { 2.3 }

    context 'when migration locks multiple tables in single statement' do
      let(:migration) { migration_base_klass.extend(TestMultipleLocksInSingleStmtMigrationModule) }

      it 'does not raise an error' do
        expect { migrate_up }.not_to raise_error
      end
    end

    context 'when migration locks multiple tables across multiple statements' do
      let(:migration) { migration_base_klass.extend(TestMultipleLocksMigrationModule) }

      context 'when migration does not include module' do
        let(:migration_version) { 2.2 }

        it 'does not raise an error' do
          expect { migrate_up }.not_to raise_error
        end
      end

      context 'when migration includes module' do
        let(:migration_version) { 2.3 }

        it 'fails with error about multiple locks' do
          expect do
            migration.migrate(:up)
          end.to raise_error(/This migration locks multiple tables across different statements/)
        end

        context 'when migration disables ddl transaction' do
          let(:migration) do
            Class.new(Gitlab::Database::Migration[migration_version]) do
              disable_ddl_transaction!

              extend TestMultipleLocksMigrationModule
            end
          end

          it 'does not raise an error' do
            expect { migrate_up }.not_to raise_error
          end
        end

        context 'when migration skips check' do
          let(:migration) do
            Class.new(Gitlab::Database::Migration[migration_version]) do
              skip_require_disable_ddl_transactions!

              extend TestMultipleLocksMigrationModule
            end
          end

          it 'does not raise an error' do
            expect { migrate_up }.not_to raise_error
          end
        end
      end
    end

    context 'when migration locks single table across multiple statements' do
      let(:migration) { migration_base_klass.extend(TestMultipleLocksOnSingleTableMigrationModule) }

      context 'when migration does not include module' do
        let(:migration_version) { 2.2 }

        it 'does not raise an error' do
          expect { migrate_up }.not_to raise_error
        end
      end

      context 'when migration includes module' do
        let(:migration_version) { 2.3 }

        it 'does not raise an error' do
          expect { migrate_up }.not_to raise_error
        end
      end
    end
  end
end
