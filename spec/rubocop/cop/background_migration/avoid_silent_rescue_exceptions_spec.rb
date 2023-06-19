# frozen_string_literal: true

require 'rubocop_spec_helper'
require_relative '../../../../rubocop/cop/background_migration/avoid_silent_rescue_exceptions'

RSpec.describe RuboCop::Cop::BackgroundMigration::AvoidSilentRescueExceptions, feature_category: :database do
  shared_examples 'expecting offense when' do |node|
    it 'throws offense when rescuing exceptions without re-raising them' do
      %w[Gitlab::BackgroundMigration::BatchedMigrationJob BatchedMigrationJob].each do |base_class|
        expect_offense(<<~RUBY)
          module Gitlab
            module BackgroundMigration
              class MyJob < #{base_class}
                #{node}
              end
            end
          end
        RUBY
      end
    end
  end

  shared_examples 'not expecting offense when' do |node|
    it 'does not throw any offense if exception is re-raised' do
      %w[Gitlab::BackgroundMigration::BatchedMigrationJob BatchedMigrationJob].each do |base_class|
        expect_no_offenses(<<~RUBY)
          module Gitlab
            module BackgroundMigration
              class MyJob < #{base_class}
                #{node}
              end
            end
          end
        RUBY
      end
    end
  end

  context "when the migration class doesn't inherits from BatchedMigrationJob" do
    it 'does not throw any offense' do
      expect_no_offenses(<<~RUBY)
        module Gitlab
          module BackgroundMigration
            class MyClass < ::Gitlab::BackgroundMigration::Logger
              def my_method
                execute
              rescue StandardError => error
                puts error.message
              end
            end
          end
        end
      RUBY
    end
  end

  context 'when the migration class inherits from BatchedMigrationJob' do
    context 'when specifying an error class' do
      it_behaves_like 'expecting offense when', <<~RUBY
        def perform
          connection.execute('SELECT 1;')
        rescue JSON::ParserError
        ^^^^^^^^^^^^^^^^^^^^^^^^ #{described_class::MSG}
          logger.error(message: error.message, class: self.class.name)
        end
      RUBY

      it_behaves_like 'expecting offense when', <<~RUBY
        def perform
          connection.execute('SELECT 1;')
        rescue StandardError, ActiveRecord::StatementTimeout => error
        ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^ #{described_class::MSG}
          logger.error(message: error.message, class: self.class.name)
        end
      RUBY

      it_behaves_like 'not expecting offense when', <<~RUBY
        def perform
          connection.execute('SELECT 1;')
        rescue StandardError, ActiveRecord::StatementTimeout => error
          logger.error(message: error.message, class: self.class.name)
          raise error
        end
      RUBY
    end

    context 'without specifying an error class' do
      it_behaves_like 'expecting offense when', <<~RUBY
        def perform
          connection.execute('SELECT 1;')
        rescue => error
        ^^^^^^ #{described_class::MSG}
          logger.error(message: error.message, class: self.class.name)
        end
      RUBY

      it_behaves_like 'not expecting offense when', <<~RUBY
        def perform
          connection.execute('SELECT 1;')
        rescue => error
          logger.error(message: error.message, class: self.class.name)
          raise error
        end
      RUBY
    end
  end
end
