class Types::FooType < Types::BaseObject
  field :other, [String]
  field :bar, [Thing], null: false do
    argument :baz, String
  end
end
