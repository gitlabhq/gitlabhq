# frozen_string_literal: true
require 'rails/generators/base'

module Graphql
  module Generators
    module Core
      def self.included(base)
        base.send(
          :class_option,
          :directory,
          type: :string,
          default: "app/graphql",
          desc: "Directory where generated files should be saved"
        )
      end

      def insert_root_type(type, name)
        log :add_root_type, type
        sentinel = /< GraphQL::Schema\s*\n/m

        in_root do
          if File.exist?(schema_file_path)
            inject_into_file schema_file_path, "  #{type}(Types::#{name})\n", after: sentinel, verbose: false, force: false
          end
        end
      end

      def schema_file_path
        "#{options[:directory]}/#{schema_name.underscore}.rb"
      end

      def create_dir(dir)
        empty_directory(dir)
        if !options[:skip_keeps]
          create_file("#{dir}/.keep")
        end
      end

      def module_namespacing_when_supported
        if defined?(module_namespacing)
          module_namespacing { yield }
        else
          yield
        end
      end

      private

      def schema_name
        @schema_name ||= begin
          if options[:schema]
            options[:schema]
          else
            "#{parent_name}Schema"
          end
        end
      end

      def parent_name
        require File.expand_path("config/application", destination_root)
        if Rails.application.class.respond_to?(:module_parent_name)
          Rails.application.class.module_parent_name
        else
          Rails.application.class.parent_name
        end
      end
    end
  end
end
