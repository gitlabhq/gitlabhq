# frozen_string_literal: true

require 'fast_spec_helper'
require_relative '../../../../rubocop/cop/migration/datetime'

RSpec.describe RuboCop::Cop::Migration::Datetime do
  subject(:cop) { described_class.new }

  let(:create_table_migration_without_datetime) do
    %q(
      class Users < ActiveRecord::Migration[6.0]
        def change
          create_table :users do |t|
            t.string :username, null: false
            t.string :password
          end
        end
      end
    )
  end

  let(:create_table_migration_with_datetime_with_timezone) do
    %q(
      class Users < ActiveRecord::Migration[6.0]
        def change
          create_table :users do |t|
            t.string :username, null: false
            t.datetime_with_timezone :last_sign_in
          end
        end
      end
    )
  end

  let(:add_column_migration_with_datetime) do
    %q(
      class Users < ActiveRecord::Migration[6.0]
        def change
          add_column(:users, :username, :text)
          add_column(:users, :last_sign_in, :datetime)
        end
      end
    )
  end

  let(:add_column_migration_with_timestamp) do
    %q(
      class Users < ActiveRecord::Migration[6.0]
        def change
          add_column(:users, :username, :text)
          add_column(:users, :last_sign_in, :timestamp)
        end
      end
    )
  end

  let(:add_column_migration_without_datetime) do
    %q(
      class Users < ActiveRecord::Migration[6.0]
        def change
          add_column(:users, :username, :text)
        end
      end
    )
  end

  let(:add_column_migration_with_datetime_with_timezone) do
    %q(
      class Users < ActiveRecord::Migration[6.0]
        def change
          add_column(:users, :username, :text)
          add_column(:users, :last_sign_in, :datetime_with_timezone)
        end
      end
    )
  end

  context 'when in migration' do
    before do
      allow(cop).to receive(:in_migration?).and_return(true)
    end

    it 'registers an offense when the ":datetime" data type is used on create_table' do
      expect_offense(<<~RUBY)
        class Users < ActiveRecord::Migration[6.0]
          def change
            create_table :users do |t|
              t.string :username, null: false
              t.datetime :last_sign_in
                ^^^^^^^^ Do not use the `datetime` data type[...]
            end
          end
        end
      RUBY
    end

    it 'registers an offense when the ":timestamp" data type is used on create_table' do
      expect_offense(<<~RUBY)
        class Users < ActiveRecord::Migration[6.0]
          def change
            create_table :users do |t|
              t.string :username, null: false
              t.timestamp :last_sign_in
                ^^^^^^^^^ Do not use the `timestamp` data type[...]
            end
          end
        end
      RUBY
    end

    it 'does not register an offense when the ":datetime" data type is not used on create_table' do
      expect_no_offenses(create_table_migration_without_datetime)
    end

    it 'does not register an offense when the ":datetime_with_timezone" data type is used on create_table' do
      expect_no_offenses(create_table_migration_with_datetime_with_timezone)
    end

    it 'registers an offense when the ":datetime" data type is used on add_column' do
      expect_offense(<<~RUBY)
        class Users < ActiveRecord::Migration[6.0]
          def change
            add_column(:users, :username, :text)
            add_column(:users, :last_sign_in, :datetime)
            ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^ Do not use the `datetime` data type[...]
          end
        end
      RUBY
    end

    it 'registers an offense when the ":timestamp" data type is used on add_column' do
      expect_offense(<<~RUBY)
        class Users < ActiveRecord::Migration[6.0]
          def change
            add_column(:users, :username, :text)
            add_column(:users, :last_sign_in, :timestamp)
            ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^ Do not use the `timestamp` data type[...]
          end
        end
      RUBY
    end

    it 'does not register an offense when the ":datetime" data type is not used on add_column' do
      expect_no_offenses(add_column_migration_without_datetime)
    end

    it 'does not register an offense when the ":datetime_with_timezone" data type is used on add_column' do
      expect_no_offenses(add_column_migration_with_datetime_with_timezone)
    end
  end

  context 'when outside of migration' do
    it 'registers no offense', :aggregate_failures do
      expect_no_offenses(add_column_migration_with_datetime)
      expect_no_offenses(add_column_migration_with_timestamp)
      expect_no_offenses(add_column_migration_without_datetime)
      expect_no_offenses(add_column_migration_with_datetime_with_timezone)
    end
  end
end
