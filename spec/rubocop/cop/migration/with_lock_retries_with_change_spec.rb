# frozen_string_literal: true

require 'rubocop_spec_helper'
require_relative '../../../../rubocop/cop/migration/with_lock_retries_with_change'

RSpec.describe RuboCop::Cop::Migration::WithLockRetriesWithChange do
  context 'when in migration' do
    before do
      allow(cop).to receive(:in_migration?).and_return(true)
    end

    it 'registers an offense when `with_lock_retries` is used inside a `change` method' do
      expect_offense(<<~RUBY)
        def change
            ^^^^^^ `with_lock_retries` cannot be used within `change` [...]
          with_lock_retries {}
        end
      RUBY
    end

    it 'registers no offense when `with_lock_retries` is used inside an `up` method' do
      expect_no_offenses(<<~RUBY)
        def up
          with_lock_retries {}
        end
      RUBY
    end
  end

  context 'when outside of migration' do
    it 'registers no offense' do
      expect_no_offenses(<<~RUBY)
        def change
          with_lock_retries {}
        end
      RUBY
    end
  end
end
