# frozen_string_literal: true

require 'fast_spec_helper'
require_relative '../../../../rubocop/cop/migration/add_columns_to_wide_tables'

RSpec.describe RuboCop::Cop::Migration::AddColumnsToWideTables do
  let(:cop) { described_class.new }

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
        offense = '`projects` is a wide table with several columns, [...]'

        expect_offense(<<~RUBY)
          def up
            add_column(:projects, :another_column, :integer)
            ^^^^^^^^^^ #{offense}
          end
        RUBY
      end

      it 'registers an offense when adding a column with default to a wide table' do
        offense = '`users` is a wide table with several columns, [...]'

        expect_offense(<<~RUBY)
          def up
            add_column(:users, :another_column, :boolean, default: false)
            ^^^^^^^^^^ #{offense}
          end
        RUBY
      end

      it 'registers an offense when adding a reference' do
        offense = '`ci_builds` is a wide table with several columns, [...]'

        expect_offense(<<~RUBY)
          def up
            add_reference(:ci_builds, :issue, :boolean, index: true)
            ^^^^^^^^^^^^^ #{offense}
          end
        RUBY
      end

      it 'registers an offense when adding timestamps' do
        offense = '`projects` is a wide table with several columns, [...]'

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
      it 'registers no offense for notes' do
        expect_no_offenses(<<~RUBY)
          def up
            add_column(:notes, :another_column, :boolean)
          end
        RUBY
      end
    end
  end
end
