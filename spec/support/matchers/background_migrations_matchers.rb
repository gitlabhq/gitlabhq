# frozen_string_literal: true

RSpec::Matchers.define :be_background_migration_with_arguments do |arguments|
  define_method :matches? do |migration|
    expect do
      Gitlab::BackgroundMigration.perform(migration, arguments)
    end.not_to raise_error
  end
end

RSpec::Matchers.define :be_scheduled_delayed_migration do |delay, *expected|
  define_method :matches? do |migration|
    expect(migration).to be_background_migration_with_arguments(expected)

    BackgroundMigrationWorker.jobs.any? do |job|
      job['args'] == [migration, expected] &&
        job['at'].to_i == (delay.to_i + Time.now.to_i)
    end
  end

  failure_message do |migration|
    "Migration `#{migration}` with args `#{expected.inspect}` " \
      "not scheduled in expected time! Expected any of `#{BackgroundMigrationWorker.jobs.map { |j| j['args'] }}` to be `#{[migration, expected]}` " \
      "and any of `#{BackgroundMigrationWorker.jobs.map { |j| j['at'].to_i }}` to be `#{delay.to_i + Time.now.to_i}` (`#{delay.to_i}` + `#{Time.now.to_i}`)."
  end
end

RSpec::Matchers.define :be_scheduled_migration do |*expected|
  define_method :matches? do |migration|
    expect(migration).to be_background_migration_with_arguments(expected)

    BackgroundMigrationWorker.jobs.any? do |job|
      args = job['args'].size == 1 ? [BackgroundMigrationWorker.jobs[0]['args'][0], []] : job['args']
      args == [migration, expected]
    end
  end

  failure_message do |migration|
    "Migration `#{migration}` with args `#{expected.inspect}` not scheduled!"
  end
end

RSpec::Matchers.define :be_scheduled_migration_with_multiple_args do |*expected|
  define_method :matches? do |migration|
    expect(migration).to be_background_migration_with_arguments(expected)

    BackgroundMigrationWorker.jobs.any? do |job|
      args = job['args'].size == 1 ? [BackgroundMigrationWorker.jobs[0]['args'][0], []] : job['args']
      args[0] == migration && compare_args(args, expected)
    end
  end

  failure_message do |migration|
    "Migration `#{migration}` with args `#{expected.inspect}` not scheduled!"
  end

  def compare_args(args, expected)
    args[1].map.with_index do |arg, i|
      arg.is_a?(Array) ? same_arrays?(arg, expected[i]) : arg == expected[i]
    end.all?
  end

  def same_arrays?(arg, expected)
    arg.sort == expected.sort
  end
end

RSpec::Matchers.define :have_scheduled_batched_migration do |table_name: nil, column_name: nil, job_arguments: [], **attributes|
  define_method :matches? do |migration|
    # Default arguments passed by BatchedMigrationWrapper (values don't matter here)
    expect(migration).to be_background_migration_with_arguments([
      _start_id = 1,
      _stop_id = 2,
      table_name,
      column_name,
      _sub_batch_size = 10,
      _pause_ms = 100,
      *job_arguments
    ])

    batched_migrations =
      Gitlab::Database::BackgroundMigration::BatchedMigration
        .for_configuration(migration, table_name, column_name, job_arguments)

    expect(batched_migrations.count).to be(1)
    expect(batched_migrations).to all(have_attributes(attributes)) if attributes.present?
  end

  define_method :does_not_match? do |migration|
    batched_migrations =
      Gitlab::Database::BackgroundMigration::BatchedMigration
        .where(job_class_name: migration)

    expect(batched_migrations.count).to be(0)
  end
end
