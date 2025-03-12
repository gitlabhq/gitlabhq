# frozen_string_literal: true
require "spec_helper"
require "generators/graphql/enum_generator"

class GraphQLGeneratorsEnumGeneratorTest < BaseGeneratorTest
  tests Graphql::Generators::EnumGenerator

  test "it generate enums with values" do
    expected_content = <<-RUBY
# frozen_string_literal: true

module Types
  class FamilyType < Types::BaseEnum
    description "Family enum"

    value "NIGHTSHADE"
    value "BRASSICA", value: Family::COLE
    value "UMBELLIFER", value: :umbellifer
    value "LEGUME", value: "bean & friends"
    value "CURCURBITS", value: 5
  end
end
RUBY

    run_generator(["Family",
      "NIGHTSHADE",
      "BRASSICA:Family::COLE",
      "UMBELLIFER::umbellifer",
      'LEGUME:"bean & friends"',
      "CURCURBITS:5"
    ])
    assert_file "app/graphql/types/family_type.rb", expected_content
  end

  test "it generates namespaced enums with values" do
    expected_content = <<-RUBY
# frozen_string_literal: true

module Types
  class Enums::FamilyType < Types::BaseEnum
    description "Family enum"

    value "NIGHTSHADE"
    value "BRASSICA", value: Family::COLE
    value "UMBELLIFER", value: :umbellifer
    value "LEGUME", value: "bean & friends"
    value "CURCURBITS", value: 5
  end
end
RUBY

    run_generator(["Family",
      "NIGHTSHADE",
      "BRASSICA:Family::COLE",
      "UMBELLIFER::umbellifer",
      'LEGUME:"bean & friends"',
      "CURCURBITS:5",
      "--namespaced-types"
    ])
    assert_file "app/graphql/types/enums/family_type.rb", expected_content
  end
end
