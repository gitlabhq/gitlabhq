# frozen_string_literal: true
require "spec_helper"
require "generators/graphql/install_generator"

class GraphQLGeneratorsInstallGeneratorTest < Rails::Generators::TestCase
  tests Graphql::Generators::InstallGenerator
  destination File.expand_path("../../../tmp/dummy", File.dirname(__FILE__))

  setup do
    prepare_destination

    FileUtils.cd(File.join(destination_root, '..')) do
      `rails new dummy --skip-active-record --skip-test-unit --skip-spring --skip-bundle --skip-webpack-install`
    end
  end

  def refute_file(path)
    assert !File.exist?(path), "No file at #{path.inspect}"
  end

  test "it generates a folder structure" do
    run_generator([ "--relay", "false"])

    assert_file "app/graphql/types/.keep"
    assert_file "app/graphql/mutations/.keep"
    assert_file "app/graphql/mutations/base_mutation.rb"
    ["base_input_object", "base_enum", "base_scalar", "base_union"].each do |base_type|
      assert_file "app/graphql/types/#{base_type}.rb"
    end

    expected_query_route = %|post "/graphql", to: "graphql#execute"|
    expected_graphiql_route = %|
  if Rails.env.development?
    mount GraphiQL::Rails::Engine, at: "/graphiql", graphql_path: "/graphql"
  end
|

    assert_file "config/routes.rb" do |contents|
      assert_includes contents, expected_query_route
      assert_includes contents, expected_graphiql_route
    end

    assert_file "app/graphql/resolvers/base_resolver.rb" do |contents|
      assert_includes contents, "module Resolvers"
      assert_includes contents, "class BaseResolver < GraphQL::Schema::Resolver"
    end

    assert_file "Gemfile" do |contents|
      assert_match %r{gem ('|")graphiql-rails('|"), :?group(:| =>) :development}, contents
    end

    expected_schema = <<-RUBY
# frozen_string_literal: true

class DummySchema < GraphQL::Schema
  mutation(Types::MutationType)
  query(Types::QueryType)

  # For batch-loading (see https://graphql-ruby.org/dataloader/overview.html)
  use GraphQL::Dataloader

  # GraphQL-Ruby calls this when something goes wrong while running a query:
  def self.type_error(err, context)
    # if err.is_a?(GraphQL::InvalidNullError)
    #   # report to your bug tracker here
    #   return nil
    # end
    super
  end

  # Union and Interface Resolution
  def self.resolve_type(abstract_type, obj, ctx)
    # TODO: Implement this method
    # to return the correct GraphQL object type for `obj`
    raise(GraphQL::RequiredImplementationMissingError)
  end

  # Limit the size of incoming queries:
  max_query_string_tokens(5000)

  # Stop validating when it encounters this many errors:
  validate_max_errors(100)
end
RUBY
    assert_file "app/graphql/dummy_schema.rb", expected_schema

    expected_base_mutation = <<-RUBY
# frozen_string_literal: true

module Mutations
  class BaseMutation < GraphQL::Schema::RelayClassicMutation
    argument_class Types::BaseArgument
    field_class Types::BaseField
    input_object_class Types::BaseInputObject
    object_class Types::BaseObject
  end
end
RUBY
    assert_file "app/graphql/mutations/base_mutation.rb", expected_base_mutation

    expected_query_type = <<-RUBY
# frozen_string_literal: true

module Types
  class QueryType < Types::BaseObject
    # Add root-level fields here.
    # They will be entry points for queries on your schema.

    # TODO: remove me
    field :test_field, String, null: false,
      description: \"An example field added by the generator\"
    def test_field
      \"Hello World!\"
    end
  end
end
RUBY

    assert_file "app/graphql/types/query_type.rb", expected_query_type
    assert_file "app/controllers/graphql_controller.rb", EXPECTED_GRAPHQLS_CONTROLLER
    expected_base_field = <<-RUBY
# frozen_string_literal: true

module Types
  class BaseField < GraphQL::Schema::Field
    argument_class Types::BaseArgument
  end
end
RUBY
    assert_file "app/graphql/types/base_field.rb", expected_base_field

    expected_base_argument = <<-RUBY
# frozen_string_literal: true

module Types
  class BaseArgument < GraphQL::Schema::Argument
  end
end
RUBY
    assert_file "app/graphql/types/base_argument.rb", expected_base_argument

    expected_base_object = <<-RUBY
# frozen_string_literal: true

module Types
  class BaseObject < GraphQL::Schema::Object
    field_class Types::BaseField
  end
end
RUBY
    assert_file "app/graphql/types/base_object.rb", expected_base_object

    expected_base_interface = <<-RUBY
# frozen_string_literal: true

module Types
  module BaseInterface
    include GraphQL::Schema::Interface

    field_class Types::BaseField
  end
end
RUBY
    assert_file "app/graphql/types/base_interface.rb", expected_base_interface

    expected_query_log_hook = "current_graphql_operation: -> { GraphQL::Current.operation_name }"
    assert_file "config/application.rb" do |contents|
      assert_includes contents, expected_query_log_hook
    end

    # Run it again and make sure the gemfile only contains graphiql-rails once
    FileUtils.cd(File.join(destination_root)) do
      run_generator(["--relay", "false", "--force"])
    end
    assert_file "Gemfile" do |contents|
      assert_equal 1, contents.scan(/graphiql-rails/).length
    end

    # It doesn't seem like this works on Rails 4, oh well
    if Rails::VERSION::STRING > "5"
      FileUtils.cd(File.join(destination_root)) do
        run_generator(["--relay", "false", "--force"], behavior: :revoke)
      end

      refute_file "app/graphql/types/base_object.rb"
      refute_file "app/graphql/types/base_interface.rb"
      refute_file "app/graphql/types/base_argument.rb"
      refute_file "app/graphql/types/base_field.rb"
      refute_file "app/graphql/types/query_type.rb"
      refute_file "app/graphql/dummy_schema.rb"

      assert_file "config/routes.rb" do |contents|
        refute_includes contents, expected_query_route
        # This doesn't work for some reason....
        # refute_includes contents, expected_graphiql_route
      end

      assert_file "Gemfile" do |contents|
        refute_match %r{gem ('|")graphiql-rails('|"), :?group(:| =>) :development}, contents
      end

      assert_file "config/application.rb" do |contents|
        refute_includes contents, expected_query_log_hook
      end
    end
  end

  test "it allows for a user-specified install directory" do
    run_generator(["--directory", "app/mydirectory", "--relay", "false"])

    assert_file "app/mydirectory/types/.keep"
    assert_file "app/mydirectory/mutations/.keep"
  end

  if Rails::VERSION::STRING > "3.9"
    # This test doesn't work on Rails 3 because it tries to boot the app
    # between the batch and relay generators, but `bundle install`
    # hasn't run yet, so graphql-batch isn't present
    test "it generates graphql-batch and relay boilerplate" do
      run_generator(["--batch"])
      assert_file "app/graphql/loaders/.keep"
      assert_file "Gemfile" do |contents|
        assert_match %r{gem ('|")graphql-batch('|")}, contents
      end

      expected_query_type = <<-RUBY
# frozen_string_literal: true

module Types
  class QueryType < Types::BaseObject
    field :node, Types::NodeType, null: true, description: "Fetches an object given its ID." do
      argument :id, ID, required: true, description: "ID of the object."
    end

    def node(id:)
      context.schema.object_from_id(id, context)
    end

    field :nodes, [Types::NodeType, null: true], null: true, description: "Fetches a list of objects given a list of IDs." do
      argument :ids, [ID], required: true, description: "IDs of the objects."
    end

    def nodes(ids:)
      ids.map { |id| context.schema.object_from_id(id, context) }
    end

    # Add root-level fields here.
    # They will be entry points for queries on your schema.

    # TODO: remove me
    field :test_field, String, null: false,
      description: \"An example field added by the generator\"
    def test_field
      \"Hello World!\"
    end
  end
end
RUBY

      assert_file "app/graphql/types/query_type.rb", expected_query_type
      assert_file "app/graphql/dummy_schema.rb", EXPECTED_RELAY_BATCH_SCHEMA
    end
  end

  test "it doesn't install graphiql when API Only" do

    run_generator(['--api'])

    assert_file "Gemfile" do |contents|
      refute_includes contents, "graphiql-rails"
    end

    assert_file "config/routes.rb" do |contents|
      refute_includes contents, "GraphiQL::Rails"
    end
  end

  test "it can skip keeps, skip graphiql, skip query logs and customize schema name" do
    run_generator(["--skip-keeps", "--skip-graphiql", "--schema=CustomSchema","--skip-query-logs"])
    assert_no_file "app/graphql/types/.keep"
    assert_no_file "app/graphql/mutations/.keep"
    assert_file "app/graphql/types"
    assert_file "app/graphql/mutations"
    assert_file "Gemfile" do |contents|
      refute_includes contents, "graphiql-rails"
    end

    assert_file "config/routes.rb" do |contents|
      refute_includes contents, "GraphiQL::Rails"
    end

    assert_file "config/application.rb" do |contents|
      refute_includes contents, "graphql"
    end

    assert_file "app/graphql/custom_schema.rb", /class CustomSchema < GraphQL::Schema/
    assert_file "app/controllers/graphql_controller.rb", /CustomSchema\.execute/
  end

  test "it can add GraphQL Playground as an IDE through the --playground option and modify existing query tags" do
    # Make it look like QueryLogs was already added:
    config_file_path = File.expand_path("config/application.rb", destination_root)
    config_file_contents = File.read(config_file_path)
    config_file_contents.sub!("class Application < Rails::Application", "class Application < Rails::Application
    config.active_record.query_log_tags_enabled = true
    config.active_record.query_log_tags = [ :application, :controller, :action, :job ]
")

    File.write(config_file_path, config_file_contents)
    run_generator(["--playground"])

    assert_file "Gemfile" do |contents|
      assert_includes contents, "graphql_playground-rails"
    end

    expected_playground_route = %|
  if Rails.env.development?
    mount GraphqlPlayground::Rails::Engine, at: "/playground", graphql_path: "/graphql"
  end
|

    assert_file "config/routes.rb" do |contents|
      assert_includes contents, expected_playground_route
    end

    assert_file "config/application.rb" do |contents|
      assert_includes contents, "
    config.active_record.query_log_tags = [ :application, :controller, :action, :job ,
      # GraphQL-Ruby query log tags:
      current_graphql_operation: -> { GraphQL::Current.operation_name },
      current_graphql_field: -> { GraphQL::Current.field&.path },
      current_dataloader_source: -> { GraphQL::Current.dataloader_source_class },
    ]
"
    end
  end

  EXPECTED_GRAPHQLS_CONTROLLER = <<-'RUBY'
# frozen_string_literal: true

class GraphqlController < ApplicationController
  # If accessing from outside this domain, nullify the session
  # This allows for outside API access while preventing CSRF attacks,
  # but you'll have to authenticate your user separately
  # protect_from_forgery with: :null_session

  def execute
    variables = prepare_variables(params[:variables])
    query = params[:query]
    operation_name = params[:operationName]
    context = {
      # Query context goes here, for example:
      # current_user: current_user,
    }
    result = DummySchema.execute(query, variables: variables, context: context, operation_name: operation_name)
    render json: result
  rescue StandardError => e
    raise e unless Rails.env.development?
    handle_error_in_development(e)
  end

  private

  # Handle variables in form data, JSON body, or a blank value
  def prepare_variables(variables_param)
    case variables_param
    when String
      if variables_param.present?
        JSON.parse(variables_param) || {}
      else
        {}
      end
    when Hash
      variables_param
    when ActionController::Parameters
      variables_param.to_unsafe_hash # GraphQL-Ruby will validate name and type of incoming variables.
    when nil
      {}
    else
      raise ArgumentError, "Unexpected parameter: #{variables_param}"
    end
  end

  def handle_error_in_development(e)
    logger.error e.message
    logger.error e.backtrace.join("\n")

    render json: { errors: [{ message: e.message, backtrace: e.backtrace }], data: {} }, status: 500
  end
end
RUBY

  EXPECTED_RELAY_BATCH_SCHEMA = '# frozen_string_literal: true

class DummySchema < GraphQL::Schema
  mutation(Types::MutationType)
  query(Types::QueryType)

  # GraphQL::Batch setup:
  use GraphQL::Batch

  # GraphQL-Ruby calls this when something goes wrong while running a query:
  def self.type_error(err, context)
    # if err.is_a?(GraphQL::InvalidNullError)
    #   # report to your bug tracker here
    #   return nil
    # end
    super
  end

  # Union and Interface Resolution
  def self.resolve_type(abstract_type, obj, ctx)
    # TODO: Implement this method
    # to return the correct GraphQL object type for `obj`
    raise(GraphQL::RequiredImplementationMissingError)
  end

  # Limit the size of incoming queries:
  max_query_string_tokens(5000)

  # Stop validating when it encounters this many errors:
  validate_max_errors(100)

  # Relay-style Object Identification:

  # Return a string UUID for `object`
  def self.id_from_object(object, type_definition, query_ctx)
    # For example, use Rails\' GlobalID library (https://github.com/rails/globalid):
    object.to_gid_param
  end

  # Given a string UUID, find the object
  def self.object_from_id(global_id, query_ctx)
    # For example, use Rails\' GlobalID library (https://github.com/rails/globalid):
    GlobalID.find(global_id)
  end
end
'
end
