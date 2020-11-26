# frozen_string_literal: true

require 'spec_helper'

RSpec.describe ::Graphql::Var do
  subject(:var) { described_class.new('foo', 'Int') }

  it 'associates a name with a type and an initially empty value' do
    expect(var).to have_attributes(
      name: 'foo',
      type: 'Int',
      value: be_nil
    )
  end

  it 'has a correct signature' do
    expect(var).to have_attributes(sig: '$foo: Int')
  end

  it 'implements to_graphql_value as $name' do
    expect(var.to_graphql_value).to eq('$foo')
  end

  it 'can set a value using with, returning a new object' do
    with_value = var.with(42)

    expect(with_value).to have_attributes(name: 'foo', type: 'Int', value: 42)
    expect(var).to have_attributes(value: be_nil)
  end

  it 'returns an object suitable for passing to post_graphql(variables:)' do
    expect(var.with(17).to_h).to eq('foo' => 17)
  end
end
