# frozen_string_literal: true

require 'rubocop_spec_helper'
require_relative '../../../../rubocop/cop/rake/top_level_method_definition'

RSpec.describe RuboCop::Cop::Rake::TopLevelMethodDefinition, :aggregate_failures, :config, feature_category: :shared do
  context 'in a rake file' do
    let(:source_file) { 'elastic.rake' }

    context 'when method definitions are inside rake namespaces' do
      it 'registers an offense for method definitions' do
        expect_offense(<<~RUBY, source_file)
          namespace :gitlab do
            namespace :elastic do
              def task_executor_service
              ^^^^^^^^^^^^^^^^^^^^^^^^^ Methods defined in rake tasks share the same namespace and can cause collisions. Please define it in a bounded contexts module in a separate Ruby file. For example, Search::RakeTask::<Namespace>. See https://github.com/rubocop/rubocop-rake/issues/42
                Search::RakeTaskExecutorService.new(logger: stdout_logger)
              end
            end
          end
        RUBY
      end

      it 'registers an offense for private method definitions' do
        expect_offense(<<~RUBY, source_file)
          namespace :gitlab do
            namespace :elastic do
              private
          #{'    '}
              def task_executor_service
              ^^^^^^^^^^^^^^^^^^^^^^^^^ Methods defined in rake tasks share the same namespace and can cause collisions. Please define it in a bounded contexts module in a separate Ruby file. For example, Search::RakeTask::<Namespace>. See https://github.com/rubocop/rubocop-rake/issues/42
                Search::RakeTaskExecutorService.new(logger: stdout_logger)
              end
            end
          end
        RUBY
      end

      it 'registers an offense for singleton method definitions' do
        expect_offense(<<~RUBY, 'rakelib/some_task.rake')
          namespace :gitlab do
            namespace :elastic do
              def self.task_executor_service
              ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^ Methods defined in rake tasks share the same namespace and can cause collisions. Please define it in a bounded contexts module in a separate Ruby file. For example, Search::RakeTask::<Namespace>. See https://github.com/rubocop/rubocop-rake/issues/42
                Search::RakeTaskExecutorService.new(logger: stdout_logger)
              end
            end
          end
        RUBY
      end
    end

    context 'when class/module definitions are in rake files' do
      it 'registers an offense for class definitions inside rake namespaces' do
        expect_offense(<<~RUBY, source_file)
          namespace :gitlab do
            namespace :elastic do
              class TaskHelper
              ^^^^^^^^^^^^^^^^ Classes should not be defined in rake files. Please define it in a bounded contexts module in a separate Ruby file. For example, Search::RakeTask::<Namespace>. See https://github.com/rubocop/rubocop-rake/issues/42
                def self.task_executor_service
                ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^ Methods defined in rake tasks share the same namespace and can cause collisions. Please define it in a bounded contexts module in a separate Ruby file. For example, Search::RakeTask::<Namespace>. See https://github.com/rubocop/rubocop-rake/issues/42
                  Search::RakeTaskExecutorService.new(logger: stdout_logger)
                end
              end
            end
          end
        RUBY
      end

      it 'registers an offense for module definitions inside rake namespaces' do
        expect_offense(<<~RUBY, source_file)
          namespace :gitlab do
            namespace :elastic do
              module TaskHelpers
              ^^^^^^^^^^^^^^^^^^ Modules should not be defined in rake files. Please define it in a separate Ruby file. For example, Search::RakeTask::<Namespace>. See https://github.com/rubocop/rubocop-rake/issues/42
                def self.task_executor_service
                ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^ Methods defined in rake tasks share the same namespace and can cause collisions. Please define it in a bounded contexts module in a separate Ruby file. For example, Search::RakeTask::<Namespace>. See https://github.com/rubocop/rubocop-rake/issues/42
                  Search::RakeTaskExecutorService.new(logger: stdout_logger)
                end
              end
            end
          end
        RUBY
      end

      it 'registers an offense for top-level class definitions' do
        expect_offense(<<~RUBY, source_file)
          class TaskHelper
          ^^^^^^^^^^^^^^^^ Classes should not be defined in rake files. Please define it in a bounded contexts module in a separate Ruby file. For example, Search::RakeTask::<Namespace>. See https://github.com/rubocop/rubocop-rake/issues/42
            def self.task_executor_service
            ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^ Methods defined in rake tasks share the same namespace and can cause collisions. Please define it in a bounded contexts module in a separate Ruby file. For example, Search::RakeTask::<Namespace>. See https://github.com/rubocop/rubocop-rake/issues/42
              Search::RakeTaskExecutorService.new(logger: stdout_logger)
            end
          end

          namespace :gitlab do
            namespace :elastic do
              task info: :environment do
                TaskHelper.task_executor_service.execute(:info)
              end
            end
          end
        RUBY
      end

      it 'registers an offense for top-level module definitions' do
        expect_offense(<<~RUBY, source_file)
          module Search
          ^^^^^^^^^^^^^ Modules should not be defined in rake files. Please define it in a separate Ruby file. For example, Search::RakeTask::<Namespace>. See https://github.com/rubocop/rubocop-rake/issues/42
            module RakeTask
            ^^^^^^^^^^^^^^^ Modules should not be defined in rake files. Please define it in a separate Ruby file. For example, Search::RakeTask::<Namespace>. See https://github.com/rubocop/rubocop-rake/issues/42
              module Elastic
              ^^^^^^^^^^^^^^ Modules should not be defined in rake files. Please define it in a separate Ruby file. For example, Search::RakeTask::<Namespace>. See https://github.com/rubocop/rubocop-rake/issues/42
                def self.task_executor_service
                ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^ Methods defined in rake tasks share the same namespace and can cause collisions. Please define it in a bounded contexts module in a separate Ruby file. For example, Search::RakeTask::<Namespace>. See https://github.com/rubocop/rubocop-rake/issues/42
                  Search::RakeTaskExecutorService.new(logger: stdout_logger)
                end
              end
            end
          end

          namespace :gitlab do
            namespace :elastic do
              task info: :environment do
                Search::RakeTask::Elastic.task_executor_service.execute(:info)
              end
            end
          end
        RUBY
      end
    end

    context 'with top-level method definitions outside rake namespaces' do
      it 'registers offenses for top-level method definitions' do
        expect_offense(<<~RUBY, source_file)
          def top_level_method
          ^^^^^^^^^^^^^^^^^^^^ Methods defined in rake tasks share the same namespace and can cause collisions. Please define it in a bounded contexts module in a separate Ruby file. For example, Search::RakeTask::<Namespace>. See https://github.com/rubocop/rubocop-rake/issues/42
            'some logic'
          end

          namespace :gitlab do
            namespace :elastic do
              # No method/class/module definitions here
              task info: :environment do
                # Only task logic here
              end
            end
          end
        RUBY
      end
    end

    context 'with mixed method definitions' do
      it 'registers offenses for all method definitions and the module' do
        expect_offense(<<~RUBY, source_file)
          # Top-level method - also gets an offense
          def top_level_method
          ^^^^^^^^^^^^^^^^^^^^ Methods defined in rake tasks share the same namespace and can cause collisions. Please define it in a bounded contexts module in a separate Ruby file. For example, Search::RakeTask::<Namespace>. See https://github.com/rubocop/rubocop-rake/issues/42
            'top level'
          end

          # Inside a module - the module gets flagged, not the method
          module SomeModule
          ^^^^^^^^^^^^^^^^^ Modules should not be defined in rake files. Please define it in a separate Ruby file. For example, Search::RakeTask::<Namespace>. See https://github.com/rubocop/rubocop-rake/issues/42
            def module_method
            ^^^^^^^^^^^^^^^^^ Methods defined in rake tasks share the same namespace and can cause collisions. Please define it in a bounded contexts module in a separate Ruby file. For example, Search::RakeTask::<Namespace>. See https://github.com/rubocop/rubocop-rake/issues/42
              'in module'
            end
          end

          namespace :gitlab do
            # Method inside namespace - offense
            def inside_namespace_method
            ^^^^^^^^^^^^^^^^^^^^^^^^^^^ Methods defined in rake tasks share the same namespace and can cause collisions. Please define it in a bounded contexts module in a separate Ruby file. For example, Search::RakeTask::<Namespace>. See https://github.com/rubocop/rubocop-rake/issues/42
              'bad practice'
            end
          end
        RUBY
      end
    end
  end

  context 'in a non-rake file' do
    let(:source_file) { 'elastic.rb' }

    it 'does not register an offense for method definitions outside modules' do
      expect_no_offenses(<<~RUBY, source_file)
        def task_executor_service
          Search::RakeTaskExecutorService.new(logger: stdout_logger)
        end
      RUBY
    end

    it 'does not register an offense for method definitions inside blocks' do
      expect_no_offenses(<<~RUBY, source_file)
        something do
          def task_executor_service
            Search::RakeTaskExecutorService.new(logger: stdout_logger)
          end
        end
      RUBY
    end

    it 'does not register an offense for class and module definitions' do
      expect_no_offenses(<<~RUBY, source_file)
        module SomeNamespace
          class TaskHelper
            def self.task_executor_service
              Search::RakeTaskExecutorService.new(logger: stdout_logger)
            end
          end
        end
      RUBY
    end
  end
end
