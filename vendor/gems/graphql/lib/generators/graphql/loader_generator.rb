# frozen_string_literal: true
require 'rails/generators'
require "rails/generators/named_base"
require_relative "core"

module Graphql
  module Generators
    # @example Generate a `GraphQL::Batch` loader by name.
    #     rails g graphql:loader RecordLoader
    class LoaderGenerator < Rails::Generators::NamedBase
      include Core

      desc "Create a GraphQL::Batch::Loader by name"
      source_root File.expand_path('../templates', __FILE__)

      def create_loader_file
        template "loader.erb", "#{options[:directory]}/loaders/#{file_path}.rb"
      end
    end
  end
end
