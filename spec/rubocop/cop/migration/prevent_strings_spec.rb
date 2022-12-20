# frozen_string_literal: true

require 'rubocop_spec_helper'
require_relative '../../../../rubocop/cop/migration/prevent_strings'

RSpec.describe RuboCop::Cop::Migration::PreventStrings do
  context 'when in migration' do
    before do
      allow(cop).to receive(:in_migration?).and_return(true)
    end

    context 'when the string data type is used' do
      it 'registers an offense' do
        expect_offense(<<~RUBY, msg: "Do not use the `string` data type, use `text` instead.[...]")
          class Users < ActiveRecord::Migration[6.0]
            def up
              create_table :users do |t|
                t.string :username, null: false
                  ^^^^^^ %{msg}

                t.timestamps_with_timezone null: true

                t.string :password
                  ^^^^^^ %{msg}
              end

              add_column(:users, :bio, :string)
              ^^^^^^^^^^ %{msg}

              add_column(:users, :url, :string, default: '/-/user', allow_null: false, limit: 255)
              ^^^^^^^^^^ %{msg}

              change_column_type_concurrently :users, :commit_id, :string
              ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^ %{msg}
            end
          end
        RUBY
      end
    end

    context 'when the string data type is not used' do
      it 'registers no offense' do
        expect_no_offenses(<<~RUBY)
          class Users < ActiveRecord::Migration[6.0]
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
            def up
              create_table :users do |t|
                t.text :username, null: false
                t.timestamps_with_timezone null: true
                t.text :password
              end

              add_column(:users, :bio, :text)
              add_column(:users, :url, :text, default: '/-/user', allow_null: false, limit: 255)
              change_column_type_concurrently :users, :commit_id, :text
            end
          end
        RUBY
      end
    end

    context 'when the string data type is used for arrays' do
      it 'registers no offense' do
        expect_no_offenses(<<~RUBY)
          class TestStringArrays < ActiveRecord::Migration[6.0]
            def up
              create_table :test_string_arrays, id: false do |t|
                t.integer :test_id, null: false
                t.string :name, array: true, default: [], null: false
              end

              add_column :test_string_arrays, :email, :string, array: true
              add_column :test_string_arrays, :role, :string, default: [], array: true
              change_column_type_concurrently :test_string_arrays, :test_id, :string, array: true
            end
          end
        RUBY
      end
    end

    context 'when using down method' do
      it 'registers no offense' do
        expect_no_offenses(<<~RUBY)
          class Users < ActiveRecord::Migration[6.0]
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
              add_column(:users, :url, :string, default: '/-/user', allow_null: false, limit: 255)
              change_column_type_concurrently :users, :commit_id, :string
            end
          end
        RUBY
      end
    end
  end

  context 'when outside of migration' do
    it 'registers no offense' do
      expect_no_offenses(<<~RUBY)
        class Users < ActiveRecord::Migration[6.0]
          def up
            create_table :users do |t|
              t.string :username, null: false
              t.timestamps_with_timezone null: true
              t.string :password
            end

            add_column(:users, :bio, :string)
            add_column(:users, :url, :string, default: '/-/user', allow_null: false, limit: 255)
            change_column_type_concurrently :users, :commit_id, :string
          end
        end
      RUBY
    end
  end
end
