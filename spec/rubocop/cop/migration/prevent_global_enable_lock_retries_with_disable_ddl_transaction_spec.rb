# frozen_string_literal: true

require 'rubocop_spec_helper'
require_relative '../../../../rubocop/cop/migration/prevent_global_enable_lock_retries_with_disable_ddl_transaction'

RSpec.describe RuboCop::Cop::Migration::PreventGlobalEnableLockRetriesWithDisableDdlTransaction do
  context 'when in migration' do
    before do
      allow(cop).to receive(:in_migration?).and_return(true)
    end

    it 'registers an offense when `enable_lock_retries` and `disable_ddl_transaction` is used together' do
      code = <<~RUBY
      class SomeMigration < ActiveRecord::Migration[6.0]
        enable_lock_retries!
        disable_ddl_transaction!
      end
      RUBY

      expect_offense(<<~RUBY, node: code, msg: described_class::MSG)
        class SomeMigration < ActiveRecord::Migration[6.0]
          enable_lock_retries!
          disable_ddl_transaction!
          ^^^^^^^^^^^^^^^^^^^^^^^^ %{msg}
        end
      RUBY
    end

    it 'registers no offense when `enable_lock_retries!` is used' do
      expect_no_offenses(<<~RUBY)
        class SomeMigration < ActiveRecord::Migration[6.0]
          enable_lock_retries!
        end
      RUBY
    end

    it 'registers no offense when `disable_ddl_transaction!` is used' do
      expect_no_offenses(<<~RUBY)
        class SomeMigration < ActiveRecord::Migration[6.0]
          disable_ddl_transaction!
        end
      RUBY
    end
  end

  context 'when outside of migration' do
    it 'registers no offense' do
      expect_no_offenses(<<~RUBY)
        class SomeMigration
          enable_lock_retries!
          disable_ddl_transaction!
        end
      RUBY
    end
  end
end
