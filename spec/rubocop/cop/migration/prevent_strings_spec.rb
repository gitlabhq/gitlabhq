# frozen_string_literal: true

require 'spec_helper'
require 'rubocop'
require 'rubocop/rspec/support'

require_relative '../../../../rubocop/cop/migration/prevent_strings'

describe RuboCop::Cop::Migration::PreventStrings do
  include CopHelper

  subject(:cop) { described_class.new }

  context 'in migration' do
    before do
      allow(cop).to receive(:in_migration?).and_return(true)
    end

    context 'when the string data type is used' do
      it 'registers an offense' do
        expect_offense(<<~RUBY)
          class Users < ActiveRecord::Migration[6.0]
            DOWNTIME = false

            def up
              create_table :users do |t|
                t.string :username, null: false
                  ^^^^^^ #{described_class::MSG}

                t.timestamps_with_timezone null: true

                t.string :password
                  ^^^^^^ #{described_class::MSG}
              end

              add_column(:users, :bio, :string)
              ^^^^^^^^^^ #{described_class::MSG}

              add_column_with_default(:users, :url, :string, default: '/-/user', allow_null: false, limit: 255)
              ^^^^^^^^^^^^^^^^^^^^^^^ #{described_class::MSG}

              change_column_type_concurrently :users, :commit_id, :string
              ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^ #{described_class::MSG}
            end
          end
        RUBY

        expect(cop.offenses.map(&:cop_name)).to all(eq('Migration/PreventStrings'))
      end
    end

    context 'when the string data type is not used' do
      it 'registers no offense' do
        expect_no_offenses(<<~RUBY)
          class Users < ActiveRecord::Migration[6.0]
            DOWNTIME = false

            def up
              create_table :users do |t|
                t.integer :not_a_string, null: false
                t.timestamps_with_timezone null: true
              end

              add_column(:users, :not_a_string, :integer)
            end
          end
        RUBY
      end
    end

    context 'when the text data type is used' do
      it 'registers no offense' do
        expect_no_offenses(<<~RUBY)
          class Users < ActiveRecord::Migration[6.0]
            DOWNTIME = false

            def up
              create_table :users do |t|
                t.text :username, null: false
                t.timestamps_with_timezone null: true
                t.text :password
              end

              add_column(:users, :bio, :text)
              add_column_with_default(:users, :url, :text, default: '/-/user', allow_null: false, limit: 255)
              change_column_type_concurrently :users, :commit_id, :text
            end
          end
        RUBY
      end
    end

    context 'on down' do
      it 'registers no offense' do
        expect_no_offenses(<<~RUBY)
          class Users < ActiveRecord::Migration[6.0]
            DOWNTIME = false

            def up
              remove_column :users, :bio
              remove_column :users, :url

              drop_table :test_strings
            end

            def down
              create_table :test_strings, id: false do |t|
                t.integer :test_id, null: false
                t.string :name
              end

              add_column(:users, :bio, :string)
              add_column_with_default(:users, :url, :string, default: '/-/user', allow_null: false, limit: 255)
              change_column_type_concurrently :users, :commit_id, :string
            end
          end
        RUBY
      end
    end
  end

  context 'outside of migration' do
    it 'registers no offense' do
      expect_no_offenses(<<~RUBY)
        class Users < ActiveRecord::Migration[6.0]
          DOWNTIME = false

          def up
            create_table :users do |t|
              t.string :username, null: false
              t.timestamps_with_timezone null: true
              t.string :password
            end

            add_column(:users, :bio, :string)
            add_column_with_default(:users, :url, :string, default: '/-/user', allow_null: false, limit: 255)
            change_column_type_concurrently :users, :commit_id, :string
          end
        end
      RUBY
    end
  end
end
