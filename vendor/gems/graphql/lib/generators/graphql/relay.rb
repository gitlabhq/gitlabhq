# frozen_string_literal: true
module Graphql
  module Generators
    module Relay
      def install_relay
        # Add Node, `node(id:)`, and `nodes(ids:)`
        template("node_type.erb", "#{options[:directory]}/types/node_type.rb")
        in_root do
          fields = <<-RUBY
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

    RUBY
          inject_into_file "#{options[:directory]}/types/query_type.rb", fields, after: /class .*QueryType\s*<\s*[^\s]+?\n/m, force: false
        end

        # Add connections and edges
        template("base_connection.erb", "#{options[:directory]}/types/base_connection.rb")
        template("base_edge.erb", "#{options[:directory]}/types/base_edge.rb")
        connectionable_type_files = {
          "#{options[:directory]}/types/base_object.rb" => /class .*BaseObject\s*<\s*[^\s]+?\n/m,
          "#{options[:directory]}/types/base_union.rb" =>  /class .*BaseUnion\s*<\s*[^\s]+?\n/m,
          "#{options[:directory]}/types/base_interface.rb" => /include GraphQL::Schema::Interface\n/m,
        }
        in_root do
          connectionable_type_files.each do |type_class_file, sentinel|
            inject_into_file type_class_file, "    connection_type_class(Types::BaseConnection)\n", after: sentinel, force: false
            inject_into_file type_class_file, "    edge_type_class(Types::BaseEdge)\n", after: sentinel, force: false
          end
        end

        # Add object ID hooks & connection plugin
        schema_code = <<-RUBY

  # Relay-style Object Identification:

  # Return a string UUID for `object`
  def self.id_from_object(object, type_definition, query_ctx)
    # For example, use Rails' GlobalID library (https://github.com/rails/globalid):
    object.to_gid_param
  end

  # Given a string UUID, find the object
  def self.object_from_id(global_id, query_ctx)
    # For example, use Rails' GlobalID library (https://github.com/rails/globalid):
    GlobalID.find(global_id)
  end
RUBY
        inject_into_file schema_file_path, schema_code, before: /^end\n/m, force: false
      end
    end
  end
end
