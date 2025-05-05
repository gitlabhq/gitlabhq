# frozen_string_literal: true

require 'rubocop_spec_helper'
require_relative '../../../../rubocop/cop/migration/prevent_enabling_lock_retries_for_transactional_migrations'

RSpec.describe RuboCop::Cop::Migration::PreventEnablingLockRetriesForTransactionalMigrations, feature_category: :database do
  it 'adds an offense when the migration explicit calls for enable_lock_retries!' do
    expect_offense(<<~RUBY)
        class MyMigration < Gitlab::Database::Migration[2.2]
          milestone '18.0'

          enable_lock_retries!
          ^^^^^^^^^^^^^^^^^^^^ Avoid using `enable_lock_retries! for transactional migrations`. The lock-retry [...]

          def change
            add_column :users, :column_id, :smallint
          end
        end
    RUBY
  end

  it "adds no offense if the migration doesn't calls enable_lock_retries!" do
    expect_no_offenses(<<~RUBY)
        class MyMigration < Gitlab::Database::Migration[2.2]
          milestone '18.0'

          def change
            add_column :users, :column_id, :smallint
          end
        end
    RUBY
  end
end
