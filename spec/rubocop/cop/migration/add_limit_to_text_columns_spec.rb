# frozen_string_literal: true

require 'fast_spec_helper'
require_relative '../../../../rubocop/cop/migration/add_limit_to_text_columns'

RSpec.describe RuboCop::Cop::Migration::AddLimitToTextColumns do
  subject(:cop) { described_class.new }

  context 'when in migration' do
    let(:msg) { 'Text columns should always have a limit set (255 is suggested)[...]' }

    before do
      allow(cop).to receive(:in_migration?).and_return(true)
    end

    context 'when text columns are defined without a limit' do
      it 'registers an offense' do
        expect_offense(<<~RUBY)
          class TestTextLimits < ActiveRecord::Migration[6.0]
            disable_ddl_transaction!

            def up
              create_table :test_text_limits, id: false do |t|
                t.integer :test_id, null: false
                t.text :name
                  ^^^^ #{msg}
              end

              create_table_with_constraints :test_text_limits_create do |t|
                t.integer :test_id, null: false
                t.text :title
                t.text :description
                  ^^^^ #{msg}

                t.text_limit :title, 100
              end

              add_column :test_text_limits, :email, :text
              ^^^^^^^^^^ #{msg}

              add_column_with_default :test_text_limits, :role, :text, default: 'default'
              ^^^^^^^^^^^^^^^^^^^^^^^ #{msg}

              change_column_type_concurrently :test_text_limits, :test_id, :text
              ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^ #{msg}
            end
          end
        RUBY
      end
    end

    context 'when text columns are defined with a limit' do
      it 'registers no offense' do
        expect_no_offenses(<<~RUBY)
          class TestTextLimits < ActiveRecord::Migration[6.0]
            disable_ddl_transaction!

            def up
              create_table :test_text_limits, id: false do |t|
                t.integer :test_id, null: false
                t.text :name
              end

              create_table_with_constraints :test_text_limits_create do |t|
                t.integer :test_id, null: false
                t.text :title
                t.text :description

                t.text_limit :title, 100
                t.text_limit :description, 255
              end

              add_column :test_text_limits, :email, :text
              add_column_with_default :test_text_limits, :role, :text, default: 'default'
              change_column_type_concurrently :test_text_limits, :test_id, :text

              add_text_limit :test_text_limits, :name, 255
              add_text_limit :test_text_limits, :email, 255
              add_text_limit :test_text_limits, :role, 255
              add_text_limit :test_text_limits, :test_id, 255
            end
          end
        RUBY
      end
    end

    context 'when text array columns are defined without a limit' do
      it 'registers no offense' do
        expect_no_offenses(<<~RUBY)
          class TestTextLimits < ActiveRecord::Migration[6.0]
            def up
              create_table :test_text_limits, id: false do |t|
                t.integer :test_id, null: false
                t.text :name, array: true, default: [], null: false
              end

              add_column :test_text_limits, :email, :text, array: true
              add_column_with_default :test_text_limits, :role, :text, default: [], array: true
              change_column_type_concurrently :test_text_limits, :test_id, :text, array: true
            end
          end
        RUBY
      end
    end

    # Make sure that the cop is properly checking for an `add_text_limit`
    # over the same {table, attribute} as the one that triggered the offense
    context 'when the limit is defined for a same name attribute but different table' do
      it 'registers an offense' do
        expect_offense(<<~RUBY)
          class TestTextLimits < ActiveRecord::Migration[6.0]
            disable_ddl_transaction!

            def up
              create_table :test_text_limits, id: false do |t|
                t.integer :test_id, null: false
                t.text :name
                  ^^^^ #{msg}
              end

              add_column :test_text_limits, :email, :text
              ^^^^^^^^^^ #{msg}

              add_column_with_default :test_text_limits, :role, :text, default: 'default'
              ^^^^^^^^^^^^^^^^^^^^^^^ #{msg}

              change_column_type_concurrently :test_text_limits, :test_id, :text
              ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^ #{msg}

              add_text_limit :wrong_table, :name, 255
              add_text_limit :wrong_table, :email, 255
              add_text_limit :wrong_table, :role, 255
              add_text_limit :wrong_table, :test_id, 255
            end
          end
        RUBY
      end
    end

    context 'when text columns are used for encryption' do
      it 'registers no offenses' do
        expect_no_offenses(<<~RUBY)
          class TestTextLimits < ActiveRecord::Migration[6.0]
            disable_ddl_transaction!

            def up
              create_table :test_text_limits, id: false do |t|
                t.integer :test_id, null: false
                t.text :encrypted_name
              end

              add_column :encrypted_test_text_limits, :encrypted_email, :text
              add_column_with_default :encrypted_test_text_limits, :encrypted_role, :text, default: 'default'
              change_column_type_concurrently :encrypted_test_text_limits, :encrypted_test_id, :text
            end
          end
        RUBY
      end
    end

    context 'on down' do
      it 'registers no offense' do
        expect_no_offenses(<<~RUBY)
          class TestTextLimits < ActiveRecord::Migration[6.0]
            def up
              drop_table :no_offense_on_down
            end

            def down
              create_table :no_offense_on_down, id: false do |t|
                t.integer :test_id, null: false
                t.text :name
              end

              add_column :no_offense_on_down, :email, :text

              add_column_with_default :no_offense_on_down, :role, :text, default: 'default'
            end
          end
        RUBY
      end
    end
  end

  context 'when outside of migration' do
    it 'registers no offense' do
      expect_no_offenses(<<~RUBY)
        class TestTextLimits < ActiveRecord::Migration[6.0]
          disable_ddl_transaction!

          def up
            create_table :test_text_limits, id: false do |t|
              t.integer :test_id, null: false
              t.text :name
            end

            add_column :test_text_limits, :email, :text
            add_column_with_default :test_text_limits, :role, :text, default: 'default'
            change_column_type_concurrently :test_text_limits, :test_id, :text
          end
        end
      RUBY
    end
  end
end
