# frozen_string_literal: true

module Database
  module MigrationTestingHelpers
    def define_background_migration(
      name, with_base_class: true, scoping: nil, block_context: :test,
      cursor_columns: nil, &block)
      raise "block_context must be :test or :migration" unless [:test, :migration].include?(block_context)

      klass = Class.new(with_base_class ? Gitlab::BackgroundMigration::BatchedMigrationJob : Object) do
        operation_name :update if with_base_class

        if block_context == :test
          # Can't simply def perform here as we won't have access to the block,
          # similarly can't define_method(:perform, &block) here as it would change the block receiver
          define_method(:perform) { |*args| yield(*args) }
        elsif block_context == :migration
          define_method(:perform, &block)
        end

        scope_to(scoping) if scoping

        cursor(*cursor_columns) if cursor_columns
      end

      stub_const("Gitlab::BackgroundMigration::#{name}", klass)
      klass
    end

    # Returns a hash of migration_class -> number of times perform was called.
    # Sets up instrumentation of the provided array of migrations, as instances of their perform methods are called,
    # the values in the hash update to count the calls.
    def record_migration_call_counts(migrations)
      call_counts = migrations.index_with { |_m| 0 }
      migrations.each do |migration|
        allow_next_instances_of(migration, nil) do |migration_instance|
          allow(migration_instance).to receive(:perform).and_wrap_original do |method, *args, **kwargs|
            call_counts[migration] += 1
            method.call(*args, **kwargs)
          end
        end
      end

      call_counts
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
      call_counts = record_migration_call_counts(migrations_to_run_counts.keys)

      yield

      expect(call_counts).to eq(migrations_to_run_counts)

      expect_recorded_migration_runs(migrations_to_run_counts)
    end
  end
end
