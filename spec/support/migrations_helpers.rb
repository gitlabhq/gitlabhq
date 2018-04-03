module MigrationsHelpers
  prepend EE::MigrationsHelpers

  def active_record_base
    ActiveRecord::Base
  end

  def table(name)
    Class.new(active_record_base) do
      self.table_name = name
      self.inheritance_column = :_type_disabled
    end
  end

  def migrations_paths
    ActiveRecord::Migrator.migrations_paths
  end

  def table_exists?(name)
    active_record_base.connection.table_exists?(name)
  end

  def migrations
    ActiveRecord::Migrator.migrations(migrations_paths)
  end

  def clear_schema_cache!
    active_record_base.connection_pool.connections.each do |conn|
      conn.schema_cache.clear!
    end
  end

  def reset_column_in_all_models
    clear_schema_cache!

    # Reset column information for the most offending classes **after** we
    # migrated the schema up, otherwise, column information could be
    # outdated. We have a separate method for this so we can override it in EE.
    active_record_base.descendants.each(&method(:reset_column_information))

    # Without that, we get errors because of missing attributes, e.g.
    # super: no superclass method `elasticsearch_indexing' for #<ApplicationSetting:0x00007f85628508d8>
    ApplicationSetting.define_attribute_methods
  end

  def reset_column_information(klass)
    klass.reset_column_information
  end

  def previous_migration
    migrations.each_cons(2) do |previous, migration|
      break previous if migration.name == described_class.name
    end
  end

  def migration_schema_version
    metadata_schema = self.class.metadata[:schema]

    if metadata_schema == :latest
      migrations.last.version
    else
      metadata_schema || previous_migration.version
    end
  end

  def schema_migrate_down!
    disable_migrations_output do
      ActiveRecord::Migrator.migrate(migrations_paths,
                                     migration_schema_version)
    end

    reset_column_in_all_models
  end

  def schema_migrate_up!
    reset_column_in_all_models

    disable_migrations_output do
      ActiveRecord::Migrator.migrate(migrations_paths)
    end

    reset_column_in_all_models
  end

  def disable_migrations_output
    ActiveRecord::Migration.verbose = false

    yield
  ensure
    ActiveRecord::Migration.verbose = true
  end

  def migrate!
    ActiveRecord::Migrator.up(migrations_paths) do |migration|
      migration.name == described_class.name
    end
  end
end
