# frozen_string_literal: true

require 'spec_helper'

require Rails.root.join('tooling/graphql/docs/schema/enum_value')

RSpec.describe Tooling::Graphql::Docs::Schema::EnumValue, feature_category: :api do
  let_it_be(:mock_enum) do
    Class.new(Types::BaseEnum) do
      graphql_name 'MockEnum'
      value 'ACTIVE', 'An active value.', value: :active
    end
  end

  let(:enum_values) { mock_enum.enum_values }

  subject(:enum_value) { described_class.new(enum_values.find { |value| value.graphql_name == 'ACTIVE' }) }

  it 'has correct properties' do
    expect(enum_value).to have_attributes(
      name: 'ACTIVE',
      value: :active,
      experiment?: false,
      deprecated?: false,
      deprecation: nil,
      description: 'An active value.'
    )
  end

  it_behaves_like Tooling::Graphql::Docs::Schema::Deprecable do
    let_it_be(:mock_enum) do
      Class.new(Types::BaseEnum) do
        graphql_name 'MockDeprecableEnum'
        value 'EXPERIMENTAL', 'An experimental enum value.', experiment: { milestone: '16.0' }
        value 'DEPRECATED', 'A deprecated enum value.', deprecated: { milestone: '16.0', reason: 'Deprecated' }
      end
    end

    let(:experimental_item) do
      described_class.new(enum_values.find { |value| value.graphql_name == 'EXPERIMENTAL' })
    end

    let(:deprecated_item) do
      described_class.new(enum_values.find { |value| value.graphql_name == 'DEPRECATED' })
    end
  end
end
