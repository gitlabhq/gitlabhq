# frozen_string_literal: true
#
require 'fast_spec_helper'
require 'rubocop'
require_relative '../../../../rubocop/cop/migration/complex_indexes_require_name'

RSpec.describe RuboCop::Cop::Migration::ComplexIndexesRequireName, type: :rubocop do
  include CopHelper

  subject(:cop) { described_class.new }

  context 'in migration' do
    before do
      allow(cop).to receive(:in_migration?).and_return(true)
    end

    context 'when creating complex indexes as part of create_table' do
      context 'when indexes are configured with an options hash, but no name' do
        it 'registers an offense' do
          expect_offense(<<~RUBY)
            class TestComplexIndexes < ActiveRecord::Migration[6.0]
              DOWNTIME = false

              def up
                create_table :test_table do |t|
                  t.integer :column1, null: false
                  t.integer :column2, null: false
                  t.jsonb :column3

                  t.index :column1, unique: true
                  t.index :column2, where: 'column1 = 0'
                    ^^^^^ #{described_class::MSG}
                  t.index :column3, using: :gin
                    ^^^^^ #{described_class::MSG}
                end
              end

              def down
                drop_table :test_table
              end
            end
          RUBY

          expect(cop.offenses.map(&:cop_name)).to all(eq("Migration/#{described_class.name.demodulize}"))
        end
      end

      context 'when indexes are configured with an options hash and name' do
        it 'registers no offense' do
          expect_no_offenses(<<~RUBY)
            class TestComplexIndexes < ActiveRecord::Migration[6.0]
              DOWNTIME = false

              def up
                create_table :test_table do |t|
                  t.integer :column1, null: false
                  t.integer :column2, null: false
                  t.jsonb :column3

                  t.index :column1, unique: true
                  t.index :column2, where: 'column1 = 0', name: 'my_index_1'
                  t.index :column3, using: :gin, name: 'my_gin_index'
                end
              end

              def down
                drop_table :test_table
              end
            end
          RUBY
        end
      end
    end

    context 'when indexes are added to an existing table' do
      context 'when indexes are configured with an options hash, but no name' do
        it 'registers an offense' do
          expect_offense(<<~RUBY)
            class TestComplexIndexes < ActiveRecord::Migration[6.0]
              DOWNTIME = false

              disable_ddl_transaction!

              def up
                add_index :test_indexes, :column1

                add_index :test_indexes, :column2, where: "column2 = 'value'", order: { column4: :desc }
                ^^^^^^^^^ #{described_class::MSG}
              end

              def down
                add_index :test_indexes, :column4, 'unique' => true, where: 'column4 IS NOT NULL'
                ^^^^^^^^^ #{described_class::MSG}

                add_concurrent_index :test_indexes, :column6, using: :gin, opclass: :gin_trgm_ops
                ^^^^^^^^^^^^^^^^^^^^ #{described_class::MSG}
              end
            end
          RUBY

          expect(cop.offenses.map(&:cop_name)).to all(eq("Migration/#{described_class.name.demodulize}"))
        end
      end

      context 'when indexes are configured with an options hash and a name' do
        it 'registers no offenses' do
          expect_no_offenses(<<~RUBY)
            class TestComplexIndexes < ActiveRecord::Migration[6.0]
              DOWNTIME = false

              INDEX_NAME = 'my_test_name'

              disable_ddl_transaction!

              def up
                add_index :test_indexes, :column1

                add_index :test_indexes, :column2, where: "column2 = 'value'", order: { column4: :desc }, name: 'my_index_1'

                add_concurrent_index :test_indexes, :column3, where: 'column3 = 10', name: 'idx_equal_to_10'
              end

              def down
                add_index :test_indexes, :column4, 'unique' => true, where: 'column4 IS NOT NULL', name: 'my_index_2'

                add_concurrent_index :test_indexes, :column6, using: :gin, opclass: :gin_trgm_ops, name: INDEX_NAME
              end
            end
          RUBY
        end
      end
    end
  end

  context 'outside migration' do
    before do
      allow(cop).to receive(:in_migration?).and_return(false)
    end

    it 'registers no offenses' do
      expect_no_offenses(<<~RUBY)
        class TestComplexIndexes < ActiveRecord::Migration[6.0]
          DOWNTIME = false

          disable_ddl_transaction!

          def up
            create_table :test_table do |t|
              t.integer :column1

              t.index :column1, where: 'column2 IS NOT NULL'
            end

            add_index :test_indexes, :column1, where: "some_column = 'value'"
          end

          def down
            add_concurrent_index :test_indexes, :column2, unique: true
          end
        end
      RUBY
    end
  end
end
