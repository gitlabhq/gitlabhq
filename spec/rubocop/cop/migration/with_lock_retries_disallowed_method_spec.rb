# frozen_string_literal: true

require 'rubocop_spec_helper'
require_relative '../../../../rubocop/cop/migration/with_lock_retries_disallowed_method'

RSpec.describe RuboCop::Cop::Migration::WithLockRetriesDisallowedMethod, feature_category: :database do
  context 'when in migration' do
    before do
      allow(cop).to receive(:in_migration?).and_return(true)
    end

    it 'registers an offense when `with_lock_retries` block has disallowed method' do
      expect_offense(<<~RUBY)
        def change
          with_lock_retries { disallowed_method }
                              ^^^^^^^^^^^^^^^^^ The method is not allowed [...]
        end
      RUBY
    end

    it 'registers an offense when `with_lock_retries` block has disallowed methods' do
      expect_offense(<<~RUBY)
        def change
          with_lock_retries do
            disallowed_method
            ^^^^^^^^^^^^^^^^^ The method is not allowed [...]

            create_table do |t|
              t.text :text
            end

            other_disallowed_method
            ^^^^^^^^^^^^^^^^^^^^^^^ The method is not allowed [...]

            add_column :users, :name
          end
        end
      RUBY
    end

    it 'registers no offense when `with_lock_retries` has only allowed method' do
      expect_no_offenses(<<~RUBY)
        def up
          with_lock_retries { add_foreign_key :foo, :bar }
        end
      RUBY
    end

    describe 'for `add_foreign_key`' do
      it 'registers an offense when more than two FKs are added' do
        message = described_class::MSG_ONLY_ONE_FK_ALLOWED

        expect_offense(<<~RUBY)
          with_lock_retries do
            add_foreign_key :imports, :projects, column: :project_id, on_delete: :cascade
            ^^^^^^^^^^^^^^^ #{message}
            add_column :projects, :name, :text
            add_foreign_key :imports, :users, column: :user_id, on_delete: :cascade
            ^^^^^^^^^^^^^^^ #{message}
          end
        RUBY
      end
    end
  end

  context 'when outside of migration' do
    it 'registers no offense' do
      expect_no_offenses(<<~RUBY)
        def change
          with_lock_retries { disallowed_method }
        end
      RUBY
    end
  end
end
