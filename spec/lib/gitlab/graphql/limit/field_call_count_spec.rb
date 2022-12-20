# frozen_string_literal: true
require 'spec_helper'

RSpec.describe Gitlab::Graphql::Limit::FieldCallCount do
  include GraphqlHelpers

  let(:field_args) { {} }
  let(:owner) { fresh_object_type }
  let(:field) do
    ::Types::BaseField.new(name: 'value', type: GraphQL::Types::String, null: true, owner: owner) do
      extension(::Gitlab::Graphql::Limit::FieldCallCount, limit: 1)
    end
  end

  let(:query) do
    GraphQL::Query.new(GitlabSchema)
  end

  def resolve_value
    resolve_field(field, { value: 'foo' }, object_type: owner, query: query)
  end

  it 'allows the call' do
    expect { resolve_value }.not_to raise_error
  end

  it 'executes the extension' do
    expect(described_class).to receive(:new).and_call_original

    resolve_value
  end

  it 'returns an error when the field is called multiple times' do
    resolve_value

    expect(resolve_value).to be_an_instance_of(Gitlab::Graphql::Errors::LimitError)
  end

  it 'does not return an error when the field is called multiple times in separte queries' do
    query_1 = GraphQL::Query.new(GitlabSchema)
    query_2 = GraphQL::Query.new(GitlabSchema)

    resolve_field(field, { value: 'foo' }, object_type: owner, query: query_1)

    expect { resolve_field(field, { value: 'foo' }, object_type: owner, query: query_2) }.not_to raise_error
  end

  context 'when limit is not specified' do
    let(:field) do
      ::Types::BaseField.new(name: 'value', type: GraphQL::Types::String, null: true, owner: owner) do
        extension(::Gitlab::Graphql::Limit::FieldCallCount)
      end
    end

    it 'returns an error' do
      expect(resolve_value).to be_an_instance_of(Gitlab::Graphql::Errors::ArgumentError)
    end
  end

  context 'when the field is not extended' do
    let(:field) do
      ::Types::BaseField.new(name: 'value', type: GraphQL::Types::String, null: true, owner: owner)
    end

    it 'allows the call' do
      expect { resolve_value }.not_to raise_error
    end

    it 'does not execute the extension' do
      expect(described_class).not_to receive(:new)

      resolve_value
    end
  end
end
