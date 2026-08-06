# frozen_string_literal: true

require 'rubocop_spec_helper'
require_relative '../../../../rubocop/cop/database/avoid_int_range_partitioning'

RSpec.describe RuboCop::Cop::Database::AvoidIntRangePartitioning, feature_category: :database do
  it 'flags the `:int_range` strategy in `partitioned_by`' do
    expect_offense(<<~RUBY)
      class MyModel < ApplicationRecord
        partitioned_by :project_id, strategy: :int_range, partition_size: 2_000_000
                                    ^^^^^^^^^^^^^^^^^^^^ Avoid the `:int_range` partitioning strategy.[...]
      end
    RUBY
  end

  it 'flags `partition_table_by_int_range`' do
    expect_offense(<<~RUBY)
      class MyMigration < Gitlab::Database::Migration[2.3]
        def up
          partition_table_by_int_range(
          ^^^^^^^^^^^^^^^^^^^^^^^^^^^^ Avoid the `:int_range` partitioning strategy.[...]
            'merge_request_diff_commits',
            'merge_request_diff_id',
            partition_size: 10_000_000,
            primary_key: %w[merge_request_diff_id relative_order]
          )
        end
      end
    RUBY
  end

  it 'flags `create_int_range_partitions`' do
    expect_offense(<<~RUBY)
      class MyMigration < Gitlab::Database::Migration[2.3]
        def up
          create_int_range_partitions(TABLE_NAME, PARTITION_SIZE, MIN_ID, max_id)
          ^^^^^^^^^^^^^^^^^^^^^^^^^^^ Avoid the `:int_range` partitioning strategy.[...]
        end
      end
    RUBY
  end

  it 'flags the strategy declared in a table registration hash' do
    expect_offense(<<~RUBY)
      Gitlab::Database::Partitioning.register_tables(
        [
          {
            table_name: 'merge_request_diff_files_99208b8fac',
            partitioned_column: :merge_request_diff_id, strategy: :int_range, partition_size: 200_000_000
                                                        ^^^^^^^^^^^^^^^^^^^^ Avoid the `:int_range` partitioning strategy.[...]
          }
        ]
      )
    RUBY
  end

  it 'does not flag other partitioning strategies' do
    expect_no_offenses(<<~RUBY)
      class MyModel < ApplicationRecord
        partitioned_by :created_at, strategy: :monthly, retain_for: 3.months
      end
    RUBY
  end

  it 'flags the helpers when called on an explicit receiver' do
    expect_offense(<<~RUBY)
      migration.create_int_range_partitions(TABLE_NAME, PARTITION_SIZE, MIN_ID, max_id)
                ^^^^^^^^^^^^^^^^^^^^^^^^^^^ Avoid the `:int_range` partitioning strategy.[...]
      migration&.partition_table_by_int_range(TABLE_NAME, COLUMN, partition_size: 1, primary_key: %w[id])
                 ^^^^^^^^^^^^^^^^^^^^^^^^^^^^ Avoid the `:int_range` partitioning strategy.[...]
    RUBY
  end
end
