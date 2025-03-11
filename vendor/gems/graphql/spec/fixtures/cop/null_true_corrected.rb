class Types::Something < Types::BaseObject
  field :name, String

  field :other_name, String,
    description: "Here's a description"

  field :described, [String, null: true], description: "Something"

  field :ok_field, String

  field :also_ok_field, String, null: false
end
