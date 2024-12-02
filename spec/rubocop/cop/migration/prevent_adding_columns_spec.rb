# frozen_string_literal: true

require 'rubocop_spec_helper'
require_relative '../../../../rubocop/cop/migration/prevent_adding_columns'

RSpec.describe RuboCop::Cop::Migration::PreventAddingColumns, feature_category: :database do
  context 'when outside of a migration' do
    it 'does not register any offenses' do
      expect_no_offenses(<<~RUBY)
        def up
          add_column(:users, :another_column, :string)
        end
      RUBY
    end
  end

  context 'when in a migration' do
    before do
      allow(cop).to receive(:in_migration?).and_return(true)
    end

    context 'with wide tables' do
      it 'registers an offense when adding a column to a wide table' do
        offense = '`projects` is over the limit authorized, [...]'

        expect_offense(<<~RUBY)
          def up
            add_column(:projects, :another_column, :integer)
            ^^^^^^^^^^ #{offense}
          end
        RUBY
      end

      it 'registers an offense when adding a column with default to a wide table' do
        offense = '`users` is over the limit authorized, [...]'

        expect_offense(<<~RUBY)
          def up
            add_column(:users, :another_column, :boolean, default: false)
            ^^^^^^^^^^ #{offense}
          end
        RUBY
      end

      it 'registers an offense when adding a reference' do
        offense = '`ci_builds` is over the limit authorized, [...]'

        expect_offense(<<~RUBY)
          def up
            add_reference(:ci_builds, :issue, :boolean, index: true)
            ^^^^^^^^^^^^^ #{offense}
          end
        RUBY
      end

      it 'registers an offense when adding timestamps' do
        offense = '`projects` is over the limit authorized, [...]'

        expect_offense(<<~RUBY)
          def up
            add_timestamps_with_timezone(:projects, null: false)
            ^^^^^^^^^^^^^^^^^^^^^^^^^^^^ #{offense}
          end
        RUBY
      end

      it 'register no offense when using other method' do
        expect_no_offenses(<<~RUBY)
          def up
            add_concurrent_index(:projects, :new_index)
          end
        RUBY
      end
    end

    context 'with a regular table' do
      it 'registers no offense for licenses' do
        expect_no_offenses(<<~RUBY)
          def up
            add_column(:licenses, :another_column, :boolean)
          end
        RUBY
      end
    end

    context 'when targeting an over limit table' do
      it 'registers an offense for issues' do
        offense = '`issues` is over the limit authorized, [...]'

        expect_offense(<<~RUBY)
          def up
            add_column(:issues, :another_column, :boolean, default: false)
            ^^^^^^^^^^ #{offense}
          end
        RUBY
      end
    end

    context 'when rolling back migration' do
      it 'registers no offense' do
        expect_no_offenses(<<~RUBY)
          def down
            add_column(:notes, :another_column, :boolean, default: false)
          end
        RUBY
      end
    end
  end
end
