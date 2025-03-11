# frozen_string_literal: true
require_relative "./base_cop"

module GraphQL
  module Rubocop
    module GraphQL
      # Identify (and auto-correct) any field whose type configuration isn't given
      # in the configuration block.
      #
      # @example
      #   # bad, immediately causes Rails to load `app/graphql/types/thing.rb`
      #   field :thing, Types::Thing
      #
      #   # good, defers loading until the file is needed
      #   field :thing do
      #     type(Types::Thing)
      #   end
      #
      class FieldTypeInBlock < BaseCop
        MSG = "type configuration can be moved to a block to defer loading the type's file"

        BUILT_IN_SCALAR_NAMES = ["Float", "Int", "Integer", "String", "ID", "Boolean"]
        def_node_matcher :field_config_with_inline_type, <<-Pattern
        (
          send {nil? _} :field sym ${const array} ...
        )
        Pattern

        def_node_matcher :field_config_with_inline_type_and_block, <<-Pattern
        (
          block
            (send {nil? _} :field sym ${const array} ...) ...
            (args)
            _

        )
        Pattern

        def on_block(node)
          ignore_node(node)
          field_config_with_inline_type_and_block(node) do |type_const|
            type_const_str = get_type_argument_str(node, type_const)
            if ignore_inline_type_str?(type_const_str)
              # Do nothing ...
            else
              add_offense(type_const) do |corrector|
                cleaned_node_source = delete_type_argument(node, type_const)
                field_indent = determine_field_indent(node)
                cleaned_node_source.sub!(/(\{|do)/, "\\1\n#{field_indent}  type #{type_const_str}")
                corrector.replace(node, cleaned_node_source)
              end
            end
          end
        end

        def on_send(node)
          return if part_of_ignored_node?(node)
          field_config_with_inline_type(node) do |type_const|
            type_const_str = get_type_argument_str(node, type_const)
            if ignore_inline_type_str?(type_const_str)
              # Do nothing -- not loading from another file
            else
              add_offense(type_const) do |corrector|
                cleaned_node_source = delete_type_argument(node, type_const)
                field_indent = determine_field_indent(node)
                cleaned_node_source += " do\n#{field_indent}  type #{type_const_str}\n#{field_indent}end"
                corrector.replace(node, cleaned_node_source)
              end
            end
          end
        end


        private

        def ignore_inline_type_str?(type_str)
          if BUILT_IN_SCALAR_NAMES.include?(type_str)
            true
          elsif (inner_type_str = type_str.sub(/\[([A-Za-z]+)(, null: (true|false))?\]/, '\1')) && BUILT_IN_SCALAR_NAMES.include?(inner_type_str)
            true
          else
            false
          end
        end

        def get_type_argument_str(send_node, type_const)
          first_pos = type_const.location.expression.begin_pos
          end_pos = type_const.location.expression.end_pos
          node_source = send_node.source_range.source
          node_first_pos = send_node.location.expression.begin_pos

          relative_first_pos = first_pos - node_first_pos
          end_removal_pos = end_pos - node_first_pos

          node_source[relative_first_pos...end_removal_pos]
        end

        def delete_type_argument(send_node, type_const)
          first_pos = type_const.location.expression.begin_pos
          end_pos = type_const.location.expression.end_pos
          node_source = send_node.source_range.source
          node_first_pos = send_node.location.expression.begin_pos

          relative_first_pos = first_pos - node_first_pos
          end_removal_pos = end_pos - node_first_pos

          begin_removal_pos = relative_first_pos
          while node_source[begin_removal_pos] != ","
            begin_removal_pos -= 1
            if begin_removal_pos < 1
              raise "Invariant: somehow backtracked to beginning of node looking for a comma (node source: #{node_source.inspect})"
            end
          end

          node_source[0...begin_removal_pos] + node_source[end_removal_pos..-1]
        end

        def determine_field_indent(send_node)
          type_defn_node = send_node

          while (type_defn_node && !(type_defn_node.class_definition? || type_defn_node.module_definition?))
            type_defn_node = type_defn_node.parent
          end

          if type_defn_node.nil?
            raise "Invariant: Something went wrong in GraphQL-Ruby, couldn't find surrounding class definition for field (#{send_node}).\n\nPlease report this error on GitHub."
          end

          type_defn_source = type_defn_node.source
          indent_test_idx = send_node.location.expression.begin_pos - type_defn_node.source_range.begin_pos - 1
          field_indent = "".dup
          while type_defn_source[indent_test_idx] == " "
            field_indent << " "
            indent_test_idx -= 1
            if indent_test_idx == 0
              raise "Invariant: somehow backtracted to beginning of class when looking for field indent (source: #{node_source.inspect})"
            end
          end
          field_indent
        end
      end
    end
  end
end
