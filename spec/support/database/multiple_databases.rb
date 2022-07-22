# frozen_string_literal: true

module Database
  module MultipleDatabases
    def skip_if_multiple_databases_not_setup
      skip 'Skipping because multiple databases not set up' unless Gitlab::Database.has_config?(:ci)
    end

    def skip_if_multiple_databases_are_setup
      skip 'Skipping because multiple databases are set up' if Gitlab::Database.has_config?(:ci)
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

    # The usage of this method switches temporarily used `connection_handler`
    # allowing full manipulation of ActiveRecord::Base connections without
    # having side effects like:
    # - misaligned transactions since this is managed by `BeforeAllAdapter`
    # - removal of primary connections
    #
    # The execution within a block ensures safe cleanup of all allocated resources.
    #
    # rubocop:disable Database/MultipleDatabases
    def with_reestablished_active_record_base(reconnect: true)
      connection_classes = ActiveRecord::Base.connection_handler.connection_pool_names.map(&:constantize).to_h do |klass|
        [klass, klass.connection_db_config]
      end

      original_handler = ActiveRecord::Base.connection_handler
      new_handler = ActiveRecord::ConnectionAdapters::ConnectionHandler.new
      ActiveRecord::Base.connection_handler = new_handler

      if reconnect
        connection_classes.each { |klass, db_config| klass.establish_connection(db_config) }
      end

      yield
    ensure
      ActiveRecord::Base.connection_handler = original_handler
      new_handler&.clear_all_connections!
    end
    # rubocop:enable Database/MultipleDatabases

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
      if connected? && connection&.transaction_open? && ActiveRecord::Base.connection_handler == ActiveRecord::Base.default_connection_handler
        raise "Cannot re-establish '#{self}.establish_connection' within an open transaction (#{connection&.open_transactions.to_i}). " \
          "Use `with_reestablished_active_record_base` instead or add `:reestablished_active_record_base` to rspec context."
      end
      # rubocop:enable Database/MultipleDatabases

      super
    end
  end
end

RSpec.configure do |config|
  config.around(:each, :reestablished_active_record_base) do |example|
    with_reestablished_active_record_base(reconnect: example.metadata.fetch(:reconnect, true)) do
      example.run
    end
  end

  config.around(:each, :add_ci_connection) do |example|
    with_added_ci_connection do
      example.run
    end
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
end

ActiveRecord::Base.singleton_class.prepend(::Database::ActiveRecordBaseEstablishConnection) # rubocop:disable Database/MultipleDatabases
