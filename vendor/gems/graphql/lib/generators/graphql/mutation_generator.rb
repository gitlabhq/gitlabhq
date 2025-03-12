# frozen_string_literal: true
require 'rails/generators'
require 'rails/generators/named_base'
require_relative 'core'

module Graphql
  module Generators
    # TODO: What other options should be supported?
    #
    # @example Generate a `GraphQL::Schema::RelayClassicMutation` by name
    #     rails g graphql:mutation CreatePostMutation
    class MutationGenerator < Rails::Generators::NamedBase
      include Core

      desc "Create a Relay Classic mutation by name"
      source_root File.expand_path('../templates', __FILE__)

      def create_mutation_file
        template "mutation.erb", File.join(options[:directory], "/mutations/", class_path, "#{file_name}.rb")

        sentinel = /class .*MutationType\s*<\s*[^\s]+?\n/m
        in_root do
          path = "#{options[:directory]}/types/mutation_type.rb"
          invoke "graphql:install:mutation_root" unless File.exist?(path)
          inject_into_file "#{options[:directory]}/types/mutation_type.rb", "    field :#{file_name}, mutation: Mutations::#{class_name}\n", after: sentinel, verbose: false, force: false
        end
      end
    end
  end
end
