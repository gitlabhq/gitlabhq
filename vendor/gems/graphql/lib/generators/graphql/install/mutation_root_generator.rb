# frozen_string_literal: true

require "rails/generators/base"
require_relative "../core"

module Graphql
  module Generators
    module Install
      class MutationRootGenerator < Rails::Generators::Base
        include Core

        desc "Create mutation base type, mutation root type, and adds the latter to the schema"
        source_root File.expand_path('../templates', __FILE__)

        class_option :schema,
          type: :string,
          default: nil,
          desc: "Name for the schema constant (default: {app_name}Schema)"

        class_option :skip_keeps,
          type: :boolean,
          default: false,
          desc: "Skip .keep files for source control"

        def generate
          create_dir("#{options[:directory]}/mutations")
          template("base_mutation.erb", "#{options[:directory]}/mutations/base_mutation.rb", { skip: true })
          template("mutation_type.erb", "#{options[:directory]}/types/mutation_type.rb", { skip: true })
          insert_root_type('mutation', 'MutationType') 
        end
      end
    end
  end
end 
