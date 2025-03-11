# frozen_string_literal: true

module GraphQL
  # A combination of query string and {Schema} instance which can be reduced to a {#result}.
  class Query
    extend Autoload
    include Tracing::Traceable
    extend Forwardable

    autoload :Context, "graphql/query/context"
    autoload :Fingerprint, "graphql/query/fingerprint"
    autoload :NullContext, "graphql/query/null_context"
    autoload :Result, "graphql/query/result"
    autoload :Variables, "graphql/query/variables"
    autoload :InputValidationResult, "graphql/query/input_validation_result"
    autoload :VariableValidationError, "graphql/query/variable_validation_error"
    autoload :ValidationPipeline, "graphql/query/validation_pipeline"

    class OperationNameMissingError < GraphQL::ExecutionError
      def initialize(name)
        msg = if name.nil?
          %|An operation name is required|
        else
          %|No operation named "#{name}"|
        end
        super(msg)
      end
    end

    attr_reader :schema, :context, :provided_variables

    # The value for root types
    attr_accessor :root_value

    # @return [nil, String] The operation name provided by client or the one inferred from the document. Used to determine which operation to run.
    attr_accessor :operation_name

    # @return [Boolean] if false, static validation is skipped (execution behavior for invalid queries is undefined)
    attr_reader :validate

    # @param new_validate [Boolean] if false, static validation is skipped. This can't be reasssigned after validation.
    def validate=(new_validate)
      if defined?(@validation_pipeline) && @validation_pipeline && @validation_pipeline.has_validated?
        raise ArgumentError, "Can't reassign Query#validate= after validation has run, remove this assignment."
      else
        @validate = new_validate
      end
    end

    # @return [GraphQL::StaticValidation::Validator] if present, the query will validate with these rules.
    attr_reader :static_validator

    # @param new_validate [GraphQL::StaticValidation::Validator] if present, the query will validate with these rules. This can't be reasssigned after validation.
    def static_validator=(new_validator)
      if defined?(@validation_pipeline) && @validation_pipeline && @validation_pipeline.has_validated?
        raise ArgumentError, "Can't reassign Query#static_validator= after validation has run, remove this assignment."
      elsif !new_validator.is_a?(GraphQL::StaticValidation::Validator)
        raise ArgumentError, "Expected a `GraphQL::StaticValidation::Validator` instance."
      else
        @static_validator = new_validator
      end
    end

    attr_writer :query_string

    # @return [GraphQL::Language::Nodes::Document]
    def document
      # It's ok if this hasn't been assigned yet
      if @query_string || @document
        with_prepared_ast { @document }
      else
        nil
      end
    end

    def inspect
      "query ..."
    end

    # @return [String, nil] The name of the operation to run (may be inferred)
    def selected_operation_name
      return nil unless selected_operation
      selected_operation.name
    end

    # @return [String, nil] the triggered event, if this query is a subscription update
    attr_reader :subscription_topic

    attr_reader :tracers

    # Prepare query `query_string` on `schema`
    # @param schema [GraphQL::Schema]
    # @param query_string [String]
    # @param context [#[]] an arbitrary hash of values which you can access in {GraphQL::Field#resolve}
    # @param variables [Hash] values for `$variables` in the query
    # @param operation_name [String] if the query string contains many operations, this is the one which should be executed
    # @param root_value [Object] the object used to resolve fields on the root type
    # @param max_depth [Numeric] the maximum number of nested selections allowed for this query (falls back to schema-level value)
    # @param max_complexity [Numeric] the maximum field complexity for this query (falls back to schema-level value)
    # @param visibility_profile [Symbol] Another way to assign `context[:visibility_profile]`
    def initialize(schema, query_string = nil, query: nil, document: nil, context: nil, variables: nil, validate: true, static_validator: nil, visibility_profile: nil, subscription_topic: nil, operation_name: nil, root_value: nil, max_depth: schema.max_depth, max_complexity: schema.max_complexity, warden: nil, use_visibility_profile: nil)
      # Even if `variables: nil` is passed, use an empty hash for simpler logic
      variables ||= {}
      @schema = schema
      @context = schema.context_class.new(query: self, values: context)
      if visibility_profile
        @context[:visibility_profile] ||= visibility_profile
      end

      if use_visibility_profile.nil?
        use_visibility_profile = warden ? false : schema.use_visibility_profile?
      end

      if use_visibility_profile
        @visibility_profile = @schema.visibility.profile_for(@context)
        @warden = Schema::Warden::NullWarden.new(context: @context, schema: @schema)
      else
        @visibility_profile = nil
        @warden = warden
      end

      @subscription_topic = subscription_topic
      @root_value = root_value
      @fragments = nil
      @operations = nil
      @validate = validate
      self.static_validator = static_validator if static_validator
      context_tracers = (context ? context.fetch(:tracers, []) : [])
      @tracers = schema.tracers + context_tracers

      if !context_tracers.empty? && !(schema.trace_class <= GraphQL::Tracing::CallLegacyTracers)
        raise ArgumentError, "context[:tracers] are not supported without `trace_with(GraphQL::Tracing::CallLegacyTracers)` in the schema configuration, please add it."
      end

      @analysis_errors = []
      if variables.is_a?(String)
        raise ArgumentError, "Query variables should be a Hash, not a String. Try JSON.parse to prepare variables."
      else
        @provided_variables = variables || {}
      end

      @query_string = query_string || query
      @document = document

      if @query_string && @document
        raise ArgumentError, "Query should only be provided a query string or a document, not both."
      end

      if @query_string && !@query_string.is_a?(String)
        raise ArgumentError, "Query string argument should be a String, got #{@query_string.class.name} instead."
      end

      # A two-layer cache of type resolution:
      # { abstract_type => { value => resolved_type } }
      @resolved_types_cache = Hash.new do |h1, k1|
        h1[k1] = Hash.new do |h2, k2|
          h2[k2] = @schema.resolve_type(k1, k2, @context)
        end
      end

      # Trying to execute a document
      # with no operations returns an empty hash
      @ast_variables = []
      @mutation = false
      @operation_name = operation_name
      @prepared_ast = false
      @validation_pipeline = nil
      @max_depth = max_depth
      @max_complexity = max_complexity

      @result_values = nil
      @executed = false

      @logger = if context && context[:logger] == false
        Logger.new(IO::NULL)
      elsif context && (l = context[:logger])
        l
      else
        schema.default_logger
      end
    end

    # If a document was provided to `GraphQL::Schema#execute` instead of the raw query string, we will need to get it from the document
    def query_string
      @query_string ||= (document ? document.to_query_string : nil)
    end

    # @return [Symbol, nil]
    attr_reader :visibility_profile

    attr_accessor :multiplex

    # @return [GraphQL::Tracing::Trace]
    def current_trace
      @current_trace ||= context[:trace] || (multiplex ? multiplex.current_trace : schema.new_trace(multiplex: multiplex, query: self))
    end

    def subscription_update?
      @subscription_topic && subscription?
    end

    # A lookahead for the root selections of this query
    # @return [GraphQL::Execution::Lookahead]
    def lookahead
      @lookahead ||= begin
        ast_node = selected_operation
        if ast_node.nil?
          GraphQL::Execution::Lookahead::NULL_LOOKAHEAD
        else
          root_type = case ast_node.operation_type
          when nil, "query"
            types.query_root # rubocop:disable Development/ContextIsPassedCop
          when "mutation"
            types.mutation_root # rubocop:disable Development/ContextIsPassedCop
          when "subscription"
            types.subscription_root # rubocop:disable Development/ContextIsPassedCop
          end
          GraphQL::Execution::Lookahead.new(query: self, root_type: root_type, ast_nodes: [ast_node])
        end
      end
    end

    # @api private
    def result_values=(result_hash)
      if @executed
        raise "Invariant: Can't reassign result"
      else
        @executed = true
        @result_values = result_hash
      end
    end

    # @api private
    attr_reader :result_values

    def fragments
      with_prepared_ast { @fragments }
    end

    def operations
      with_prepared_ast { @operations }
    end

    # Get the result for this query, executing it once
    # @return [GraphQL::Query::Result] A Hash-like GraphQL response, with `"data"` and/or `"errors"` keys
    def result
      if !@executed
        Execution::Interpreter.run_all(@schema, [self], context: @context)
      end
      @result ||= Query::Result.new(query: self, values: @result_values)
    end

    def executed?
      @executed
    end

    def static_errors
      validation_errors + analysis_errors + context.errors
    end

    # This is the operation to run for this query.
    # If more than one operation is present, it must be named at runtime.
    # @return [GraphQL::Language::Nodes::OperationDefinition, nil]
    def selected_operation
      with_prepared_ast { @selected_operation }
    end

    # Determine the values for variables of this query, using default values
    # if a value isn't provided at runtime.
    #
    # If some variable is invalid, errors are added to {#validation_errors}.
    #
    # @return [GraphQL::Query::Variables] Variables to apply to this query
    def variables
      @variables ||= begin
        with_prepared_ast {
          GraphQL::Query::Variables.new(
            @context,
            @ast_variables,
            @provided_variables,
          )
        }
      end
    end

    # Node-level cache for calculating arguments. Used during execution and query analysis.
    # @param ast_node [GraphQL::Language::Nodes::AbstractNode]
    # @param definition [GraphQL::Schema::Field]
    # @param parent_object [GraphQL::Schema::Object]
    # @return Hash{Symbol => Object}
    def arguments_for(ast_node, definition, parent_object: nil)
      arguments_cache.fetch(ast_node, definition, parent_object)
    end

    def arguments_cache
      @arguments_cache ||= Execution::Interpreter::ArgumentsCache.new(self)
    end

    # A version of the given query string, with:
    # - Variables inlined to the query
    # - Strings replaced with `<REDACTED>`
    # @return [String, nil] Returns nil if the query is invalid.
    def sanitized_query_string(inline_variables: true)
      with_prepared_ast {
        schema.sanitized_printer.new(self, inline_variables: inline_variables).sanitized_query_string
      }
    end

    # This contains a few components:
    #
    # - The selected operation name (or `anonymous`)
    # - The fingerprint of the query string
    # - The number of given variables (for readability)
    # - The fingerprint of the given variables
    #
    # This fingerprint can be used to track runs of the same operation-variables combination over time.
    #
    # @see operation_fingerprint
    # @see variables_fingerprint
    # @return [String] An opaque hash identifying this operation-variables combination
    def fingerprint
      @fingerprint ||= "#{operation_fingerprint}/#{variables_fingerprint}"
    end

    # @return [String] An opaque hash for identifying this query's given query string and selected operation
    def operation_fingerprint
      @operation_fingerprint ||= "#{selected_operation_name || "anonymous"}/#{Fingerprint.generate(query_string || "")}"
    end

    # @return [String] An opaque hash for identifying this query's given a variable values (not including defaults)
    def variables_fingerprint
      @variables_fingerprint ||= "#{provided_variables.size}/#{Fingerprint.generate(provided_variables.to_json)}"
    end

    def validation_pipeline
      with_prepared_ast { @validation_pipeline }
    end

    def_delegators :validation_pipeline, :validation_errors,
                   :analyzers, :ast_analyzers, :max_depth, :max_complexity, :validate_timeout_remaining

    attr_accessor :analysis_errors
    def valid?
      validation_pipeline.valid? && analysis_errors.empty?
    end

    def warden
      with_prepared_ast { @warden }
    end

    def get_type(type_name)
      types.type(type_name) # rubocop:disable Development/ContextIsPassedCop
    end

    def get_field(owner, field_name)
      types.field(owner, field_name) # rubocop:disable Development/ContextIsPassedCop
    end

    def possible_types(type)
      types.possible_types(type) # rubocop:disable Development/ContextIsPassedCop
    end

    def root_type_for_operation(op_type)
      case op_type
      when "query"
        types.query_root # rubocop:disable Development/ContextIsPassedCop
      when "mutation"
        types.mutation_root # rubocop:disable Development/ContextIsPassedCop
      when "subscription"
        types.subscription_root # rubocop:disable Development/ContextIsPassedCop
      else
        raise ArgumentError, "unexpected root type name: #{op_type.inspect}; expected 'query', 'mutation', or 'subscription'"
      end
    end

    def types
      @visibility_profile || warden.visibility_profile
    end

    # @param abstract_type [GraphQL::UnionType, GraphQL::InterfaceType]
    # @param value [Object] Any runtime value
    # @return [GraphQL::ObjectType, nil] The runtime type of `value` from {Schema#resolve_type}
    # @see {#possible_types} to apply filtering from `only` / `except`
    def resolve_type(abstract_type, value = NOT_CONFIGURED)
      if value.is_a?(Symbol) && value == NOT_CONFIGURED
        # Old method signature
        value = abstract_type
        abstract_type = nil
      end
      if value.is_a?(GraphQL::Schema::Object)
        value = value.object
      end
      @resolved_types_cache[abstract_type][value]
    end

    def mutation?
      with_prepared_ast { @mutation }
    end

    def query?
      with_prepared_ast { @query }
    end

    def subscription?
      with_prepared_ast { @subscription }
    end

    # @api private
    def handle_or_reraise(err)
      schema.handle_or_reraise(context, err)
    end

    def after_lazy(value, &block)
      if !defined?(@runtime_instance)
        @runtime_instance = context.namespace(:interpreter_runtime)[:runtime]
      end

      if @runtime_instance
        @runtime_instance.minimal_after_lazy(value, &block)
      else
        @schema.after_lazy(value, &block)
      end
    end

    attr_reader :logger

    private

    def find_operation(operations, operation_name)
      if operation_name.nil? && operations.length == 1
        operations.values.first
      elsif !operations.key?(operation_name)
        nil
      else
        operations.fetch(operation_name)
      end
    end

    def prepare_ast
      @prepared_ast = true
      @warden ||= @schema.warden_class.new(schema: @schema, context: @context)
      parse_error = nil
      @document ||= begin
        current_trace.begin_parse(query_string)
        if query_string
          GraphQL.parse(query_string, trace: self.current_trace, max_tokens: @schema.max_query_string_tokens)
        end
      rescue GraphQL::ParseError => err
        parse_error = err
        @schema.parse_error(err, @context)
        nil
      ensure
        current_trace.end_parse(query_string)
      end

      @fragments = {}
      @operations = {}
      if @document
        @document.definitions.each do |part|
          case part
          when GraphQL::Language::Nodes::FragmentDefinition
            @fragments[part.name] = part
          when GraphQL::Language::Nodes::OperationDefinition
            @operations[part.name] = part
          end
        end
      elsif parse_error
        # This will be handled later
      else
        parse_error = GraphQL::ExecutionError.new("No query string was present")
        @context.add_error(parse_error)
      end

      # Trying to execute a document
      # with no operations returns an empty hash
      @ast_variables = []
      @mutation = false
      @subscription = false
      operation_name_error = nil
      if !@operations.empty?
        @selected_operation = find_operation(@operations, @operation_name)
        if @selected_operation.nil?
          operation_name_error = GraphQL::Query::OperationNameMissingError.new(@operation_name)
        else
          if @operation_name.nil?
            @operation_name = @selected_operation.name
          end
          @ast_variables = @selected_operation.variables
          @mutation = @selected_operation.operation_type == "mutation"
          @query = @selected_operation.operation_type == "query"
          @subscription = @selected_operation.operation_type == "subscription"
        end
      end

      @validation_pipeline = GraphQL::Query::ValidationPipeline.new(
        query: self,
        parse_error: parse_error,
        operation_name_error: operation_name_error,
        max_depth: @max_depth,
        max_complexity: @max_complexity
      )
    end

    # Since the query string is processed at the last possible moment,
    # any internal values which depend on it should be accessed within this wrapper.
    def with_prepared_ast
      if !@prepared_ast
        prepare_ast
      end
      yield
    end
  end
end
