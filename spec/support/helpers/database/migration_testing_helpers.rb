# frozen_string_literal: true

module Database
  module MigrationTestingHelpers
    def define_background_migration(name)
      klass = Class.new do
        # Can't simply def perform here as we won't have access to the block,
        # similarly can't define_method(:perform, &block) here as it would change the block receiver
        define_method(:perform) { |*args| yield(*args) }
      end
      stub_const("Gitlab::BackgroundMigration::#{name}", klass)
      klass
    end

    def expect_migration_call_counts(migrations_to_calls)
      migrations_to_calls.each do |migration, calls|
        expect_next_instances_of(migration, calls) do |m|
          expect(m).to receive(:perform).and_call_original
        end
      end
    end

    def expect_recorded_migration_runs(migrations_to_runs)
      migrations_to_runs.each do |migration, runs|
        path = File.join(result_dir, migration.name.demodulize)
        if runs.zero?
          expect(Pathname(path)).not_to be_exist
        else
          num_subdirs = Pathname(path).children.count(&:directory?)
          expect(num_subdirs).to eq(runs)
        end
      end
    end

    def expect_migration_runs(migrations_to_run_counts)
      expect_migration_call_counts(migrations_to_run_counts)

      yield

      expect_recorded_migration_runs(migrations_to_run_counts)
    end
  end
end
