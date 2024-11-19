# frozen_string_literal: true

module Database
  module MultipleDatabasesHelpers
    EXTRA_DBS = ::Gitlab::Database.all_database_names.map(&:to_sym) - [:main]

    def database_exists?(database_name)
      ::Gitlab::Database.has_database?(database_name)
    end

    def skip_if_shared_database(database_name)
      skip "Skipping because #{database_name} is shared or doesn't not exist" unless database_exists?(database_name)
    end

    def skip_if_database_exists(database_name)
      skip "Skipping because database #{database_name} exists" if database_exists?(database_name)
    end

    def execute_on_each_database(query, databases: %I[main ci])
      databases = databases.select { |database_name| database_exists?(database_name) }

      Gitlab::Database::EachDatabase.each_connection(only: databases, include_shared: false) do |connection, _|
        next unless Gitlab::Database.gitlab_schemas_for_connection(connection).include?(:gitlab_shared)

        connection.execute(query)
      end
    end

    def skip_if_multiple_databases_not_setup(*databases)
      unless (databases - EXTRA_DBS).empty?
        raise "Unsupported database in #{databases}. It must be one of #{EXTRA_DBS}."
      end

      databases = EXTRA_DBS if databases.empty?
      return if databases.any? { |db| Gitlab::Database.has_config?(db) }

      skip "Skipping because none of the extra databases #{databases} are setup"
    end

    def skip_if_multiple_databases_are_setup(*databases)
      unless (databases - EXTRA_DBS).empty?
        raise "Unsupported database in #{databases}. It must be one of #{EXTRA_DBS}."
      end

      databases = EXTRA_DBS if databases.empty?
      return if databases.none? { |db| Gitlab::Database.has_config?(db) }

      skip "Skipping because some of the extra databases #{databases} are setup"
    end

    def reconfigure_db_connection(name: nil, config_hash: {}, model: ActiveRecord::Base, config_model: nil)
      db_config = (config_model || model).connection_db_config

      new_db_config = ActiveRecord::DatabaseConfigurations::HashConfig.new(
        db_config.env_name,
        name ? name.to_s : db_config.name,
        db_config.configuration_hash.merge(config_hash)
      )

      model.establish_connection(new_db_config)
    end

    def ensure_schema_and_empty_tables
      # Ensure all schemas for both databases are migrated back
      Gitlab::Database.database_base_models.each do |_, base_model|
        with_reestablished_active_record_base do
          reconfigure_db_connection(
            model: ActiveRecord::Base,
            config_model: base_model
          )

          # Delete after migrating so that rows created during migration don't impact other
          # specs (for example, async foreign key creation rows)
          schema_migrate_up!
          delete_from_all_tables!(except: deletion_except_tables)
        end
      end

      # ActiveRecord::Base.clear_all_connections! disconnects and clears attribute methods
      # Force a refresh to avoid schema failures.
      reset_column_in_all_models
      refresh_attribute_methods
    end

    # The usage of this method switches temporarily used `connection_handler`
    # allowing full manipulation of ActiveRecord::Base connections without
    # having side effects like:
    # - misaligned transactions since this is managed by `TestProf::BeforeAll::Adapters::ActiveRecord`
    # - removal of primary connections
    #
    # The execution within a block ensures safe cleanup of all allocated resources.
    #
    def with_reestablished_active_record_base(reconnect: true)
      connection_classes = ActiveRecord::Base
        .connection_handler
        .connection_pool_names
        .map(&:constantize)

      connection_classes.delete(ActiveRecord::PendingMigrationConnection) if ::Gitlab.next_rails?

      connection_class_to_config = connection_classes.index_with(&:connection_db_config)

      original_handler = ActiveRecord::Base.connection_handler
      new_handler = ActiveRecord::ConnectionAdapters::ConnectionHandler.new
      ActiveRecord::Base.connection_handler = new_handler

      connection_class_to_config.each { |klass, db_config| klass.establish_connection(db_config) } if reconnect

      yield
    ensure
      ActiveRecord::Base.connection_handler = original_handler
      new_handler&.clear_all_connections!
    end

    def with_db_configs(test: test_config)
      current_configurations = ActiveRecord::Base.configurations
      ActiveRecord::Base.configurations = { test: test_config }
      yield
    ensure
      ActiveRecord::Base.configurations = current_configurations
    end

    def with_added_ci_connection
      if Gitlab::Database.has_config?(:ci)
        # No need to add a ci: connection if we already have one
        yield
      else
        with_reestablished_active_record_base(reconnect: true) do
          reconfigure_db_connection(
            name: :ci,
            model: Ci::ApplicationRecord,
            config_model: ActiveRecord::Base
          )

          yield

          # Cleanup connection_specification_name for Ci::ApplicationRecord
          Ci::ApplicationRecord.remove_connection
        end
      end
    end
  end

  module ActiveRecordBaseEstablishConnection
    def establish_connection(*args)
      # rubocop:disable Database/MultipleDatabases
      if connected? &&
          connection&.transaction_open? &&
          ActiveRecord::Base.connection_handler == ActiveRecord::Base.default_connection_handler
        raise "Cannot re-establish '#{self}.establish_connection' within an open transaction " \
          "(#{connection&.open_transactions.to_i}). Use `with_reestablished_active_record_base` " \
          "instead or add `:reestablished_active_record_base` to rspec context."
      end
      # rubocop:enable Database/MultipleDatabases

      super
    end
  end
end

ActiveRecord::Base.singleton_class.prepend(::Database::ActiveRecordBaseEstablishConnection) # rubocop:disable Database/MultipleDatabases
