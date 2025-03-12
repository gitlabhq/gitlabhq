# frozen_string_literal: true

require "strscan"
require "graphql/language/nodes"

module GraphQL
  module Language
    class Parser
      include GraphQL::Language::Nodes
      include EmptyObjects

      class << self
        attr_accessor :cache

        def parse(graphql_str, filename: nil, trace: Tracing::NullTrace, max_tokens: nil)
          self.new(graphql_str, filename: filename, trace: trace, max_tokens: max_tokens).parse
        end

        def parse_file(filename, trace: Tracing::NullTrace)
          if cache
            cache.fetch(filename) do
              parse(File.read(filename), filename: filename, trace: trace)
            end
          else
            parse(File.read(filename), filename: filename, trace: trace)
          end
        end
      end

      def initialize(graphql_str, filename: nil, trace: Tracing::NullTrace, max_tokens: nil)
        if graphql_str.nil?
          raise GraphQL::ParseError.new("No query string was present", nil, nil, nil)
        end
        @lexer = Lexer.new(graphql_str, filename: filename, max_tokens: max_tokens)
        @graphql_str = graphql_str
        @filename = filename
        @trace = trace
        @dedup_identifiers = false
        @lines_at = nil
      end

      def parse
        @document ||= begin
          @trace.parse(query_string: @graphql_str) do
            document
          end
        rescue SystemStackError
          raise GraphQL::ParseError.new("This query is too large to execute.", nil, nil, @query_str, filename: @filename)
        end
      end

      def tokens_count
        parse
        @lexer.tokens_count
      end

      def line_at(pos)
        line = lines_at.bsearch_index { |l| l >= pos }
        if line.nil?
          @lines_at.size + 1
        else
          line + 1
        end
      end

      def column_at(pos)
        next_line_idx = lines_at.bsearch_index { |l| l >= pos } || 0
        if next_line_idx > 0
          line_pos = @lines_at[next_line_idx - 1]
          pos - line_pos
        else
          pos + 1
        end
      end

      private

      # @return [Array<Integer>] Positions of each line break in the original string
      def lines_at
        @lines_at ||= begin
          la = []
          idx = 0
          while idx
            idx = @graphql_str.index("\n", idx)
            if idx
              la << idx
              idx += 1
            end
          end
          la
        end
      end

      attr_reader :token_name

      def advance_token
        @token_name = @lexer.advance
      end

      def pos
        @lexer.pos
      end

      def document
        any_tokens = advance_token
        defns = []
        if any_tokens
          defns << definition
        else
          # Only ignored characters is not a valid document
          raise GraphQL::ParseError.new("Unexpected end of document", nil, nil, @graphql_str)
        end
        while !@lexer.eos?
          defns << definition
        end
        Document.new(pos: 0, definitions: defns, filename: @filename, source: self)
      end

      def definition
        case token_name
        when :FRAGMENT
          loc = pos
          expect_token :FRAGMENT
          f_name = if !at?(:ON)
            parse_name
          end
          expect_token :ON
          f_type = parse_type_name
          directives = parse_directives
          selections = selection_set
          Nodes::FragmentDefinition.new(
            pos: loc,
            name: f_name,
            type: f_type,
            directives: directives,
            selections: selections,
            filename: @filename,
            source: self
          )
        when :QUERY, :MUTATION, :SUBSCRIPTION, :LCURLY
          op_loc = pos
          op_type = case token_name
          when :LCURLY
            "query"
          else
            parse_operation_type
          end

          op_name = case token_name
          when :LPAREN, :LCURLY, :DIR_SIGN
            nil
          else
            parse_name
          end

          variable_definitions = if at?(:LPAREN)
            expect_token(:LPAREN)
            defs = []
            while !at?(:RPAREN)
              loc = pos
              expect_token(:VAR_SIGN)
              var_name = parse_name
              expect_token(:COLON)
              var_type = self.type || raise_parse_error("Missing type definition for variable: $#{var_name}")
              default_value = if at?(:EQUALS)
                advance_token
                value
              end

              directives = parse_directives

              defs << Nodes::VariableDefinition.new(
                pos: loc,
                name: var_name,
                type: var_type,
                default_value: default_value,
                directives: directives,
                filename: @filename,
                source: self
              )
            end
            expect_token(:RPAREN)
            defs
          else
            EmptyObjects::EMPTY_ARRAY
          end

          directives = parse_directives

          OperationDefinition.new(
            pos: op_loc,
            operation_type: op_type,
            name: op_name,
            variables: variable_definitions,
            directives: directives,
            selections: selection_set,
            filename: @filename,
            source: self
          )
        when :EXTEND
          loc = pos
          advance_token
          case token_name
          when :SCALAR
            advance_token
            name = parse_name
            directives = parse_directives
            ScalarTypeExtension.new(pos: loc, name: name, directives: directives, filename: @filename, source: self)
          when :TYPE
            advance_token
            name = parse_name
            implements_interfaces = parse_implements
            directives = parse_directives
            field_defns = at?(:LCURLY) ? parse_field_definitions : EMPTY_ARRAY

            ObjectTypeExtension.new(pos: loc, name: name, interfaces: implements_interfaces, directives: directives, fields: field_defns, filename: @filename, source: self)
          when :INTERFACE
            advance_token
            name = parse_name
            directives = parse_directives
            interfaces = parse_implements
            fields_definition = at?(:LCURLY) ? parse_field_definitions : EMPTY_ARRAY
            InterfaceTypeExtension.new(pos: loc, name: name, directives: directives, fields: fields_definition, interfaces: interfaces, filename: @filename, source: self)
          when :UNION
            advance_token
            name = parse_name
            directives = parse_directives
            union_member_types = parse_union_members
            UnionTypeExtension.new(pos: loc, name: name, directives: directives, types: union_member_types, filename: @filename, source: self)
          when :ENUM
            advance_token
            name = parse_name
            directives = parse_directives
            enum_values_definition = parse_enum_value_definitions
            Nodes::EnumTypeExtension.new(pos: loc, name: name, directives: directives, values: enum_values_definition, filename: @filename, source: self)
          when :INPUT
            advance_token
            name = parse_name
            directives = parse_directives
            input_fields_definition = parse_input_object_field_definitions
            InputObjectTypeExtension.new(pos: loc, name: name, directives: directives, fields: input_fields_definition, filename: @filename, source: self)
          when :SCHEMA
            advance_token
            directives = parse_directives
            query = mutation = subscription = nil
            if at?(:LCURLY)
              advance_token
              while !at?(:RCURLY)
                if at?(:QUERY)
                  advance_token
                  expect_token(:COLON)
                  query = parse_name
                elsif at?(:MUTATION)
                  advance_token
                  expect_token(:COLON)
                  mutation = parse_name
                elsif at?(:SUBSCRIPTION)
                  advance_token
                  expect_token(:COLON)
                  subscription = parse_name
                else
                  expect_one_of([:QUERY, :MUTATION, :SUBSCRIPTION])
                end
              end
              expect_token :RCURLY
            end
            SchemaExtension.new(
              subscription: subscription,
              mutation: mutation,
              query: query,
              directives: directives,
              pos: loc,
              filename: @filename,
              source: self,
            )
          else
            expect_one_of([:SCHEMA, :SCALAR, :TYPE, :ENUM, :INPUT, :UNION, :INTERFACE])
          end
        else
          loc = pos
          desc = at?(:STRING) ? string_value : nil
          defn_loc = pos
          case token_name
          when :SCHEMA
            advance_token
            directives = parse_directives
            query = mutation = subscription = nil
            expect_token :LCURLY
            while !at?(:RCURLY)
              if at?(:QUERY)
                advance_token
                expect_token(:COLON)
                query = parse_name
              elsif at?(:MUTATION)
                advance_token
                expect_token(:COLON)
                mutation = parse_name
              elsif at?(:SUBSCRIPTION)
                advance_token
                expect_token(:COLON)
                subscription = parse_name
              else
                expect_one_of([:QUERY, :MUTATION, :SUBSCRIPTION])
              end
            end
            expect_token :RCURLY
            SchemaDefinition.new(pos: loc, definition_pos: defn_loc, query: query, mutation: mutation, subscription: subscription, directives: directives, filename: @filename, source: self)
          when :DIRECTIVE
            advance_token
            expect_token :DIR_SIGN
            name = parse_name
            arguments_definition = parse_argument_definitions
            repeatable = if at?(:REPEATABLE)
              advance_token
              true
            else
              false
            end
            expect_token :ON
            directive_locations = [DirectiveLocation.new(pos: pos, name: parse_name, filename: @filename, source: self)]
            while at?(:PIPE)
              advance_token
              directive_locations << DirectiveLocation.new(pos: pos, name: parse_name, filename: @filename, source: self)
            end
            DirectiveDefinition.new(pos: loc, definition_pos: defn_loc, description: desc, name: name, arguments: arguments_definition, locations: directive_locations, repeatable: repeatable, filename: @filename, source: self)
          when :TYPE
            advance_token
            name = parse_name
            implements_interfaces = parse_implements
            directives = parse_directives
            field_defns = at?(:LCURLY) ? parse_field_definitions : EMPTY_ARRAY

            ObjectTypeDefinition.new(pos: loc, definition_pos: defn_loc, description: desc, name: name, interfaces: implements_interfaces, directives: directives, fields: field_defns, filename: @filename, source: self)
          when :INTERFACE
            advance_token
            name = parse_name
            interfaces = parse_implements
            directives = parse_directives
            fields_definition = parse_field_definitions
            InterfaceTypeDefinition.new(pos: loc, definition_pos: defn_loc, description: desc, name: name, directives: directives, fields: fields_definition, interfaces: interfaces, filename: @filename, source: self)
          when :UNION
            advance_token
            name = parse_name
            directives = parse_directives
            union_member_types = parse_union_members
            UnionTypeDefinition.new(pos: loc, definition_pos: defn_loc, description: desc, name: name, directives: directives, types: union_member_types, filename: @filename, source: self)
          when :SCALAR
            advance_token
            name = parse_name
            directives = parse_directives
            ScalarTypeDefinition.new(pos: loc, definition_pos: defn_loc, description: desc, name: name, directives: directives, filename: @filename, source: self)
          when :ENUM
            advance_token
            name = parse_name
            directives = parse_directives
            enum_values_definition = parse_enum_value_definitions
            Nodes::EnumTypeDefinition.new(pos: loc, definition_pos: defn_loc, description: desc, name: name, directives: directives, values: enum_values_definition, filename: @filename, source: self)
          when :INPUT
            advance_token
            name = parse_name
            directives = parse_directives
            input_fields_definition = parse_input_object_field_definitions
            InputObjectTypeDefinition.new(pos: loc, definition_pos: defn_loc, description: desc, name: name, directives: directives, fields: input_fields_definition, filename: @filename, source: self)
          else
            expect_one_of([:SCHEMA, :SCALAR, :TYPE, :ENUM, :INPUT, :UNION, :INTERFACE])
          end
        end
      end

      def parse_input_object_field_definitions
        if at?(:LCURLY)
          expect_token :LCURLY
          list = []
          while !at?(:RCURLY)
            list << parse_input_value_definition
          end
          expect_token :RCURLY
          list
        else
          EMPTY_ARRAY
        end
      end

      def parse_enum_value_definitions
        if at?(:LCURLY)
          expect_token :LCURLY
          list = []
          while !at?(:RCURLY)
            v_loc = pos
            description = if at?(:STRING); string_value; end
            defn_loc = pos
            # Any identifier, but not true, false, or null
            enum_value = if at?(:TRUE) || at?(:FALSE) || at?(:NULL)
              expect_token(:IDENTIFIER)
            else
              parse_name
            end
            v_directives = parse_directives
            list << EnumValueDefinition.new(pos: v_loc, definition_pos: defn_loc, description: description, name: enum_value, directives: v_directives, filename: @filename, source: self)
          end
          expect_token :RCURLY
          list
        else
          EMPTY_ARRAY
        end
      end

      def parse_union_members
        if at?(:EQUALS)
          expect_token :EQUALS
          if at?(:PIPE)
            advance_token
          end
          list = [parse_type_name]
          while at?(:PIPE)
            advance_token
            list << parse_type_name
          end
          list
        else
          EMPTY_ARRAY
        end
      end

      def parse_implements
        if at?(:IMPLEMENTS)
          advance_token
          list = []
          while true
            advance_token if at?(:AMP)
            break unless at?(:IDENTIFIER)
            list << parse_type_name
          end
          list
        else
          EMPTY_ARRAY
        end
      end

      def parse_field_definitions
        expect_token :LCURLY
        list = []
        while !at?(:RCURLY)
          loc = pos
          description = if at?(:STRING); string_value; end
          defn_loc = pos
          name = parse_name
          arguments_definition = parse_argument_definitions
          expect_token :COLON
          type = self.type
          directives = parse_directives

          list << FieldDefinition.new(pos: loc, definition_pos: defn_loc, description: description, name: name, arguments: arguments_definition, type: type, directives: directives, filename: @filename, source: self)
        end
        expect_token :RCURLY
        list
      end

      def parse_argument_definitions
        if at?(:LPAREN)
          advance_token
          list = []
          while !at?(:RPAREN)
            list << parse_input_value_definition
          end
          expect_token :RPAREN
          list
        else
          EMPTY_ARRAY
        end
      end

      def parse_input_value_definition
        loc = pos
        description = if at?(:STRING); string_value; end
        defn_loc = pos
        name = parse_name
        expect_token :COLON
        type = self.type
        default_value = if at?(:EQUALS)
          advance_token
          value
        else
          nil
        end
        directives = parse_directives
        InputValueDefinition.new(pos: loc, definition_pos: defn_loc, description: description, name: name, type: type, default_value: default_value, directives: directives, filename: @filename, source: self)
      end

      def type
        type = case token_name
        when :IDENTIFIER
          parse_type_name
        when :LBRACKET
          list_type
        end

        if at?(:BANG)
          type = Nodes::NonNullType.new(pos: pos, of_type: type, source: self)
          expect_token(:BANG)
        end
        type
      end

      def list_type
        loc = pos
        expect_token(:LBRACKET)
        type = Nodes::ListType.new(pos: loc, of_type: self.type, source: self)
        expect_token(:RBRACKET)
        type
      end

      def parse_operation_type
        val = if at?(:QUERY)
          "query"
        elsif at?(:MUTATION)
          "mutation"
        elsif at?(:SUBSCRIPTION)
          "subscription"
        else
          expect_one_of([:QUERY, :MUTATION, :SUBSCRIPTION])
        end
        advance_token
        val
      end

      def selection_set
        expect_token(:LCURLY)
        selections = []
        while @token_name != :RCURLY
          selections << if at?(:ELLIPSIS)
            loc = pos
            advance_token
            case token_name
            when :ON, :DIR_SIGN, :LCURLY
              if_type = if at?(:ON)
                advance_token
                parse_type_name
              else
                nil
              end

              directives = parse_directives

              Nodes::InlineFragment.new(pos: loc, type: if_type, directives: directives, selections: selection_set, filename: @filename, source: self)
            else
              name = parse_name_without_on
              directives = parse_directives

              # Can this ever happen?
              # expect_token(:IDENTIFIER) if at?(:ON)

              FragmentSpread.new(pos: loc, name: name, directives: directives, filename: @filename, source: self)
            end
          else
            loc = pos
            name = parse_name

            field_alias = nil

            if at?(:COLON)
              advance_token
              field_alias = name
              name = parse_name
            end

            arguments = at?(:LPAREN) ? parse_arguments : nil
            directives = at?(:DIR_SIGN) ? parse_directives : nil
            selection_set = at?(:LCURLY) ? self.selection_set : nil

            Nodes::Field.new(pos: loc, field_alias: field_alias, name: name, arguments: arguments, directives: directives, selections: selection_set, filename: @filename, source: self)
          end
        end
        expect_token(:RCURLY)
        selections
      end

      def parse_name
        case token_name
        when :IDENTIFIER
          expect_token_value(:IDENTIFIER)
        when :SCHEMA
          advance_token
          "schema"
        when :SCALAR
          advance_token
          "scalar"
        when :IMPLEMENTS
          advance_token
          "implements"
        when :INTERFACE
          advance_token
          "interface"
        when :UNION
          advance_token
          "union"
        when :ENUM
          advance_token
          "enum"
        when :INPUT
          advance_token
          "input"
        when :DIRECTIVE
          advance_token
          "directive"
        when :TYPE
          advance_token
          "type"
        when :QUERY
          advance_token
          "query"
        when :MUTATION
          advance_token
          "mutation"
        when :SUBSCRIPTION
          advance_token
          "subscription"
        when :TRUE
          advance_token
          "true"
        when :FALSE
          advance_token
          "false"
        when :FRAGMENT
          advance_token
          "fragment"
        when :REPEATABLE
          advance_token
          "repeatable"
        when :NULL
          advance_token
          "null"
        when :ON
          advance_token
          "on"
        when :EXTEND
          advance_token
          "extend"
        else
          expect_token(:NAME)
        end
      end

      def parse_name_without_on
        if at?(:ON)
          expect_token(:IDENTIFIER)
        else
          parse_name
        end
      end

      def parse_type_name
        TypeName.new(pos: pos, name: parse_name, filename: @filename, source: self)
      end

      def parse_directives
        if at?(:DIR_SIGN)
          dirs = []
          while at?(:DIR_SIGN)
            loc = pos
            advance_token
            name = parse_name
            arguments = parse_arguments

            dirs << Nodes::Directive.new(pos: loc, name: name, arguments: arguments, filename: @filename, source: self)
          end
          dirs
        else
          EMPTY_ARRAY
        end
      end

      def parse_arguments
        if at?(:LPAREN)
          advance_token
          args = []
          while !at?(:RPAREN)
            loc = pos
            name = parse_name
            expect_token(:COLON)
            args << Nodes::Argument.new(pos: loc, name: name, value: value, filename: @filename, source: self)
          end
          if args.empty?
            expect_token(:ARGUMENT_NAME) # At least one argument is required
          end
          expect_token(:RPAREN)
          args
        else
          EMPTY_ARRAY
        end
      end

      def string_value
        token_value = @lexer.string_value
        expect_token :STRING
        token_value
      end

      def value
        case token_name
        when :INT
          expect_token_value(:INT).to_i
        when :FLOAT
          expect_token_value(:FLOAT).to_f
        when :STRING
          string_value
        when :TRUE
          advance_token
          true
        when :FALSE
          advance_token
          false
        when :NULL
          advance_token
          NullValue.new(pos: pos, name: "null", filename: @filename, source: self)
        when :IDENTIFIER
          Nodes::Enum.new(pos: pos, name: expect_token_value(:IDENTIFIER), filename: @filename, source: self)
        when :LBRACKET
          advance_token
          list = []
          while !at?(:RBRACKET)
            list << value
          end
          expect_token(:RBRACKET)
          list
        when :LCURLY
          start = pos
          advance_token
          args = []
          while !at?(:RCURLY)
            loc = pos
            n = parse_name
            expect_token(:COLON)
            args << Argument.new(pos: loc, name: n, value: value, filename: @filename, source: self)
          end
          expect_token(:RCURLY)
          InputObject.new(pos: start, arguments: args, filename: @filename, source: self)
        when :VAR_SIGN
          loc = pos
          advance_token
          VariableIdentifier.new(pos: loc, name: parse_name, filename: @filename, source: self)
        when :SCHEMA
          advance_token
          Nodes::Enum.new(pos: pos, name: "schema", filename: @filename, source: self)
        when :SCALAR
          advance_token
          Nodes::Enum.new(pos: pos, name: "scalar", filename: @filename, source: self)
        when :IMPLEMENTS
          advance_token
          Nodes::Enum.new(pos: pos, name: "implements", filename: @filename, source: self)
        when :INTERFACE
          advance_token
          Nodes::Enum.new(pos: pos, name: "interface", filename: @filename, source: self)
        when :UNION
          advance_token
          Nodes::Enum.new(pos: pos, name: "union", filename: @filename, source: self)
        when :ENUM
          advance_token
          Nodes::Enum.new(pos: pos, name: "enum", filename: @filename, source: self)
        when :INPUT
          advance_token
          Nodes::Enum.new(pos: pos, name: "input", filename: @filename, source: self)
        when :DIRECTIVE
          advance_token
          Nodes::Enum.new(pos: pos, name: "directive", filename: @filename, source: self)
        when :TYPE
          advance_token
          Nodes::Enum.new(pos: pos, name: "type", filename: @filename, source: self)
        when :QUERY
          advance_token
          Nodes::Enum.new(pos: pos, name: "query", filename: @filename, source: self)
        when :MUTATION
          advance_token
          Nodes::Enum.new(pos: pos, name: "mutation", filename: @filename, source: self)
        when :SUBSCRIPTION
          advance_token
          Nodes::Enum.new(pos: pos, name: "subscription", filename: @filename, source: self)
        when :FRAGMENT
          advance_token
          Nodes::Enum.new(pos: pos, name: "fragment", filename: @filename, source: self)
        when :REPEATABLE
          advance_token
          Nodes::Enum.new(pos: pos, name: "repeatable", filename: @filename, source: self)
        when :ON
          advance_token
          Nodes::Enum.new(pos: pos, name: "on", filename: @filename, source: self)
        when :EXTEND
          advance_token
          Nodes::Enum.new(pos: pos, name: "extend", filename: @filename, source: self)
        else
          expect_token(:VALUE)
        end
      end

      def at?(expected_token_name)
        @token_name == expected_token_name
      end

      def expect_token(expected_token_name)
        unless @token_name == expected_token_name
          raise_parse_error("Expected #{expected_token_name}, actual: #{token_name || "(none)"} (#{debug_token_value.inspect})")
        end
        advance_token
      end

      def expect_one_of(token_names)
        raise_parse_error("Expected one of #{token_names.join(", ")}, actual: #{token_name || "NOTHING"} (#{debug_token_value.inspect})")
      end

      def raise_parse_error(message)
        message += " at [#{@lexer.line_number}, #{@lexer.column_number}]"
        raise GraphQL::ParseError.new(
          message,
          @lexer.line_number,
          @lexer.column_number,
          @graphql_str,
          filename: @filename,
        )

      end

      # Only use when we care about the expected token's value
      def expect_token_value(tok)
        token_value = @lexer.token_value
        if @dedup_identifiers
          token_value = -token_value
        end
        expect_token(tok)
        token_value
      end

      # token_value works for when the scanner matched something
      # which is usually fine and it's good for it to be fast at that.
      def debug_token_value
        @lexer.debug_token_value(token_name)
      end
      class SchemaParser < Parser
        def initialize(*args, **kwargs)
          super
          @dedup_identifiers = true
        end
      end
    end
  end
end
