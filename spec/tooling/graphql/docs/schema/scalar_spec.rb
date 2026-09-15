# frozen_string_literal: true

require 'spec_helper'

require Rails.root.join('tooling/graphql/docs/schema/scalar')

RSpec.describe Tooling::Graphql::Docs::Schema::Scalar, feature_category: :api do
  let_it_be(:mock_scalar) do
    Class.new(Types::BaseScalar) do
      graphql_name 'MockScalar'
      description 'Scalar description'
    end
  end

  subject(:scalar) { described_class.new(mock_scalar) }

  it 'has correct properties' do
    expect(scalar).to have_attributes(
      name: 'MockScalar',
      description: 'Scalar description'
    )
  end
end
