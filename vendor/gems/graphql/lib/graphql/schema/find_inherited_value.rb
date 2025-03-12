# frozen_string_literal: true
module GraphQL
  class Schema
    module FindInheritedValue
      def self.extended(child_cls)
        child_cls.singleton_class.include(GraphQL::EmptyObjects)
      end

      def self.included(child_cls)
        child_cls.include(GraphQL::EmptyObjects)
      end

      private

      def find_inherited_value(method_name, default_value = nil)
        if self.is_a?(Class)
          superclass.respond_to?(method_name, true) ? superclass.send(method_name) : default_value
        else
          ancestors_except_self = ancestors
          ancestors_except_self.delete(self)
          ancestors_except_self.each do |ancestor|
            if ancestor.respond_to?(method_name, true)
              return ancestor.send(method_name)
            end
          end
          default_value
        end
      end
    end
  end
end
