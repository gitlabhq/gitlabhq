# frozen_string_literal: true
#
require 'fast_spec_helper'
require_relative '../../../../rubocop/cop/migration/refer_to_index_by_name'

RSpec.describe RuboCop::Cop::Migration::ReferToIndexByName do
  subject(:cop) { described_class.new }

  context 'when in migration' do
    before do
      allow(cop).to receive(:in_migration?).and_return(true)
    end

    context 'when existing indexes are referred to without an explicit name' do
      it 'registers an offense' do
        expect_offense(<<~RUBY, msg: 'migration methods that refer to existing indexes must do so by name')
          class TestReferToIndexByName < ActiveRecord::Migration[6.0]
            INDEX_NAME = 'my_test_name'

            disable_ddl_transaction!

            def up
              if index_exists? :test_indexes, :column1, name: 'index_name_1'
                remove_index :test_indexes, column: :column1, name: 'index_name_1'
              end

              if index_exists? :test_indexes, :column2
                 ^^^^^^^^^^^^^ %{msg}
                remove_index :test_indexes, :column2
                ^^^^^^^^^^^^ %{msg}
              end

              remove_index :test_indexes, column: column3
              ^^^^^^^^^^^^ %{msg}

              remove_index :test_indexes, name: 'index_name_4'
            end

            def down
              if index_exists? :test_indexes, :column4, using: :gin, opclass: :gin_trgm_ops
                 ^^^^^^^^^^^^^ %{msg}
                remove_concurrent_index :test_indexes, :column4, using: :gin, opclass: :gin_trgm_ops
                ^^^^^^^^^^^^^^^^^^^^^^^ %{msg}
              end

              if index_exists? :test_indexes, :column3, unique: true, name: 'index_name_3', where: 'column3 = 10'
                remove_concurrent_index :test_indexes, :column3, unique: true, name: 'index_name_3', where: 'column3 = 10'
              end
            end
          end
        RUBY
      end
    end
  end

  context 'when outside migration' do
    before do
      allow(cop).to receive(:in_migration?).and_return(false)
    end

    it 'registers no offenses' do
      expect_no_offenses(<<~RUBY)
        class TestReferToIndexByName < ActiveRecord::Migration[6.0]
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
