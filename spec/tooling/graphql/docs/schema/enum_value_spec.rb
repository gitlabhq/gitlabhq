# frozen_string_literal: true

require 'spec_helper'

require Rails.root.join('tooling/graphql/docs/schema/enum_value')

RSpec.describe Tooling::Graphql::Docs::Schema::EnumValue, feature_category: :api do
  let_it_be(:mock_enum) do
    Class.new(Types::BaseEnum) do
      graphql_name 'MockEnum'
      value 'ENUM_VALUE', 'An enum value.', value: :enum_value
      value 'EXPERIMENTAL', 'An experimental enum value.', experiment: { milestone: '16.0' }
      value 'DEPRECATED', 'A deprecated enum value.', deprecated: { milestone: '16.0', reason: 'Deprecated' }
    end
  end

  let(:values) { mock_enum.values }

  subject(:enum_value) { described_class.new(values['ENUM_VALUE']) }

  it 'has correct properties' do
    expect(enum_value).to have_attributes(
      item: kind_of(Types::BaseEnum::CustomValue),
      name: 'ENUM_VALUE',
      value: :enum_value,
      description: 'An enum value.'
    )
  end

  it_behaves_like Tooling::Graphql::Docs::Schema::Deprecable do
    let(:experimental_item) { described_class.new(values['EXPERIMENTAL']) }
    let(:deprecated_item) { described_class.new(values['DEPRECATED']) }
  end
end
