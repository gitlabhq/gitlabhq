# frozen_string_literal: true

require 'rubocop_spec_helper'
require_relative '../../../../rubocop/cop/search/avoid_checking_finished_on_deprecated_migrations'

RSpec.describe RuboCop::Cop::Search::AvoidCheckingFinishedOnDeprecatedMigrations, feature_category: :global_search do
  context 'when a deprecated class is used with migration_has_finished?' do
    it 'flags it as an offense' do
      expect_offense <<~SOURCE
        return if Elastic::DataMigrationService.migration_has_finished?(:backfill_archived_on_issues)
                  ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^ Migration is deprecated and can not be used with `migration_has_finished?`.
      SOURCE
    end
  end

  context 'when a non deprecated class is used with migration_has_finished?' do
    it 'does not flag it as an offense' do
      expect_no_offenses <<~SOURCE
        return if Elastic::DataMigrationService.migration_has_finished?(:backfill_project_permissions_in_blobs)
      SOURCE
    end
  end

  context 'when migration_has_finished? method is called on another class' do
    it 'does not flag it as an offense' do
      expect_no_offenses <<~SOURCE
        return if Klass.migration_has_finished?(:backfill_archived_on_issues)
      SOURCE
    end
  end
end
