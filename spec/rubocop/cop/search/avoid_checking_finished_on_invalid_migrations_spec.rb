# frozen_string_literal: true

require 'rubocop_spec_helper'
require_relative '../../../../rubocop/cop/search/avoid_checking_finished_on_invalid_migrations'

RSpec.describe RuboCop::Cop::Search::AvoidCheckingFinishedOnInvalidMigrations, feature_category: :global_search do
  # Only run these tests if the migration directories are present
  if Dir.exist?('ee/elastic/docs') && Dir.exist?('ee/elastic/migrate')
    context 'when an obsolete migration is used with migration_has_finished?' do
      it 'flags it as an offense' do
        expect_offense <<~RUBY
          return if Elastic::DataMigrationService.migration_has_finished?(:backfill_archived_on_issues)
                    ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^ Migration is obsolete and can not be used with `migration_has_finished?`.
        RUBY
      end
    end

    context 'when a non-existing migration is used with migration_has_finished?' do
      it 'flags it as an offense' do
        expect_offense <<~RUBY
          return if Elastic::DataMigrationService.migration_has_finished?(:non_existing_migration)
                    ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^ Migration does not exist and can not be used with `migration_has_finished?`.
        RUBY
      end
    end

    context 'when a valid migration is used with migration_has_finished?' do
      it 'does not flag it as an offense' do
        expect_no_offenses <<~RUBY
          return if Elastic::DataMigrationService.migration_has_finished?(:backfill_work_items_incorrect_data)
        RUBY
      end
    end

    context 'when an obsolete migration (that was documented) is used' do
      it 'flags it as an offense' do
        expect_offense <<~RUBY
          return if Elastic::DataMigrationService.migration_has_finished?(:apply_max_analyzed_offset)
                    ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^ Migration is obsolete and can not be used with `migration_has_finished?`.
        RUBY
      end
    end

    context 'when migration_has_finished? method is called on another class' do
      it 'does not flag it as an offense' do
        expect_no_offenses <<~RUBY
          return if Klass.migration_has_finished?(:backfill_archived_on_issues)
        RUBY
      end
    end

    context 'when migration exists in docs but missing implementation file' do
      it 'flags it as an offense' do
        # Mock the migration info to exist but file to be missing
        allow(cop).to receive_messages(
          find_migration_info: { obsolete: false, version: '1.0', milestone: '14.0' },
          migration_file_exists?: false
        )

        expect_offense <<~RUBY
          return if Elastic::DataMigrationService.migration_has_finished?(:missing_implementation)
                    ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^ Migration implementation file is missing.
        RUBY
      end
    end

    context 'when YAML parsing fails' do
      it 'handles errors gracefully' do
        # Mock Dir.glob to return a file that will cause YAML parsing to fail
        allow(Dir).to receive(:glob).with('ee/elastic/docs/*.yml').and_return(['invalid_file.yml'])
        allow(YAML).to receive(:safe_load_file).and_raise(StandardError.new('Invalid YAML'))

        # Capture the warning message
        expect { cop.send(:load_migrations) }.to output(
          /Warning: Could not parse migration documentation file/
        ).to_stderr
      end
    end
  end
end
