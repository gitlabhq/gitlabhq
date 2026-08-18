# frozen_string_literal: true

require 'spec_helper'

require Rails.root.join('tooling/graphql/docs/schema/enum')

RSpec.describe Tooling::Graphql::Docs::Schema::Enum, feature_category: :api do
  let_it_be(:mock_enum) do
    Class.new(Types::BaseEnum) do
      graphql_name 'MockEnum'
      description 'Enum description'
      value 'ACTIVE', 'An active value.', value: :active
    end
  end

  subject(:enum) { described_class.new(mock_enum) }

  it 'has correct properties' do
    expect(enum).to have_attributes(
      name: 'MockEnum',
      description: 'Enum description',
      values: contain_exactly(kind_of(Tooling::Graphql::Docs::Schema::EnumValue))
    )
  end
end
