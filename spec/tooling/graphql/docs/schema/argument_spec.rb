# frozen_string_literal: true

require 'spec_helper'

require Rails.root.join('tooling/graphql/docs/schema/argument')

RSpec.describe Tooling::Graphql::Docs::Schema::Argument, feature_category: :api do
  let_it_be(:enum_type) do
    Class.new(Types::BaseEnum) do
      graphql_name 'MockArgumentEnum'
      value 'FIRST', 'First.', value: :first
      value 'SECOND', 'Second.', value: :second
    end
  end

  let_it_be(:mock_input_object) do
    an_enum = enum_type

    Class.new(Types::BaseInputObject) do
      graphql_name 'MockInputObject'

      argument :my_arg, GraphQL::Types::String, description: 'An argument.'
      argument :experimental, GraphQL::Types::String, required: false, experiment: { milestone: '16.0' }
      argument :deprecated, GraphQL::Types::String, required: false, deprecated: { milestone: '16.0', reason: 'Deprecated' }
      argument :with_string_default, GraphQL::Types::String, required: false,
        description: 'A string default.', default_value: 'the default'
      argument :with_boolean_default, GraphQL::Types::Boolean, required: false,
        description: 'A boolean default.', default_value: false
      argument :with_enum_default, an_enum, required: false,
        description: 'An enum default.', default_value: :first
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

  describe '#default_value?' do
    it 'is false when the argument has no default' do
      expect(described_class.new(arguments['myArg'])).not_to be_default_value
    end

    it 'is true when the argument has a default' do
      expect(described_class.new(arguments['withStringDefault'])).to be_default_value
    end
  end

  describe '#default_value' do
    it 'is nil when the argument has no default' do
      expect(described_class.new(arguments['myArg']).default_value).to be_nil
    end

    it 'renders a string default as a quoted GraphQL literal' do
      expect(described_class.new(arguments['withStringDefault']).default_value).to eq('"the default"')
    end

    it 'renders a boolean default' do
      expect(described_class.new(arguments['withBooleanDefault']).default_value).to eq('false')
    end

    it 'renders an enum default as an unquoted enum name' do
      expect(described_class.new(arguments['withEnumDefault']).default_value).to eq('FIRST')
    end
  end

  it_behaves_like Tooling::Graphql::Docs::Schema::Deprecable do
    let(:experimental_item) { described_class.new(arguments['experimental']) }
    let(:deprecated_item) { described_class.new(arguments['deprecated']) }
  end
end
