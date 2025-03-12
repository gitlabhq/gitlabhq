# frozen_string_literal: true
module EagerModule
  module NestedEagerModule
    extend GraphQL::Autoload
    autoload(:NestedEagerClass, "fixtures/eager_module/nested_eager_module/nested_eager_class")
  end
end
