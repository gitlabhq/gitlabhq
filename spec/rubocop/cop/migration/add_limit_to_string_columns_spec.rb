# frozen_string_literal: true

require 'spec_helper'
require 'rubocop'
require 'rubocop/rspec/support'

require_relative '../../../../rubocop/cop/migration/add_limit_to_string_columns'

describe RuboCop::Cop::Migration::AddLimitToStringColumns do
  include CopHelper

  subject(:cop) { described_class.new }

  context 'in migration' do
    before do
      allow(cop).to receive(:in_migration?).and_return(true)

      inspect_source(migration)
    end

    context 'when creating a table' do
      context 'with string columns and limit' do
        let(:migration) do
          %q(
           class CreateUsers < ActiveRecord::Migration[5.2]
             DOWNTIME = false

             def change
               create_table :users do |t|
                 t.string :username, null: false, limit: 255
                 t.timestamps_with_timezone null: true
               end
             end
           end
          )
        end

        it 'register no offense' do
          expect(cop.offenses.size).to eq(0)
        end

        context 'with limit in a different position' do
          let(:migration) do
            %q(
             class CreateUsers < ActiveRecord::Migration[5.2]
               DOWNTIME = false

               def change
                 create_table :users do |t|
                   t.string :username, limit: 255, null: false
                   t.timestamps_with_timezone null: true
                 end
               end
             end
            )
          end

          it 'registers an offense' do
            expect(cop.offenses.size).to eq(0)
          end
        end
      end

      context 'with string columns and no limit' do
        let(:migration) do
          %q(
           class CreateUsers < ActiveRecord::Migration[5.2]
             DOWNTIME = false

             def change
               create_table :users do |t|
                 t.string :username, null: false
                 t.timestamps_with_timezone null: true
               end
             end
           end
          )
        end

        it 'registers an offense' do
          expect(cop.offenses.size).to eq(1)
          expect(cop.offenses.first.message)
            .to eq('String columns should have a limit constraint. 255 is suggested')
        end
      end

      context 'with no string columns' do
        let(:migration) do
          %q(
            class CreateMilestoneReleases < ActiveRecord::Migration[5.2]
              DOWNTIME = false

              def change
                create_table :milestone_releases do |t|
                  t.integer :milestone_id
                  t.integer :release_id
                end
              end
            end
          )
        end

        it 'register no offense' do
          expect(cop.offenses.size).to eq(0)
        end
      end
    end

    context 'when adding columns' do
      context 'with string columns with limit' do
        let(:migration) do
          %q(
            class AddEmailToUsers < ActiveRecord::Migration[5.2]
              DOWNTIME = false

              def change
                add_column :users, :email, :string, limit: 255
              end
            end
          )
        end

        it 'registers no offense' do
          expect(cop.offenses.size).to eq(0)
        end

        context 'with limit in a different position' do
          let(:migration) do
            %q(
              class AddEmailToUsers < ActiveRecord::Migration[5.2]
                DOWNTIME = false

                def change
                  add_column :users, :email, :string, limit: 255, default: 'example@email.com'
                end
              end
            )
          end

          it 'registers no offense' do
            expect(cop.offenses.size).to eq(0)
          end
        end
      end

      context 'with string columns with no limit' do
        let(:migration) do
          %q(
            class AddEmailToUsers < ActiveRecord::Migration[5.2]
              DOWNTIME = false

              def change
                add_column :users, :email, :string
              end
            end
          )
        end

        it 'registers offense' do
          expect(cop.offenses.size).to eq(1)
          expect(cop.offenses.first.message)
            .to eq('String columns should have a limit constraint. 255 is suggested')
        end
      end

      context 'with no string columns' do
        let(:migration) do
          %q(
            class AddEmailToUsers < ActiveRecord::Migration[5.2]
              DOWNTIME = false

              def change
                add_column :users, :active, :boolean, default: false
              end
            end
          )
        end

        it 'registers no offense' do
          expect(cop.offenses.size).to eq(0)
        end
      end
    end

    context 'with add_column_with_default' do
      context 'with a limit' do
        let(:migration) do
          %q(
           class AddRuleTypeToApprovalMergeRequestRules < ActiveRecord::Migration[5.2]
             DOWNTIME = false

             def change
               add_column_with_default(:approval_merge_request_rules, :rule_type, :string, limit: 2, default: 1)
             end
           end
           )
        end

        it 'registers no offense' do
          expect(cop.offenses.size).to eq(0)
        end
      end

      context 'without a limit' do
        let(:migration) do
          %q(
           class AddRuleTypeToApprovalMergeRequestRules < ActiveRecord::Migration[5.2]
             DOWNTIME = false

             def change
               add_column_with_default(:approval_merge_request_rules, :rule_type, :string, default: 1)
             end
           end
           )
        end

        it 'registers an offense' do
          expect(cop.offenses.size).to eq(1)
        end
      end
    end

    context 'with methods' do
      let(:migration) do
        %q(
          class AddEmailToUsers < ActiveRecord::Migration[5.2]
            DOWNTIME = false

            def change
              add_column_if_table_not_exists :users, :first_name, :string, limit: 255
              search_namespace(user_name)
            end

            def add_column_if_not_exists(table, name, *args)
              add_column(table, name, *args) unless column_exists?(table, name)
            end

            def search_namespace(username)
               Uniquify.new.string(username) do |str|
                query = "SELECT id FROM namespaces WHERE parent_id IS NULL AND path='#{str}' LIMIT 1"
                connection.exec_query(query)
              end
            end
          end
        )
      end

      it 'registers no offense' do
        expect(cop.offenses.size).to eq(0)
      end
    end
  end

  context 'outside of migrations' do
    let(:active_record_model) do
      %q(
      class User < ApplicationRecord
      end
      )
    end

    it 'registers no offense' do
      inspect_source(active_record_model)

      expect(cop.offenses.size).to eq(0)
    end
  end
end
