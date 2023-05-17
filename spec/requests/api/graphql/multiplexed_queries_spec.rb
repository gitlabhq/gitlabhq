# frozen_string_literal: true
require 'spec_helper'

RSpec.describe 'Multiplexed queries', feature_category: :shared do
  include GraphqlHelpers

  it 'returns responses for multiple queries' do
    queries = [
      { query: 'query($text: String!) { echo(text: $text) }',
        variables: { 'text' => 'Hello' } },
      { query: 'query($text: String!) { echo(text: $text) }',
        variables: { 'text' => 'World' } }
    ]

    post_multiplex(queries)

    first_response = json_response.first['data']['echo']
    second_response = json_response.last['data']['echo']

    expect(first_response).to eq('nil says: Hello')
    expect(second_response).to eq('nil says: World')
  end

  it 'returns error and data combinations' do
    queries = [
      { query: 'query($text: String!) { broken query }' },
      { query: 'query working($text: String!) { echo(text: $text) }',
        variables: { 'text' => 'World' } }
    ]

    post_multiplex(queries)

    first_response = json_response.first['errors']
    second_response = json_response.last['data']['echo']

    expect(first_response).not_to be_empty
    expect(second_response).to eq('nil says: World')
  end
end
