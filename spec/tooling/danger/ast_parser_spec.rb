# frozen_string_literal: true

require 'fast_spec_helper'
require_relative '../../../tooling/danger/ast_parser'

RSpec.describe Tooling::Danger::AstParser, feature_category: :database do
  let(:parser) { described_class.new(file_content) }

  describe '#initialize' do
    let(:file_content) { 'class TestClass; end' }

    it 'initializes with file content and creates an AST' do
      expect(parser.ast).to be_a(RuboCop::AST::Node)
    end
  end

  describe '#extract_class_or_module_name' do
    context 'with a class in the BackgroundMigration module' do
      let(:file_content) do
        <<~RUBY
          module Gitlab
            module BackgroundMigration
              class TestMigration
                def perform
                end
              end
            end
          end
        RUBY
      end

      it 'extracts the class name after BackgroundMigration' do
        expect(parser.extract_class_or_module_name).to eq('TestMigration')
      end
    end

    context 'with a module in the BackgroundMigration module' do
      let(:file_content) do
        <<~RUBY
          module EE
            module Gitlab
              module BackgroundMigration
                module TestModule
                  class InnerClass
                  end
                end
              end
            end
          end
        RUBY
      end

      it 'extracts the module name after BackgroundMigration' do
        expect(parser.extract_class_or_module_name).to eq('TestModule')
      end
    end

    context 'without BackgroundMigration module' do
      let(:file_content) do
        <<~RUBY
          module Gitlab
            class SomeClass
            end
          end
        RUBY
      end

      it 'returns nil' do
        expect(parser.extract_class_or_module_name).to be_nil
      end
    end

    context 'with BackgroundMigration as the last module' do
      let(:file_content) do
        <<~RUBY
          module Gitlab
            module BackgroundMigration
            end
          end
        RUBY
      end

      it 'returns nil' do
        expect(parser.extract_class_or_module_name).to be_nil
      end
    end
  end

  describe '#has_ensure_batched_background_migration_is_finished_call?' do
    context 'when the method is called' do
      let(:file_content) do
        <<~RUBY
          class Migration
            def up
              ensure_batched_background_migration_is_finished(
                job_class_name: 'TestMigration',
                table_name: :users,
                column_name: :id
              )
            end
          end
        RUBY
      end

      it 'returns true' do
        expect(parser.has_ensure_batched_background_migration_is_finished_call?).to be true
      end
    end

    context 'when the method is not called' do
      let(:file_content) do
        <<~RUBY
          class Migration
            def up
              some_other_method
            end
          end
        RUBY
      end

      it 'returns false' do
        expect(parser.has_ensure_batched_background_migration_is_finished_call?).to be false
      end
    end
  end

  describe '#contains_class_name_assignment?' do
    context 'with constant assignment' do
      let(:file_content) do
        <<~RUBY
          class Migration
            MIGRATION = 'TestMigration'
          end
        RUBY
      end

      it 'returns true when the class name matches' do
        expect(parser.contains_class_name_assignment?('TestMigration')).to be true
      end

      it 'returns false when the class name does not match' do
        expect(parser.contains_class_name_assignment?('OtherMigration')).to be false
      end
    end

    context 'with job_class_name argument' do
      let(:file_content) do
        <<~RUBY
          class Migration
            def up
              ensure_batched_background_migration_is_finished(
                job_class_name: 'TestMigration',
                table_name: :users,
                column_name: :id
              )
            end
          end
        RUBY
      end

      it 'returns true when the class name matches' do
        expect(parser.contains_class_name_assignment?('TestMigration')).to be true
      end

      it 'returns false when the class name does not match' do
        expect(parser.contains_class_name_assignment?('OtherMigration')).to be false
      end
    end

    context 'with neither constant assignment nor job_class_name argument is present' do
      let(:file_content) do
        <<~RUBY
          class Migration
            def up
              some_other_method
            end
          end
        RUBY
      end

      it 'returns false' do
        expect(parser.contains_class_name_assignment?('TestMigration')).to be false
      end
    end
  end

  describe '#extract_milestone' do
    context 'with milestone declaration' do
      let(:file_content) do
        <<~RUBY
          class Migration < Gitlab::Database::Migration[2.1]
            milestone '17.2'

            def up
              # Migration code
            end
          end
        RUBY
      end

      it 'extracts the milestone version' do
        expect(parser.extract_milestone).to eq('17.2')
      end
    end

    context 'with double-quoted milestone declaration' do
      let(:file_content) do
        <<~RUBY
          class Migration < Gitlab::Database::Migration[2.1]
            milestone "17.2"

            def up
              # Migration code
            end
          end
        RUBY
      end

      it 'extracts the milestone version' do
        expect(parser.extract_milestone).to eq('17.2')
      end
    end

    context 'with parenthesized milestone declaration' do
      let(:file_content) do
        <<~RUBY
          class Migration < Gitlab::Database::Migration[2.1]
            milestone('17.2')

            def up
              # Migration code
            end
          end
        RUBY
      end

      it 'returns nil' do
        expect(parser.extract_milestone).to be_nil
      end
    end

    context 'without milestone declaration' do
      let(:file_content) do
        <<~RUBY
          class Migration < Gitlab::Database::Migration[2.1]
            def up
              # Migration code
            end
          end
        RUBY
      end

      it 'returns nil' do
        expect(parser.extract_milestone).to be_nil
      end
    end
  end

  describe '#find_method_call' do
    context 'when the method is called' do
      let(:file_content) do
        <<~RUBY
          class TestClass
            def test_method
              some_method
            end
          end
        RUBY
      end

      it 'returns true' do
        expect(parser.send(:find_method_call, :some_method)).to be true
      end
    end

    context 'when the method is not called' do
      let(:file_content) do
        <<~RUBY
          class TestClass
            def test_method
              other_method
            end
          end
        RUBY
      end

      it 'returns false' do
        expect(parser.send(:find_method_call, :some_method)).to be false
      end
    end
  end

  describe '#has_constant_assignment?' do
    context 'with matching string assignment' do
      let(:file_content) do
        <<~RUBY
          class TestClass
            CONSTANT = 'TestValue'
          end
        RUBY
      end

      it 'returns true' do
        expect(parser.send(:has_constant_assignment?, 'TestValue')).to be true
      end
    end

    context 'with non-matching string assignment' do
      let(:file_content) do
        <<~RUBY
          class TestClass
            CONSTANT = 'OtherValue'
          end
        RUBY
      end

      it 'returns false' do
        expect(parser.send(:has_constant_assignment?, 'TestValue')).to be false
      end
    end

    context 'with non-string assignment' do
      let(:file_content) do
        <<~RUBY
          class TestClass
            CONSTANT = 123
          end
        RUBY
      end

      it 'returns false' do
        expect(parser.send(:has_constant_assignment?, 'TestValue')).to be false
      end
    end
  end

  describe '#has_job_class_name_argument?' do
    context 'with matching job_class_name argument' do
      let(:file_content) do
        <<~RUBY
          class TestClass
            def test_method
              some_method(job_class_name: 'TestMigration')
            end
          end
        RUBY
      end

      it 'returns true' do
        expect(parser.send(:has_job_class_name_argument?, 'TestMigration')).to be true
      end
    end

    context 'with non-matching job_class_name argument' do
      let(:file_content) do
        <<~RUBY
          class TestClass
            def test_method
              some_method(job_class_name: 'OtherMigration')
            end
          end
        RUBY
      end

      it 'returns false' do
        expect(parser.send(:has_job_class_name_argument?, 'TestMigration')).to be false
      end
    end

    context 'without job_class_name argument' do
      let(:file_content) do
        <<~RUBY
          class TestClass
            def test_method
              some_method(other_param: 'value')
            end
          end
        RUBY
      end

      it 'returns false' do
        expect(parser.send(:has_job_class_name_argument?, 'TestMigration')).to be false
      end
    end

    context 'with job_class_name argument that is not a string' do
      let(:file_content) do
        <<~RUBY
          class TestClass
            def test_method
              some_method(job_class_name: variable)
            end
          end
        RUBY
      end

      it 'returns false' do
        expect(parser.send(:has_job_class_name_argument?, 'TestMigration')).to be false
      end
    end
  end
end
