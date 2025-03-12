# frozen_string_literal: true
module GraphQL
  class Backtrace
    # A class for turning a context into a human-readable table or array
    class Table
      MIN_COL_WIDTH = 4
      MAX_COL_WIDTH = 100
      HEADERS = [
        "Loc",
        "Field",
        "Object",
        "Arguments",
        "Result",
      ]

      def initialize(context, value:)
        @context = context
        @override_value = value
      end

      # @return [String] A table layout of backtrace with metadata
      def to_table
        @to_table ||= render_table(rows)
      end

      # @return [Array<String>] An array of position + field name entries
      def to_backtrace
        @to_backtrace ||= begin
          backtrace = rows.map { |r| "#{r[0]}: #{r[1]}" }
          # skip the header entry
          backtrace.shift
          backtrace
        end
      end

      private

      def rows
        @rows ||= begin
          query = @context.query
          query_ctx = @context
          runtime_inst = query_ctx.namespace(:interpreter_runtime)[:runtime]
          result = runtime_inst.instance_variable_get(:@response)
          rows = []
          result_path = []
          last_part = nil
          path = @context.current_path
          path.each do |path_part|
            value = value_at(runtime_inst, result_path)

            if result_path.empty?
              name = query.selected_operation.operation_type || "query"
              if (n = query.selected_operation_name)
                name += " #{n}"
              end
              args = query.variables
            else
              name = result.graphql_field.path
              args = result.graphql_arguments
            end

            object = result.graphql_parent ? result.graphql_parent.graphql_application_value : result.graphql_application_value
            object = object.object.inspect

            rows << [
              result.ast_node.position.join(":"),
              name,
              "#{object}",
              args.to_h.inspect,
              inspect_result(value),
            ]

            result_path << path_part
            if path_part == path.last
              last_part = path_part
            else
              result = result[path_part]
            end
          end


          object = result.graphql_application_value.object.inspect
          ast_node = result.graphql_selections.find { |s| s.alias == last_part || s.name == last_part }
          field_defn = query.get_field(result.graphql_result_type, ast_node.name)
          args = query.arguments_for(ast_node, field_defn).to_h
          field_path = field_defn.path
          if ast_node.alias
            field_path += " as #{ast_node.alias}"
          end

          rows << [
            ast_node.position.join(":"),
            field_path,
            "#{object}",
            args.inspect,
            inspect_result(@override_value)
          ]

          rows << HEADERS
          rows.reverse!
          rows
        end
      end

      # @return [String]
      def render_table(rows)
        max = Array.new(HEADERS.length, MIN_COL_WIDTH)

        rows.each do |row|
          row.each_with_index do |col, idx|
            col_len = col.length
            max_len = max[idx]
            if col_len > max_len
              if col_len > MAX_COL_WIDTH
                max[idx] = MAX_COL_WIDTH
              else
                max[idx] = col_len
              end
            end
          end
        end

        table = "".dup
        last_col_idx = max.length - 1
        rows.each do |row|
          table << row.map.each_with_index do |col, idx|
            max_len = max[idx]
            if idx < last_col_idx
              col = col.ljust(max_len)
            end
            if col.length > max_len
              col = col[0, max_len - 3] + "..."
            end
            col
          end.join(" | ")
          table << "\n"
        end
        table
      end


      def value_at(runtime, path)
        response = runtime.final_result
        path.each do |key|
          response && (response = response[key])
        end
        response
      end

      def inspect_result(obj)
        case obj
        when Hash
          "{" +
            obj.map do |key, val|
              "#{key}: #{inspect_truncated(val)}"
            end.join(", ") +
            "}"
        when Array
          "[" +
            obj.map { |v| inspect_truncated(v) }.join(", ") +
            "]"
        else
          inspect_truncated(obj)
        end
      end

      def inspect_truncated(obj)
        case obj
        when Hash
          "{...}"
        when Array
          "[...]"
        when GraphQL::Execution::Lazy
          "(unresolved)"
        else
          "#{obj.inspect}"
        end
      end
    end
  end
end
