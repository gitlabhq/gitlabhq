# frozen_string_literal: true

require 'fast_spec_helper'
require_relative '../../../../rubocop/cop/migration/add_concurrent_foreign_key'

RSpec.describe RuboCop::Cop::Migration::AddConcurrentForeignKey do
  let(:cop) { described_class.new }

  context 'when outside of a migration' do
    it 'does not register any offenses' do
      expect_no_offenses('def up; add_foreign_key(:projects, :users, column: :user_id); end')
    end
  end

  context 'when in a migration' do
    before do
      allow(cop).to receive(:in_migration?).and_return(true)
    end

    it 'registers an offense when using add_foreign_key' do
      expect_offense(<<~RUBY)
        def up
          add_foreign_key(:projects, :users, column: :user_id)
          ^^^^^^^^^^^^^^^ `add_foreign_key` requires downtime, use `add_concurrent_foreign_key` instead
        end
      RUBY
    end

    it 'does not register an offense when a `NOT VALID` foreign key is added' do
      expect_no_offenses('def up; add_foreign_key(:projects, :users, column: :user_id, validate: false); end')
    end

    it 'does not register an offense when `add_foreign_key` is within `with_lock_retries`' do
      expect_no_offenses(<<~RUBY)
        with_lock_retries do
          add_foreign_key :key, :projects, column: :project_id, on_delete: :cascade
        end
      RUBY
    end
  end
end
