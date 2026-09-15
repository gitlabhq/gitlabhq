# frozen_string_literal: true

require 'spec_helper'

require Rails.root.join('tooling/graphql/docs/schema/directive')

RSpec.describe Tooling::Graphql::Docs::Schema::Directive, feature_category: :api do
  let_it_be(:mock_directive) do
    Class.new(GraphQL::Schema::Directive) do
      graphql_name 'mockDirective'
      description 'Directive description'
      locations(:INLINE_FRAGMENT, :FIELD)

      argument :directive_argument, GraphQL::Types::String, description: 'A directive argument.', required: false
    end
  end

  subject(:directive) { described_class.new(mock_directive) }

  it 'has correct properties' do
    expect(directive).to have_attributes(
      item: mock_directive,
      name: 'mockDirective',
      description: 'Directive description',
      locations: %w[FIELD INLINE_FRAGMENT],
      arguments: contain_exactly(kind_of(Tooling::Graphql::Docs::Schema::Argument))
    )
  end

  describe '#repeatable?' do
    it 'is false by default' do
      expect(directive).not_to be_repeatable
    end

    context 'when the directive is repeatable' do
      let_it_be(:mock_directive) do
        Class.new(GraphQL::Schema::Directive) do
          graphql_name 'mockRepeatableDirective'
          repeatable true
          locations(:FIELD)
        end
      end

      it 'is true' do
        expect(directive).to be_repeatable
      end
    end
  end
end
