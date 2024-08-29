# frozen_string_literal: true

RSpec.configure do |config|
  # The :each scope runs "inside" the example, so this hook ensures the DB is in the
  # correct state before any examples' before hooks are called. This prevents a
  # problem where `ScheduleIssuesClosedAtTypeChange` (or any migration that depends
  # on background migrations being run inline during test setup) can be broken by
  # altering Sidekiq behavior in an unrelated spec like so:
  #
  # around do |example|
  #   Sidekiq::Testing.fake! do
  #     example.run
  #   end
  # end
  config.before(:context, :migration) do
    @migration_out_of_test_window = false

    if migration_out_of_test_window?(described_class)
      @migration_out_of_test_window = true

      skip "Skipping because migration #{described_class} is outside the test window. " \
        "Run with `RUN_ALL_MIGRATION_TESTS=1 bundle exec rspec <spec> if you need to run this spec."
    end

    schema_migrate_down!
  end

  config.after(:context, :migration) do
    Gitlab::ApplicationSettingFetcher.clear_in_memory_application_settings!
  end

  config.append_after(:context, :migration) do
    recreate_databases_and_seed_if_needed || ensure_schema_and_empty_tables unless @migration_out_of_test_window
  end

  config.around(:each, :migration) do |example|
    migration_schema = example.metadata[:migration]
    migration_schema = :gitlab_main if migration_schema == true
    base_model = Gitlab::Database.schemas_to_base_models.fetch(migration_schema).first

    # Migration require an `ActiveRecord::Base` to point to desired database
    if base_model != ActiveRecord::Base
      with_reestablished_active_record_base do
        reconfigure_db_connection(
          model: ActiveRecord::Base,
          config_model: base_model
        )

        example.run
      end
    else
      example.run
    end
  end

  # Each example may call `migrate!`, so we must ensure we are migrated down every time
  config.before(:each, :migration) do
    use_fake_application_settings

    schema_migrate_down!
  end
end
