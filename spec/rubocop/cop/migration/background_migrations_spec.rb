# frozen_string_literal: true

require 'rubocop_spec_helper'
require_relative '../../../../rubocop/cop/migration/background_migrations'

RSpec.describe RuboCop::Cop::Migration::BackgroundMigrations do
  context 'when queue_background_migration_jobs_by_range_at_intervals is used' do
    it 'registers an offense' do
      expect_offense(<<~RUBY)
        def up
          queue_background_migration_jobs_by_range_at_intervals('example', 'example', 1, batch_size: 1, track_jobs: true)
          ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^ Background migrations are deprecated. Please use a batched background migration instead[...]
        end
      RUBY
    end
  end

  context 'when requeue_background_migration_jobs_by_range_at_intervals is used' do
    it 'registers an offense' do
      expect_offense(<<~RUBY)
        def up
          requeue_background_migration_jobs_by_range_at_intervals('example', 1)
          ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^ Background migrations are deprecated. Please use a batched background migration instead[...]
        end
      RUBY
    end
  end

  context 'when migrate_in is used' do
    it 'registers an offense' do
      expect_offense(<<~RUBY)
        def up
          migrate_in(1, 'example', 1, ['example'])
          ^^^^^^^^^^ Background migrations are deprecated. Please use a batched background migration instead[...]
        end
      RUBY
    end
  end
end
