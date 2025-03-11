# frozen_string_literal: true
module GraphQL
  module StaticValidation
    class InterpreterVisitor < BaseVisitor
      include(GraphQL::StaticValidation::DefinitionDependencies)

      StaticValidation::ALL_RULES.reverse_each do |r|
        include(r)
      end

      include(ContextMethods)
    end
  end
end
