# frozen_string_literal: true

require 'rubocop_spec_helper'
require_relative '../../../../rubocop/cop/migration/migration_with_milestone'

RSpec.describe RuboCop::Cop::Migration::MigrationWithMilestone, feature_category: :database do
  context 'when we\'re not a Gitlab migration' do
    it 'does not register an offense at all' do
      expect_no_offenses <<~CODE
        class CreateProducts < ActiveRecord::Migration[7.0]
          def change
            add_column :users, :foo, :integer
          end
        end
      CODE
    end
  end

  context 'when we\'re a Gitlab migration' do
    it 'does not register an offense if we\'re a version before 2.2' do
      expect_no_offenses <<~CODE
        class TestFoo < Gitlab::Database::Migration[2.1]
          def change
            add_column :users, :foo, :integer
          end
        end
      CODE
    end

    context 'when we\'re version 2.2' do
      it 'expects no offense if we call `milestone` with a string' do
        expect_no_offenses <<~CODE
          class TestFoo < Gitlab::Database::Migration[2.2]
            milestone '16.7'

            def change
              add_column :users, :foo, :integer
            end
          end
        CODE
      end

      it 'expects an offense if we don\'t call `milestone`' do
        expect_offense <<~CODE
          class TestFoo < Gitlab::Database::Migration[2.2]
          ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^ #{described_class::MSG}
            def change
              add_column :users, :foo, :integer
            end
          end
        CODE
      end

      it 'does not matter if include a mixin' do
        expect_no_offenses <<~CODE
          class TestFoo < Gitlab::Database::Migration[2.2]
            include Gitlab::Test::Mixin

            milestone '16.7'

            def change
              add_column :users, :foo, :integer
            end
          end
        CODE
      end

      it 'does not matter if we call a helper method' do
        expect_no_offenses <<~CODE
          class TestFoo < Gitlab::Database::Migration[2.2]
            disable_ddl_transaction!

            milestone '16.7'

            def change
              add_column :users, :foo, :integer
            end
          end
        CODE
      end

      it 'does not matter if we include a mixin and call a helper method' do
        expect_no_offenses <<~CODE
          class TestFoo < Gitlab::Database::Migration[2.2]
            include Gitlab::Test::Mixin

            disable_ddl_transaction!

            milestone '16.7'

            def change
              add_column :users, :foo, :integer
            end
          end
        CODE
      end
    end
  end
end
