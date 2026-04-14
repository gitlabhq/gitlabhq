# frozen_string_literal: true

DEFAULT_PARITY_EXCEPTIONS = Set.new(%w[type]).freeze

RSpec.shared_examples 'work item widget entity parity' do |entity_class, graphql_type, exceptions: []|
  let(:rest_field_names) do
    if entity_class.respond_to?(:root_exposures)
      entity_class.root_exposures.map { |exposure| exposure.key.to_s }.to_set
    else
      Set.new
    end
  end

  let(:graphql_field_names) do
    type = graphql_type.is_a?(String) ? graphql_type.constantize : graphql_type
    Set.new(type.fields.keys.map(&:underscore))
  end

  it 'exposes the same fields as the GraphQL widget type' do
    expect(rest_field_names).to match_array(graphql_field_names - DEFAULT_PARITY_EXCEPTIONS - exceptions)
  end
end
