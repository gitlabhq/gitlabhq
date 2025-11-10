# frozen_string_literal: true

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

    if attributes.present?
      expect(batched_migrations).to all(have_attributes(attributes))
    else
      true
    end
  end

  define_method :does_not_match? do |migration|
    batched_migrations = if [gitlab_schema, table_name, column_name, job_arguments].all?(&:present?)
                           Gitlab::Database::BackgroundMigration::BatchedMigration
                             .for_configuration(gitlab_schema, migration, table_name, column_name, job_arguments)
                         else
                           Gitlab::Database::BackgroundMigration::BatchedMigration
                             .where(job_class_name: migration)
                         end

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
