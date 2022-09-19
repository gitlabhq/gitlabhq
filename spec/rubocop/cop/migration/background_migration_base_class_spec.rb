# frozen_string_literal: true

require 'rubocop_spec_helper'
require_relative '../../../../rubocop/cop/migration/background_migration_base_class'

RSpec.describe RuboCop::Cop::Migration::BackgroundMigrationBaseClass do
  context 'when the migration class inherits from BatchedMigrationJob' do
    it 'does not register any offenses' do
      expect_no_offenses(<<~RUBY)
        module Gitlab
          module BackgroundMigration
            class MyJob < BatchedMigrationJob
              def perform
                connection.execute("select 1")
              end
            end
          end
        end
      RUBY
    end
  end

  context 'when the migration class inherits from the namespaced BatchedMigrationJob' do
    it 'does not register any offenses' do
      expect_no_offenses(<<~RUBY)
        module Gitlab
          module BackgroundMigration
            class MyJob < Gitlab::BackgroundMigration::BatchedMigrationJob
              def perform
                connection.execute("select 1")
              end
            end
          end
        end
      RUBY
    end
  end

  context 'when the migration class inherits from the top-level namespaced BatchedMigrationJob' do
    it 'does not register any offenses' do
      expect_no_offenses(<<~RUBY)
        module Gitlab
          module BackgroundMigration
            class MyJob < ::Gitlab::BackgroundMigration::BatchedMigrationJob
              def perform
                connection.execute("select 1")
              end
            end
          end
        end
      RUBY
    end
  end

  context 'when a nested class is used inside the job class' do
    it 'does not register any offenses' do
      expect_no_offenses(<<~RUBY)
        module Gitlab
          module BackgroundMigration
            class MyJob < BatchedMigrationJob
              class Project < ApplicationRecord
                self.table_name = 'projects'
              end

              def perform
                Project.update!(name: 'hi')
              end
            end
          end
        end
      RUBY
    end
  end

  context 'when the migration class inherits from another class' do
    it 'registers an offense' do
      expect_offense(<<~RUBY)
        module Gitlab
          module BackgroundMigration
            class MyJob < SomeOtherClass
            ^^^^^^^^^^^^^^^^^^^^^^^^^^^^ #{described_class::MSG}
            end
          end
        end
      RUBY
    end
  end

  context 'when the migration class does not inherit from anything' do
    it 'registers an offense' do
      expect_offense(<<~RUBY)
        module Gitlab
          module BackgroundMigration
            class MyJob
            ^^^^^^^^^^^ #{described_class::MSG}
            end
          end
        end
      RUBY
    end
  end
end
