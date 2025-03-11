# frozen_string_literal: true
require "delegate"
require "json"
require "set"
require "singleton"
require "forwardable"
require "fiber/storage"
require "graphql/autoload"

module GraphQL
  extend Autoload

  # Load all `autoload`-configured classes, and also eager-load dependents who have autoloads of their own.
  def self.eager_load!
    super
    Query.eager_load!
    Types.eager_load!
    Schema.eager_load!
  end

  class Error < StandardError
  end

  # This error is raised when GraphQL-Ruby encounters a situation
  # that it *thought* would never happen. Please report this bug!
  class InvariantError < Error
    def initialize(message)
      message += "

This is probably a bug in GraphQL-Ruby, please report this error on GitHub: https://github.com/rmosolgo/graphql-ruby/issues/new?template=bug_report.md"
      super(message)
    end
  end

  class RequiredImplementationMissingError < Error
  end

  class << self
    def default_parser
      @default_parser ||= GraphQL::Language::Parser
    end

    attr_writer :default_parser
  end

  # Turn a query string or schema definition into an AST
  # @param graphql_string [String] a GraphQL query string or schema definition
  # @return [GraphQL::Language::Nodes::Document]
  def self.parse(graphql_string, trace: GraphQL::Tracing::NullTrace, filename: nil, max_tokens: nil)
    default_parser.parse(graphql_string, trace: trace, filename: filename, max_tokens: max_tokens)
  end

  # Read the contents of `filename` and parse them as GraphQL
  # @param filename [String] Path to a `.graphql` file containing IDL or query
  # @return [GraphQL::Language::Nodes::Document]
  def self.parse_file(filename)
    content = File.read(filename)
    default_parser.parse(content, filename: filename)
  end

  # @return [Array<Array>]
  def self.scan(graphql_string)
    default_parser.scan(graphql_string)
  end

  def self.parse_with_racc(string, filename: nil, trace: GraphQL::Tracing::NullTrace)
    warn "`GraphQL.parse_with_racc` is deprecated; GraphQL-Ruby no longer uses racc for parsing. Call `GraphQL.parse` or `GraphQL::Language::Parser.parse` instead."
    GraphQL::Language::Parser.parse(string, filename: filename, trace: trace)
  end

  def self.scan_with_ruby(graphql_string)
    GraphQL::Language::Lexer.tokenize(graphql_string)
  end

  NOT_CONFIGURED = Object.new
  private_constant :NOT_CONFIGURED
  module EmptyObjects
    EMPTY_HASH = {}.freeze
    EMPTY_ARRAY = [].freeze
  end

  class << self
    # If true, the parser should raise when an integer or float is followed immediately by an identifier (instead of a space or punctuation)
    attr_accessor :reject_numbers_followed_by_names
  end

  self.reject_numbers_followed_by_names = false

  autoload :ExecutionError, "graphql/execution_error"
  autoload :RuntimeTypeError, "graphql/runtime_type_error"
  autoload :UnresolvedTypeError, "graphql/unresolved_type_error"
  autoload :InvalidNullError, "graphql/invalid_null_error"
  autoload :AnalysisError, "graphql/analysis_error"
  autoload :CoercionError, "graphql/coercion_error"
  autoload :InvalidNameError, "graphql/invalid_name_error"
  autoload :IntegerDecodingError, "graphql/integer_decoding_error"
  autoload :IntegerEncodingError, "graphql/integer_encoding_error"
  autoload :StringEncodingError, "graphql/string_encoding_error"
  autoload :DateEncodingError, "graphql/date_encoding_error"
  autoload :DurationEncodingError, "graphql/duration_encoding_error"
  autoload :TypeKinds, "graphql/type_kinds"
  autoload :NameValidator, "graphql/name_validator"
  autoload :Language, "graphql/language"

  autoload :Analysis, "graphql/analysis"
  autoload :Tracing, "graphql/tracing"
  autoload :Dig, "graphql/dig"
  autoload :Execution, "graphql/execution"
  autoload :Pagination, "graphql/pagination"
  autoload :Schema, "graphql/schema"
  autoload :Query, "graphql/query"
  autoload :Dataloader, "graphql/dataloader"
  autoload :Types, "graphql/types"
  autoload :StaticValidation, "graphql/static_validation"
  autoload :Execution, "graphql/execution"
  autoload :Introspection, "graphql/introspection"
  autoload :Relay, "graphql/relay"
  autoload :Subscriptions, "graphql/subscriptions"
  autoload :ParseError, "graphql/parse_error"
  autoload :Backtrace, "graphql/backtrace"

  autoload :UnauthorizedError, "graphql/unauthorized_error"
  autoload :UnauthorizedEnumValueError, "graphql/unauthorized_enum_value_error"
  autoload :UnauthorizedFieldError, "graphql/unauthorized_field_error"
  autoload :LoadApplicationObjectFailedError, "graphql/load_application_object_failed_error"
  autoload :Testing, "graphql/testing"
  autoload :Current, "graphql/current"
  if defined?(::Rails::Engine)
    autoload :Dashboard, 'graphql/dashboard'
  end
end

require "graphql/version"
require "graphql/railtie" if defined? Rails::Railtie
