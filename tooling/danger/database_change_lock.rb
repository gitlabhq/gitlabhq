# frozen_string_literal: true

require_relative 'database_change_lock_window'
require_relative 'database_upgrade_ddl_lock'
require_relative 'post_deployment_migration_lock'

module Tooling
  module Danger
    module DatabaseChangeLock
      # DatabaseChangeLockWindow provides the same "find the active or upcoming lock entry"
      # logic used by the lock rules. The dispatcher needs the same view of which lock entry
      # is relevant so that dispatch matches the rules' own behavior.
      include DatabaseChangeLockWindow

      DEFAULT_BLOCK_LEVEL = 'only_ddl'

      LOCK_TYPE = {
        'only_ddl' => DatabaseUpgradeDdlLock,
        'only_pdm' => PostDeploymentMigrationLock
      }.freeze

      def check_database_lock_contention
        return unless config_file_exists? && config_valid?

        lock_rule_for(config['block_level'].to_s).check_lock
      end

      private

      def lock_rule_for(block_level)
        rule_class = LOCK_TYPE.fetch(block_level, LOCK_TYPE.fetch(DEFAULT_BLOCK_LEVEL))
        rule_class.new(self)
      end
    end
  end
end
