# frozen_string_literal: true
module GraphQL
  module Language
    module DefinitionSlice
      extend self

      def slice(document, name)
        definitions = {}
        document.definitions.each { |d| definitions[d.name] = d }
        names = Set.new
        DependencyVisitor.find_definition_dependencies(definitions, name, names)
        definitions = document.definitions.select { |d| names.include?(d.name) }
        Nodes::Document.new(definitions: definitions)
      end

      private

      class DependencyVisitor < GraphQL::Language::StaticVisitor
        def initialize(doc, definitions, names)
          @names = names
          @definitions = definitions
          super(doc)
        end

        def on_fragment_spread(node, parent)
          if fragment = @definitions[node.name]
            self.class.find_definition_dependencies(@definitions, fragment.name, @names)
          end
          super
        end

        def self.find_definition_dependencies(definitions, name, names)
          names.add(name)
          visitor = self.new(definitions[name], definitions, names)
          visitor.visit
          nil
        end
      end
    end
  end
end
