# frozen_string_literal: true
require "fileutils"
require "rake"
require "graphql/rake_task/validate"

module GraphQL
  # A rake task for dumping a schema as IDL or JSON.
  #
  # By default, schemas are looked up by name as constants using `schema_name:`.
  # You can provide a `load_schema` function to return your schema another way.
  #
  # Use `load_context:` and `visible?` to dump schemas under certain visibility constraints.
  #
  # @example Dump a Schema to .graphql + .json files
  #   require "graphql/rake_task"
  #   GraphQL::RakeTask.new(schema_name: "MySchema")
  #
  #   # $ rake graphql:schema:dump
  #   # Schema IDL dumped to ./schema.graphql
  #   # Schema JSON dumped to ./schema.json
  #
  # @example Invoking the task from Ruby
  #   require "rake"
  #   Rake::Task["graphql:schema:dump"].invoke
  #
  # @example Providing arguments to build the introspection query
  #   require "graphql/rake_task"
  #   GraphQL::RakeTask.new(schema_name: "MySchema", include_is_one_of: true)
  class RakeTask
    include Rake::DSL

    DEFAULT_OPTIONS = {
      namespace: "graphql",
      dependencies: nil,
      schema_name: nil,
      load_schema: ->(task) { Object.const_get(task.schema_name) },
      load_context: ->(task) { {} },
      directory: ".",
      idl_outfile: "schema.graphql",
      json_outfile: "schema.json",
      include_deprecated_args: true,
      include_schema_description: false,
      include_is_repeatable: false,
      include_specified_by_url: false,
      include_is_one_of: false
    }

    # @return [String] Namespace for generated tasks
    attr_writer :namespace

    def rake_namespace
      @namespace
    end

    # @return [Array<String>]
    attr_accessor :dependencies

    # @return [String] By default, used to find the schema as a constant.
    # @see {#load_schema} for loading a schema another way
    attr_accessor :schema_name

    # @return [<#call(task)>] A proc for loading the target GraphQL schema
    attr_accessor :load_schema

    # @return [<#call(task)>] A callable for loading the query context
    attr_accessor :load_context

    # @return [String] target for IDL task
    attr_accessor :idl_outfile

    # @return [String] target for JSON task
    attr_accessor :json_outfile

    # @return [String] directory for IDL & JSON files
    attr_accessor :directory

    # @return [Boolean] Options for additional fields in the introspection query JSON response
    # @see GraphQL::Schema.as_json
    attr_accessor :include_deprecated_args, :include_schema_description, :include_is_repeatable, :include_specified_by_url, :include_is_one_of

    # Set the parameters of this task by passing keyword arguments
    # or assigning attributes inside the block
    def initialize(options = {})
      all_options = DEFAULT_OPTIONS.merge(options)
      all_options.each do |k, v|
        self.public_send("#{k}=", v)
      end

      if block_given?
        yield(self)
      end

      define_task
    end

    private

    # Use the provided `method_name` to generate a string from the specified schema
    # then write it to `file`.
    def write_outfile(method_name, file)
      schema = @load_schema.call(self)
      context = @load_context.call(self)
      result = case method_name
      when :to_json
        schema.to_json(
          include_is_one_of: include_is_one_of,
          include_deprecated_args: include_deprecated_args,
          include_is_repeatable: include_is_repeatable,
          include_specified_by_url: include_specified_by_url,
          include_schema_description: include_schema_description,
          context: context
        )
      when :to_definition
        schema.to_definition(context: context)
      else
        raise ArgumentError, "Unexpected schema dump method: #{method_name.inspect}"
      end
      dir = File.dirname(file)
      FileUtils.mkdir_p(dir)
      if !result.end_with?("\n")
        result += "\n"
      end
      File.write(file, result)
    end

    def idl_path
      File.join(@directory, @idl_outfile)
    end

    def json_path
      File.join(@directory, @json_outfile)
    end

    def load_rails_environment_if_defined
      if Rake::Task.task_defined?('environment')
        Rake::Task['environment'].invoke
      end
    end

    # Use the Rake DSL to add tasks
    def define_task
      namespace(@namespace) do
        namespace("schema") do
          desc("Dump the schema to IDL in #{idl_path}")
          task :idl => @dependencies do
            load_rails_environment_if_defined
            write_outfile(:to_definition, idl_path)
            puts "Schema IDL dumped into #{idl_path}"
          end

          desc("Dump the schema to JSON in #{json_path}")
          task :json => @dependencies do
            load_rails_environment_if_defined
            write_outfile(:to_json, json_path)
            puts "Schema JSON dumped into #{json_path}"
          end

          desc("Dump the schema to JSON and IDL")
          task :dump => [:idl, :json]
        end
      end
    end
  end
end
