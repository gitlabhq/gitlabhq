# frozen_string_literal: true

require 'spec_helper'

require Rails.root.join('tooling/graphql/docs/schema/input_object')

RSpec.describe Tooling::Graphql::Docs::Schema::InputObject, feature_category: :api do
  let_it_be(:mock_input_object) do
    Class.new(Types::BaseInputObject) do
      description 'Input object description'
      graphql_name 'MockInputObject'
      argument :my_arg, String
    end
  end

  subject(:input_object) { described_class.new(mock_input_object) }

  it 'has correct properties' do
    expect(input_object).to have_attributes(
      name: 'MockInputObject',
      description: 'Input object description',
      arguments: contain_exactly(kind_of(Tooling::Graphql::Docs::Schema::Argument))
    )
  end

  context 'without arguments' do
    subject(:input_object) { described_class.new(mock_input_object, with_arguments: false) }

    it 'has no arguments' do
      expect(input_object.arguments).to be_nil
    end
  end
end
