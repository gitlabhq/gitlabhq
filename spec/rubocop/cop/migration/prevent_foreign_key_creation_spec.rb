# frozen_string_literal: true

require 'rubocop_spec_helper'
require_relative '../../../../rubocop/cop/migration/prevent_foreign_key_creation'

RSpec.describe RuboCop::Cop::Migration::PreventForeignKeyCreation, feature_category: :database do
  let(:forbidden_tables) { described_class::FORBIDDEN_TABLES }
  let(:offense) do
    "Adding new foreign key relationships to some CI tables is forbidden due to high cardinality concerns. [...]"
  end

  context 'when adding a foreign key to a forbidden table' do
    it 'does not register an offense when direction is down' do
      forbidden_tables.each do |table_name|
        expect_no_offenses(<<~RUBY)
          def down
            add_concurrent_partitioned_foreign_key :some_table, #{table_name}, column: :build_id
          end
        RUBY
      end
    end

    context 'when table_name is a symbol' do
      it 'registers an offense when add_concurrent_partitioned_foreign_key is used' do
        forbidden_tables.each do |table_name|
          expect_offense(<<~RUBY)
            def up
              add_concurrent_partitioned_foreign_key :some_table, :#{table_name}, column: :build_id
              ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^ #{offense}
            end
          RUBY
        end
      end

      it 'registers an offense in change method' do
        forbidden_tables.each do |table_name|
          expect_offense(<<~RUBY)
            def change
              add_concurrent_partitioned_foreign_key :some_table, :#{table_name}, column: :build_id
              ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^ #{offense}
            end
          RUBY
        end
      end
    end

    context 'when table_name is a string' do
      it 'registers an offense when add_concurrent_partitioned_foreign_key is used' do
        forbidden_tables.each do |table_name|
          expect_offense(<<~RUBY)
            def up
              add_concurrent_partitioned_foreign_key :some_table, "#{table_name}", column: :build_id
              ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^ #{offense}
            end
          RUBY
        end
      end
    end

    context 'when table_name is a constant' do
      it 'registers an offense when add_concurrent_partitioned_foreign_key is used' do
        forbidden_tables.each do |table_name|
          expect_offense(<<~RUBY)
            TARGET_TABLE = :#{table_name}
            SOURCE_TABLE = :some_table

            def up
              add_concurrent_partitioned_foreign_key(SOURCE_TABLE, TARGET_TABLE, column: [:partition_id, :build_id], target_column: [:partition_id, :id])
              ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^ #{offense}
            end
          RUBY
        end
      end

      it 'registers an offense with string constant' do
        forbidden_tables.each do |table_name|
          expect_offense(<<~RUBY)
            TARGET_TABLE = "#{table_name}"
            SOURCE_TABLE = "some_table"

            def up
              add_concurrent_partitioned_foreign_key(SOURCE_TABLE, TARGET_TABLE, column: [:partition_id, :build_id], target_column: [:partition_id, :id])
              ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^ #{offense}
            end
          RUBY
        end
      end
    end
  end

  context 'when adding a foreign key to a regular table' do
    it 'does not register an offense' do
      expect_no_offenses(<<~RUBY)
        def up
          add_concurrent_partitioned_foreign_key :some_table, :projects, column: :project_id
        end
      RUBY
    end

    it 'does not register an offense in change method' do
      expect_no_offenses(<<~RUBY)
        def change
          add_concurrent_partitioned_foreign_key :some_table, :users, column: :user_id
        end
      RUBY
    end

    context 'when using a constant' do
      it 'does not register an offense' do
        expect_no_offenses(<<~RUBY)
          TARGET_TABLE = :projects

          def up
            add_concurrent_partitioned_foreign_key :some_table, TARGET_TABLE, column: :project_id
          end
        RUBY
      end
    end
  end

  context 'when method is not up, down, or change' do
    it 'does not register an offense' do
      expect_no_offenses(<<~RUBY)
        def some_helper_method
          add_concurrent_partitioned_foreign_key :some_table, :p_ci_builds, column: :build_id
        end
      RUBY
    end
  end
end
