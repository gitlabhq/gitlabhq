# frozen_string_literal: true

require 'rubocop_spec_helper'
require_relative '../../../../rubocop/cop/migration/add_reference'

RSpec.describe RuboCop::Cop::Migration::AddReference do
  context 'when outside of a migration' do
    it 'does not register any offenses' do
      expect_no_offenses(<<~RUBY)
        def up
          add_reference(:projects, :users)
        end
      RUBY
    end
  end

  context 'when in a migration' do
    before do
      allow(cop).to receive(:in_migration?).and_return(true)
    end

    let(:offense) { '`add_reference` requires downtime for existing tables, use `add_concurrent_foreign_key`[...]' }

    context 'when the table existed before' do
      it 'registers an offense when using add_reference' do
        expect_offense(<<~RUBY)
          def up
            add_reference(:projects, :users)
            ^^^^^^^^^^^^^ #{offense}
          end
        RUBY
      end

      it 'registers an offense when using add_reference with index enabled' do
        expect_offense(<<~RUBY)
        def up
          add_reference(:projects, :users, index: true)
          ^^^^^^^^^^^^^ #{offense}
        end
        RUBY
      end

      it 'registers an offense if only a different table was created' do
        expect_offense(<<~RUBY)
        def up
          create_table(:foo) do |t|
            t.string :name
          end
          add_reference(:projects, :users, index: true)
          ^^^^^^^^^^^^^ #{offense}
        end
        RUBY
      end
    end

    context 'when creating the table at the same time' do
      let(:create_table_statement) do
        <<~RUBY
          create_table(:projects) do |t|
            t.string :name
          end
        RUBY
      end

      it 'registers an offense when using add_reference without index' do
        expect_offense(<<~RUBY)
        def up
          #{create_table_statement}
          add_reference(:projects, :users)
          ^^^^^^^^^^^^^ #{offense}
        end
        RUBY
      end

      it 'registers an offense when using add_reference index disabled' do
        expect_offense(<<~RUBY)
        def up
          #{create_table_statement}
          add_reference(:projects, :users, index: false)
          ^^^^^^^^^^^^^ #{offense}
        end
        RUBY
      end

      it 'does not register an offense when using add_reference with index enabled' do
        expect_no_offenses(<<~RUBY)
        def up
          #{create_table_statement}
          add_reference(:projects, :users, index: true)
        end
        RUBY
      end

      it 'does not register an offense when the index is unique' do
        expect_no_offenses(<<~RUBY)
        def up
          #{create_table_statement}
          add_reference(:projects, :users, index: { unique: true } )
        end
        RUBY
      end
    end
  end
end
