# frozen_string_literal: true

module Database
  module MultipleDatabases
    def skip_if_multiple_databases_not_setup
      skip 'Skipping because multiple databases not set up' unless Gitlab::Database.has_config?(:ci)
    end
  end
end
