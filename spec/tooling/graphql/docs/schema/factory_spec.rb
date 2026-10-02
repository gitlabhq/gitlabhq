# frozen_string_literal: true

require 'spec_helper'

require Rails.root.join('tooling/graphql/docs/schema/factory')

RSpec.describe Tooling::Graphql::Docs::Schema::Factory, feature_category: :api do
  describe '.wrap' do
    context 'with a union type' do
      let(:union_type) do
        member = Class.new(Types::BaseObject) do
          graphql_name 'Member'
          field :id, GraphQL::Types::ID, null: true
        end

        Class.new(Types::BaseUnion) do
          graphql_name 'Union'
          possible_types member
        end
      end

      it 'wraps it as a Union' do
        expect(described_class.wrap(union_type)).to be_a(Tooling::Graphql::Docs::Schema::Union)
      end
    end

    context 'with a kind that has no docs schema class' do
      it 'raises an error' do
        expect { described_class.wrap(GraphQL::Types::String.to_list_type) }
          .to raise_error(described_class::UnknownKindError, /LIST/)
      end
    end
  end
end
