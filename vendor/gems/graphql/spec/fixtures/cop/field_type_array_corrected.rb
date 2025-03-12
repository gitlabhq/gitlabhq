class Types::FooType < Types::BaseObject
  field :other, [String]
  field :bar, null: false do
    type [Thing]
    argument :baz, String
  end
end
