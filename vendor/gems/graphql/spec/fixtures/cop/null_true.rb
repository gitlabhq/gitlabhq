class Types::Something < Types::BaseObject
  field :name, String, null: true

  field :other_name, String,
    null: true,
    description: "Here's a description"

  field :described, [String, null: true], null: true, description: "Something"

  field :ok_field, String

  field :also_ok_field, String, null: false
end
