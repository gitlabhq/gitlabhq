# frozen_string_literal: true

require 'rubocop'

# Wrapper around RuboCop AST parser providing a simplified interface
# for parsing batched background migration code in Danger plugins

module Tooling
  module Danger
    class AstParser
      BACKGROUND_MIGRATION_MODULE = 'BackgroundMigration'
      JOB_CLASS_NAME_KEY = :job_class_name

      attr_reader :ast

      def initialize(file_content)
        @ast = RuboCop::AST::ProcessedSource.new(file_content, RUBY_VERSION.to_f).ast
      end

      # Extracts both class and module name after the BackgroundMigration module
      # ex: Gitlab => BackgroundMigration => ClassName
      # ex: EE => Gitlab => BackgroundMigration => ModuleName
      def extract_class_or_module_name
        namespace_names = collect_module_and_class_names

        # Find the module/class that comes after BackgroundMigration
        bg_index = namespace_names.index(BACKGROUND_MIGRATION_MODULE)
        return unless bg_index && bg_index < namespace_names.length - 1

        namespace_names[bg_index + 1]
      end

      # Checks if the code contains a call to ensure_batched_background_migration_is_finished
      def has_ensure_batched_background_migration_is_finished_call?
        find_method_call(:ensure_batched_background_migration_is_finished)
      end

      # Checks if the code contains any assignment or reference to a specific class name
      # Looks for patterns like:
      # MIGRATION = 'ClassName'
      # method(job_class_name: 'ClassName')
      def contains_class_name_assignment?(class_name)
        has_constant_assignment?(class_name) || has_job_class_name_argument?(class_name)
      end

      # Extracts milestone info
      # Looking for milestone '15.0' / milestone "14.5"
      def extract_milestone
        node = ast.each_descendant(:send).find do |n|
          n.method_name == :milestone &&
            n.arguments.first&.type == :str &&
            !n.parenthesized?
        end
        node&.arguments&.first&.str_content
      end

      private

      # Collect all module and class names in the file
      def collect_module_and_class_names
        namespace_names = []
        ast.each_descendant(:module, :class) do |node|
          name_node = node.children.first
          namespace_names << name_node.const_name.to_s if name_node&.type == :const
        end
        namespace_names
      end

      # Find if a specific method is called anywhere in the file
      def find_method_call(method_name)
        ast.each_descendant(:send).any? { |node| node.method_name == method_name }
      end

      # Check if a constant is assigned the specified string value
      # ex. MIGRATION = 'ClassName'
      def has_constant_assignment?(string_value)
        ast.each_descendant(:casgn).any? do |node|
          value_node = node.children[2]
          value_node&.type == :str && value_node.str_content == string_value
        end
      end

      # Check if a method is called with job_class_name: 'ClassName' argument
      def has_job_class_name_argument?(class_name)
        ast.each_descendant(:send).any? do |node|
          node.arguments.any? do |arg|
            next false unless arg.type == :hash

            arg.pairs.any? do |pair|
              key_node, value_node = pair.children
              key_node.type == :sym &&
                key_node.value == JOB_CLASS_NAME_KEY &&
                value_node.type == :str &&
                value_node.str_content == class_name
            end
          end
        end
      end
    end
  end
end
