# frozen_string_literal: true

require 'spec_helper'
require 'rubocop'
require 'rubocop/rspec/support'

require_relative '../../../../rubocop/cop/migration/add_limit_to_text_columns'

describe RuboCop::Cop::Migration::AddLimitToTextColumns do
  include CopHelper

  subject(:cop) { described_class.new }

  context 'in migration' do
    before do
      allow(cop).to receive(:in_migration?).and_return(true)
    end

    context 'when text columns are defined without a limit' do
      it 'registers an offense' do
        expect_offense(<<~RUBY)
          class TestTextLimits < ActiveRecord::Migration[6.0]
            DOWNTIME = false
            disable_ddl_transaction!

            def up
              create_table :test_text_limits, id: false do |t|
                t.integer :test_id, null: false
                t.text :name
                  ^^^^ #{described_class::MSG}
              end

              add_column :test_text_limits, :email, :text
              ^^^^^^^^^^ #{described_class::MSG}

              add_column_with_default :test_text_limits, :role, :text, default: 'default'
              ^^^^^^^^^^^^^^^^^^^^^^^ #{described_class::MSG}

              change_column_type_concurrently :test_text_limits, :test_id, :text
              ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^ #{described_class::MSG}
            end
          end
        RUBY

        expect(cop.offenses.map(&:cop_name)).to all(eq('Migration/AddLimitToTextColumns'))
      end
    end

    context 'when text columns are defined with a limit' do
      it 'registers no offense' do
        expect_no_offenses(<<~RUBY)
          class TestTextLimits < ActiveRecord::Migration[6.0]
            DOWNTIME = false
            disable_ddl_transaction!

            def up
              create_table :test_text_limits, id: false do |t|
                t.integer :test_id, null: false
                t.text :name
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
            DOWNTIME = false

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
    # over the same {table, attribute} as the one that triggered the offence
    context 'when the limit is defined for a same name attribute but different table' do
      it 'registers an offense' do
        expect_offense(<<~RUBY)
          class TestTextLimits < ActiveRecord::Migration[6.0]
            DOWNTIME = false
            disable_ddl_transaction!

            def up
              create_table :test_text_limits, id: false do |t|
                t.integer :test_id, null: false
                t.text :name
                  ^^^^ #{described_class::MSG}
              end

              add_column :test_text_limits, :email, :text
              ^^^^^^^^^^ #{described_class::MSG}

              add_column_with_default :test_text_limits, :role, :text, default: 'default'
              ^^^^^^^^^^^^^^^^^^^^^^^ #{described_class::MSG}

              change_column_type_concurrently :test_text_limits, :test_id, :text
              ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^ #{described_class::MSG}

              add_text_limit :wrong_table, :name, 255
              add_text_limit :wrong_table, :email, 255
              add_text_limit :wrong_table, :role, 255
              add_text_limit :wrong_table, :test_id, 255
            end
          end
        RUBY

        expect(cop.offenses.map(&:cop_name)).to all(eq('Migration/AddLimitToTextColumns'))
      end
    end

    context 'on down' do
      it 'registers no offense' do
        expect_no_offenses(<<~RUBY)
          class TestTextLimits < ActiveRecord::Migration[6.0]
            DOWNTIME = false

            def up
              drop_table :no_offence_on_down
            end

            def down
              create_table :no_offence_on_down, id: false do |t|
                t.integer :test_id, null: false
                t.text :name
              end

              add_column :no_offence_on_down, :email, :text

              add_column_with_default :no_offence_on_down, :role, :text, default: 'default'
            end
          end
        RUBY
      end
    end
  end

  context 'outside of migration' do
    it 'registers no offense' do
      expect_no_offenses(<<~RUBY)
        class TestTextLimits < ActiveRecord::Migration[6.0]
          DOWNTIME = false
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
