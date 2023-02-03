# frozen_string_literal: true

require 'rubocop_spec_helper'
require_relative '../../../../rubocop/cop/migration/prevent_single_statement_with_disable_ddl_transaction'

RSpec.describe RuboCop::Cop::Migration::PreventSingleStatementWithDisableDdlTransaction, feature_category: :database do
  context 'when in migration' do
    before do
      allow(cop).to receive(:in_migration?).and_return(true)
    end

    it 'registers an offense when `disable_ddl_transaction!` is only for the :validate_foreign_key statement' do
      code = <<~RUBY
      class SomeMigration < Gitlab::Database::Migration[2.1]
        disable_ddl_transaction!
        def up
          validate_foreign_key :emails, :user_id
        end
        def down
          # no-op
        end
      end
      RUBY

      expect_offense(<<~RUBY, node: code, msg: described_class::MSG)
        class SomeMigration < Gitlab::Database::Migration[2.1]
          disable_ddl_transaction!
          ^^^^^^^^^^^^^^^^^^^^^^^^ %{msg}
          def up
            validate_foreign_key :emails, :user_id
          end
          def down
            # no-op
          end
        end
      RUBY
    end

    it 'registers no offense when `disable_ddl_transaction!` is used with more than one statement' do
      expect_no_offenses(<<~RUBY)
        class SomeMigration < Gitlab::Database::Migration[2.1]
          disable_ddl_transaction!
          def up
            add_concurrent_foreign_key :emails, :users, column: :user_id, on_delete: :cascade, validate: false
            validate_foreign_key :emails, :user_id
          end
          def down
            remove_foreign_key_if_exists :emails, column: :user_id
          end
        end
      RUBY
    end
  end

  context 'when outside of migration' do
    it 'registers no offense' do
      expect_no_offenses(<<~RUBY)
        class SomeMigration
          disable_ddl_transaction!
          def up
            validate_foreign_key :deployments, :environment_id
          end
        end
      RUBY
    end
  end
end
