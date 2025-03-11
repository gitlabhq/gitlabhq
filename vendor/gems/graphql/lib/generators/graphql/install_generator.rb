# frozen_string_literal: true
require 'rails/generators'
require 'rails/generators/base'
require_relative 'core'
require_relative 'relay'

module Graphql
  module Generators
    # Add GraphQL to a Rails app with `rails g graphql:install`.
    #
    # Setup a folder structure for GraphQL:
    #
    # ```
    # - app/
    #   - graphql/
    #     - resolvers/
    #     - types/
    #       - base_argument.rb
    #       - base_field.rb
    #       - base_enum.rb
    #       - base_input_object.rb
    #       - base_interface.rb
    #       - base_object.rb
    #       - base_scalar.rb
    #       - base_union.rb
    #       - query_type.rb
    #     - loaders/
    #     - mutations/
    #       - base_mutation.rb
    #     - {app_name}_schema.rb
    # ```
    #
    # (Add `.gitkeep`s by default, support `--skip-keeps`)
    #
    # Add a controller for serving GraphQL queries:
    #
    # ```
    # app/controllers/graphql_controller.rb
    # ```
    #
    # Add a route for that controller:
    #
    # ```ruby
    # # config/routes.rb
    # post "/graphql", to: "graphql#execute"
    # ```
    #
    # Add ActiveRecord::QueryLogs metadata:
    # ```ruby
    #   current_graphql_operation: -> { GraphQL::Current.operation_name },
    #   current_graphql_field: -> { GraphQL::Current.field&.path },
    #   current_dataloader_source: -> { GraphQL::Current.dataloader_source_class },
    # ```
    #
    # Accept a `--batch` option which adds `GraphQL::Batch` setup.
    #
    # Use `--skip-graphiql` to skip `graphiql-rails` installation.
    #
    # TODO: also add base classes
    class InstallGenerator < Rails::Generators::Base
      include Core
      include Relay

      desc "Install GraphQL folder structure and boilerplate code"
      source_root File.expand_path('../templates', __FILE__)

      class_option :schema,
        type: :string,
        default: nil,
        desc: "Name for the schema constant (default: {app_name}Schema)"

      class_option :skip_keeps,
        type: :boolean,
        default: false,
        desc: "Skip .keep files for source control"

      class_option :skip_graphiql,
        type: :boolean,
        default: false,
        desc: "Skip graphiql-rails installation"

      class_option :skip_mutation_root_type,
        type: :boolean,
        default: false,
        desc: "Skip creation of the mutation root type"

      class_option :relay,
        type: :boolean,
        default: true,
        desc: "Include installation of Relay conventions (nodes, connections, edges)"

      class_option :batch,
        type: :boolean,
        default: false,
        desc: "Include GraphQL::Batch installation"

      class_option :playground,
        type: :boolean,
        default: false,
        desc: "Use GraphQL Playground over Graphiql as IDE"

      class_option :skip_query_logs,
        type: :boolean,
        default: false,
        desc: "Skip ActiveRecord::QueryLogs hooks in config/application.rb"

      # These two options are taken from Rails' own generators'
      class_option :api,
        type: :boolean,
        desc: "Preconfigure smaller stack for API only apps"

      def create_folder_structure
        create_dir("#{options[:directory]}/types")
        template("schema.erb", schema_file_path)

        ["base_object", "base_argument", "base_field", "base_enum", "base_input_object", "base_interface", "base_scalar", "base_union"].each do |base_type|
          template("#{base_type}.erb", "#{options[:directory]}/types/#{base_type}.rb")
        end

        # All resolvers are defined as living in their own module, including this class.
        template("base_resolver.erb", "#{options[:directory]}/resolvers/base_resolver.rb")

        # Note: You can't have a schema without the query type, otherwise introspection breaks
        template("query_type.erb", "#{options[:directory]}/types/query_type.rb")
        insert_root_type('query', 'QueryType')

        invoke "graphql:install:mutation_root" unless options.skip_mutation_root_type?

        template("graphql_controller.erb", "app/controllers/graphql_controller.rb")
        route('post "/graphql", to: "graphql#execute"')

        if options[:batch]
          gem("graphql-batch")
          create_dir("#{options[:directory]}/loaders")
        end

        if options.api?
          say("Skipped graphiql, as this rails project is API only")
          say("  You may wish to use GraphiQL.app for development: https://github.com/skevy/graphiql-app")
        elsif !options[:skip_graphiql]
          # `gem(...)` uses `gsub_file(...)` under the hood, which is a no-op for `rails destroy...` (when `behavior == :revoke`).
          # So handle that case by calling `gsub_file` with `force: true`.
          if behavior == :invoke && !File.read(Rails.root.join("Gemfile")).include?("graphiql-rails")
            gem("graphiql-rails", group: :development)
          elsif behavior == :revoke
            gemfile_pattern = /\n\s*gem ('|")graphiql-rails('|"), :?group(:| =>) :development/
            gsub_file Rails.root.join("Gemfile"), gemfile_pattern, "", { force: true }
          end

          # This is a little cheat just to get cleaner shell output:
          log :route, 'graphiql-rails'
          shell.mute do
            # Rails 5.2 has better support for `route`?
            if Rails::VERSION::STRING > "5.2"
              route <<-RUBY
if Rails.env.development?
  mount GraphiQL::Rails::Engine, at: "/graphiql", graphql_path: "/graphql"
end
RUBY
            else
              route <<-RUBY
if Rails.env.development?
    mount GraphiQL::Rails::Engine, at: "/graphiql", graphql_path: "/graphql"
  end
RUBY
            end
          end
        end

        if options[:playground]
          gem("graphql_playground-rails", group: :development)

          log :route, 'graphql_playground-rails'
          shell.mute do
            if Rails::VERSION::STRING > "5.2"
              route <<-RUBY
if Rails.env.development?
  mount GraphqlPlayground::Rails::Engine, at: "/playground", graphql_path: "/graphql"
end
RUBY
            else
              route <<-RUBY
if Rails.env.development?
    mount GraphqlPlayground::Rails::Engine, at: "/playground", graphql_path: "/graphql"
  end
RUBY
            end
          end
        end

        if options[:relay]
          install_relay
        end

        if !options[:skip_query_logs]
          config_file = "config/application.rb"
          current_app_rb = File.read(Rails.root.join(config_file))
          existing_log_tags_pattern = /config.active_record.query_log_tags = \[\n?(\s*:[a-z_]+,?\s*\n?|\s*#[^\]]*\n)*/m
          existing_log_tags = existing_log_tags_pattern.match(current_app_rb)
          if existing_log_tags && behavior == :invoke
            code = <<-RUBY
      # GraphQL-Ruby query log tags:
      current_graphql_operation: -> { GraphQL::Current.operation_name },
      current_graphql_field: -> { GraphQL::Current.field&.path },
      current_dataloader_source: -> { GraphQL::Current.dataloader_source_class },
RUBY
            if !existing_log_tags.to_s.end_with?(",")
              code = ",\n#{code}    "
            end
            # Try to insert this code _after_ any plain symbol entries in the array of query log tags:
            after_code = existing_log_tags_pattern
          else
            code = <<-RUBY
    config.active_record.query_log_tags_enabled = true
    config.active_record.query_log_tags = [
      # Rails query log tags:
      :application, :controller, :action, :job,
      # GraphQL-Ruby query log tags:
      current_graphql_operation: -> { GraphQL::Current.operation_name },
      current_graphql_field: -> { GraphQL::Current.field&.path },
      current_dataloader_source: -> { GraphQL::Current.dataloader_source_class },
    ]
RUBY
            after_code = "class Application < Rails::Application\n"
          end
          insert_into_file(config_file, code, after: after_code)
        end

        if gemfile_modified?
          say "Gemfile has been modified, make sure you `bundle install`"
        end
      end

      private

      def gemfile_modified?
        @gemfile_modified
      end

      def gem(*args)
        @gemfile_modified = true
        super(*args)
      end
    end
  end
end
