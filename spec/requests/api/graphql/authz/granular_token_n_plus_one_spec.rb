# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'granular token authorization N+1', feature_category: :permissions do
  include GraphqlHelpers

  let_it_be(:user) { create(:user) }

  let_it_be(:granular_pat) do
    create(:granular_pat,
      user: user,
      boundary: ::Authz::Boundary.for(:all_memberships),
      permissions: [:read_project]
    )
  end

  let(:query) { graphql_query_for(:projects, {}, 'nodes { id }') }

  it 'avoids N+1 queries when authorizing multiple projects', :request_store, :use_sql_query_cache do
    create(:project, :private, developers: user)

    post_graphql(query, token: { personal_access_token: granular_pat }) # warm-up

    control = ActiveRecord::QueryRecorder.new(skip_cached: false) do
      post_graphql(query, token: { personal_access_token: granular_pat })
    end

    create_list(:project, 3, :private, developers: user)

    expect do
      post_graphql(query, token: { personal_access_token: granular_pat })
    end.to issue_same_number_of_queries_as(control)
  end
end
