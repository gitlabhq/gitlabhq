# frozen_string_literal: true
require 'spec_helper'

RSpec.describe 'getting a repository in a project' do
  include GraphqlHelpers

  let_it_be(:project) { create(:project) }
  let_it_be(:current_user) { project.owner }
  let_it_be(:container_expiration_policy) { project.container_expiration_policy }

  let(:fields) do
    <<~QUERY
      #{all_graphql_fields_for('container_expiration_policy'.classify)}
    QUERY
  end

  let(:query) do
    graphql_query_for(
      'project',
      { 'fullPath' => project.full_path },
      query_graphql_field('containerExpirationPolicy', {}, fields)
    )
  end

  before do
    stub_config(registry: { enabled: true })
    post_graphql(query, current_user: current_user)
  end

  it_behaves_like 'a working graphql query'
end
