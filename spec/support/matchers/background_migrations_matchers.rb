# frozen_string_literal: true

RSpec::Matchers.define :be_background_migration_with_arguments do |arguments|
  define_method :matches? do |migration|
    expect do
      Gitlab::BackgroundMigration.perform(migration, arguments)
    end.not_to raise_error
  end
end

RSpec::Matchers.define :be_scheduled_delayed_migration do |delay, *expected|
  match(notify_expectation_failures: true) do |migration|
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
  match(notify_expectation_failures: true) do |migration|
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
  match(notify_expectation_failures: true) do |migration|
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

RSpec::Matchers.define :have_scheduled_batched_migration do |gitlab_schema: nil, table_name: nil, column_name: nil, job_arguments: [], **attributes|
  define_method :matches? do |migration|
    reset_column_information(Gitlab::Database::BackgroundMigration::BatchedMigration)

    if gitlab_schema.nil?
      expect(described_class.allowed_gitlab_schemas.count).to(
        be(1),
        "Please specify a gitlab_schema, since more than one schema is allowed for #{described_class}: " \
          "#{described_class.allowed_gitlab_schemas}"
      )
      gitlab_schema = described_class.allowed_gitlab_schemas.first
    end

    batched_migrations =
      Gitlab::Database::BackgroundMigration::BatchedMigration
        .for_configuration(gitlab_schema, migration, table_name, column_name, job_arguments)

    expect(batched_migrations.count).to be(1)

    # the :batch_min_value & :batch_max_value attribute argument values get applied to the
    # :min_value & :max_value columns on the database. Here we change the attribute names
    # for the rspec have_attributes matcher used below to pass
    attributes[:min_value] = attributes.delete :batch_min_value if attributes.include?(:batch_min_value)
    attributes[:max_value] = attributes.delete :batch_max_value if attributes.include?(:batch_max_value)

    expect(batched_migrations).to all(have_attributes(attributes)) if attributes.present?
  end

  define_method :does_not_match? do |migration|
    batched_migrations =
      Gitlab::Database::BackgroundMigration::BatchedMigration
        .where(job_class_name: migration)

    expect(batched_migrations.count).to(
      be(0),
      "#{migration} should not be scheduled, found #{batched_migrations.count} times"
    )
  end
end

RSpec::Matchers.define :be_finalize_background_migration_of do |migration|
  define_method :matches? do |klass|
    expect_next_instance_of(klass) do |instance|
      expect(instance).to receive(:finalize_background_migration).with(migration)
    end
  end
end

RSpec::Matchers.define :ensure_batched_background_migration_is_finished_for do |migration_arguments|
  define_method :matches? do |klass|
    expect_next_instance_of(klass) do |instance|
      expect(instance).to receive(:ensure_batched_background_migration_is_finished).with(migration_arguments)
    end
  end

  define_method :does_not_match? do |klass|
    expect_next_instance_of(klass) do |instance|
      expect(instance).not_to receive(:ensure_batched_background_migration_is_finished).with(migration_arguments)
    end
  end
end
