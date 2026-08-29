# frozen_string_literal: true

require 'spec_helper'

require Rails.root.join('tooling/graphql/docs/schema/argument')

RSpec.describe Tooling::Graphql::Docs::Schema::Argument, feature_category: :api do
  let_it_be(:mock_input_object) do
    Class.new(Types::BaseInputObject) do
      graphql_name 'MockInputObject'

      argument :my_arg, GraphQL::Types::String, description: 'An argument.'
      argument :experimental, GraphQL::Types::String, required: false, experiment: { milestone: '16.0' }
      argument :deprecated, GraphQL::Types::String, required: false, deprecated: { milestone: '16.0', reason: 'Deprecated' }
    end
  end

  let(:arguments) { mock_input_object.arguments }

  subject(:argument) { described_class.new(arguments['myArg']) }

  it 'has correct properties' do
    expect(argument).to have_attributes(
      item: kind_of(Types::BaseArgument),
      name: 'myArg',
      description: 'An argument.'
    )
  end

  it_behaves_like Tooling::Graphql::Docs::Schema::Deprecable do
    let(:experimental_item) { described_class.new(arguments['experimental']) }
    let(:deprecated_item) { described_class.new(arguments['deprecated']) }
  end
end
