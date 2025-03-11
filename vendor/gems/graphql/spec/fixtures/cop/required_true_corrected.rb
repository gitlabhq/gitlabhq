class Types::Something < Types::BaseObject
  field :name, String do
    argument :id_1, ID

    argument :id_2,
      ID,
      description: "Described"

    argument :id_3, ID, other_config: { something: false, required: true }, description: "Something"

    argument :id_4, ID, required: false

    argument :id_5, ID
  end

  field :name2, String do |f|
    f.argument(:id_1, ID)
  end
end
