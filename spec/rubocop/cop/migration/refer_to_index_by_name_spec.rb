# frozen_string_literal: true
#
require 'fast_spec_helper'
require 'rubocop'
require_relative '../../../../rubocop/cop/migration/refer_to_index_by_name'

RSpec.describe RuboCop::Cop::Migration::ReferToIndexByName, type: :rubocop do
  include CopHelper

  subject(:cop) { described_class.new }

  context 'in migration' do
    before do
      allow(cop).to receive(:in_migration?).and_return(true)
    end

    context 'when existing indexes are referred to without an explicit name' do
      it 'registers an offense' do
        expect_offense(<<~RUBY)
          class TestReferToIndexByName < ActiveRecord::Migration[6.0]
            DOWNTIME = false

            INDEX_NAME = 'my_test_name'

            disable_ddl_transaction!

            def up
              if index_exists? :test_indexes, :column1, name: 'index_name_1'
                remove_index :test_indexes, column: :column1, name: 'index_name_1'
              end

              if index_exists? :test_indexes, :column2
                 ^^^^^^^^^^^^^ #{described_class::MSG}
                remove_index :test_indexes, :column2
                ^^^^^^^^^^^^ #{described_class::MSG}
              end

              remove_index :test_indexes, column: column3
              ^^^^^^^^^^^^ #{described_class::MSG}

              remove_index :test_indexes, name: 'index_name_4'
            end

            def down
              if index_exists? :test_indexes, :column4, using: :gin, opclass: :gin_trgm_ops
                 ^^^^^^^^^^^^^ #{described_class::MSG}
                remove_concurrent_index :test_indexes, :column4, using: :gin, opclass: :gin_trgm_ops
                ^^^^^^^^^^^^^^^^^^^^^^^ #{described_class::MSG}
              end

              if index_exists? :test_indexes, :column3, unique: true, name: 'index_name_3', where: 'column3 = 10'
                remove_concurrent_index :test_indexes, :column3, unique: true, name: 'index_name_3', where: 'column3 = 10'
              end
            end
          end
        RUBY

        expect(cop.offenses.map(&:cop_name)).to all(eq("Migration/#{described_class.name.demodulize}"))
      end
    end
  end

  context 'outside migration' do
    before do
      allow(cop).to receive(:in_migration?).and_return(false)
    end

    it 'registers no offenses' do
      expect_no_offenses(<<~RUBY)
        class TestReferToIndexByName < ActiveRecord::Migration[6.0]
          DOWNTIME = false

          disable_ddl_transaction!

          def up
            if index_exists? :test_indexes, :column1
              remove_index :test_indexes, :column1
            end
          end

          def down
            if index_exists? :test_indexes, :column1
              remove_concurrent_index :test_indexes, :column1
            end
          end
        end
      RUBY
    end
  end
end
