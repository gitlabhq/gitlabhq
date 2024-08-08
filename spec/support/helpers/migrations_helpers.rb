# frozen_string_literal: true

module MigrationsHelpers
  def active_record_base(database: nil)
    database_name = database || self.class.metadata[:database] || :main

    unless ::Gitlab::Database.all_database_connections.include?(database_name)
      raise ArgumentError, "#{database_name} is not a valid argument"
    end

    Gitlab::Database.database_base_models[database_name] || Gitlab::Database.database_base_models[:main]
  end

  def table(name, database: nil)
    Class.new(active_record_base(database: database)) do
      self.table_name = name
      self.inheritance_column = :_type_disabled

      def self.name
        table_name.singularize.camelcase
      end

      yield self if block_given?
    end
  end

  def partitioned_table(name, by: :created_at, strategy: :monthly)
    klass = Class.new(active_record_base) do
      include PartitionedTable

      self.table_name = name
      self.primary_key = :id

      partitioned_by by, strategy: strategy

      def self.name
        table_name.singularize.camelcase
      end
    end

    klass.tap { Gitlab::Database::Partitioning.sync_partitions([klass]) }
  end

  def migrations_paths
    active_record_base.connection.migrations_paths
  end

  def migration_context
    ActiveRecord::MigrationContext.new(migrations_paths, ActiveRecord::SchemaMigration)
  end

  def migrations
    migration_context.migrations
  end

  def clear_schema_cache!
    active_record_base.connection_pool.connections.each do |conn|
      conn.schema_cache.clear!
    end
  end

  def foreign_key_exists?(source, target = nil, column: nil)
    active_record_base.connection.foreign_keys(source).any? do |key|
      if column
        key.options[:column].to_s == column.to_s
      else
        key.to_table.to_s == target.to_s
      end
    end
  end

  def reset_column_in_all_models
    clear_schema_cache!

    # Reset column information for the most offending classes **after** we
    # migrated the schema up, otherwise, column information could be
    # outdated. We have a separate method for this so we can override it in EE.
    active_record_base.descendants.each(&method(:reset_column_information))
  end

  def refresh_attribute_methods
    # Without this, we get errors because of missing attributes, e.g.
    # super: no superclass method `elasticsearch_indexing' for #<ApplicationSetting:0x00007f85628508d8>
    # attr_encrypted also expects ActiveRecord attribute methods to be
    # defined, or it will override the accessors:
    # https://gitlab.com/gitlab-org/gitlab/issues/8234#note_113976421
    [ApplicationSetting, SystemHook].each do |model|
      model.define_attribute_methods
    end

    Gitlab.ee { License.define_attribute_methods }
  end

  def reset_column_information(klass)
    klass.reset_column_information if klass.instance_variable_get(:@table_name)
  end

  # In some migration tests, we're using factories to create records,
  # however those models might be depending on a schema version which
  # doesn't have the columns we want in application_settings.
  # In these cases, we'll need to use the fake application settings
  # as if we have migrations pending
  def use_fake_application_settings
    # We stub this way because we can't stub on
    # `current_application_settings` due to `method_missing` is
    # depending on current_application_settings...
    allow(Gitlab::Database::Migration::V1_0::MigrationRecord.connection)
      .to receive(:active?)
      .and_return(false)
    allow(Gitlab::Runtime)
      .to receive(:rake?)
      .and_return(true)

    stub_env('IN_MEMORY_APPLICATION_SETTINGS', 'false')
  end

  def previous_migration(steps_back = 2)
    migrations.each_cons(steps_back) do |cons|
      break cons.first if cons.last.name == described_class.name
    end
  end

  def finalized_by_version
    finalized_by = ::Gitlab::Database::BackgroundMigration::BatchedBackgroundMigrationDictionary
      .entry(described_class.to_s.demodulize)&.finalized_by

    finalized_by.to_i if finalized_by
  end

  def migration_schema_version
    metadata_schema = self.class.metadata[:schema]

    if metadata_schema == :latest
      migrations.last.version
    elsif self.class.metadata[:level] == :background_migration
      metadata_schema || finalized_by_version || migrations.last.version
    else
      metadata_schema || previous_migration.version
    end
  end

  def schema_migrate_down!
    disable_migrations_output do
      migration_context.down(migration_schema_version)
    end

    reset_column_in_all_models
  end

  def schema_migrate_up!
    reset_column_in_all_models

    disable_migrations_output do
      migration_context.up
    end

    reset_column_in_all_models
    refresh_attribute_methods
  end

  def disable_migrations_output
    ActiveRecord::Migration.verbose = false

    yield
  ensure
    ActiveRecord::Migration.verbose = true
  end

  def migrate!
    open_transactions = Gitlab::Database::Migration::V1_0::MigrationRecord.connection.open_transactions
    allow_next_instance_of(described_class) do |migration|
      allow(migration).to receive(:transaction_open?) do
        Gitlab::Database::Migration::V1_0::MigrationRecord.connection.open_transactions > open_transactions
      end
    end

    migration_context.up do |migration|
      migration.name == described_class.name
    end
  end

  class ReversibleMigrationTest
    attr_reader :before_up, :after_up

    def initialize
      @before_up = -> {}
      @after_up = -> {}
    end

    def before(expectations)
      @before_up = expectations

      self
    end

    def after(expectations)
      @after_up = expectations

      self
    end
  end

  def reversible_migration(&block)
    tests = yield(ReversibleMigrationTest.new)

    tests.before_up.call

    migrate!

    tests.after_up.call

    schema_migrate_down!

    tests.before_up.call
  end
end

MigrationsHelpers.prepend_mod_with('MigrationsHelpers')
