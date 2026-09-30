# frozen_string_literal: true

require 'spec_helper'

# The frontend sends eTag-cached GraphQL queries as POST to avoid URL length limits,
# so this protects the (non-standard) 304 response to a POST through the full middleware stack.
RSpec.describe 'GraphQL eTag caching', :clean_gitlab_redis_shared_state, :clean_gitlab_redis_cache, feature_category: :continuous_integration do
  include GraphqlHelpers

  let_it_be(:project) { create(:project, :public) }
  let_it_be(:user) { create(:user, developer_of: project) }

  let(:resource) { "/api/graphql:project_pipelines/#{project.id}" }
  let(:query) { graphql_query_for(:project, { full_path: project.full_path }, :id) }

  def post_etag_query(if_none_match: nil)
    headers = { 'X-GITLAB-GRAPHQL-RESOURCE-ETAG' => resource }
    headers['If-None-Match'] = if_none_match if if_none_match

    post api('/', user, version: 'graphql'), params: { query: query }, headers: headers
  end

  it 'returns 304 for a POST whose If-None-Match matches, and 200 once the resource changes', :aggregate_failures do
    post_etag_query

    expect(response).to have_gitlab_http_status(:ok)
    expect(graphql_data_at(:project, :id)).to eq(project.to_global_id.to_s)

    etag = response.headers['ETag']
    expect(etag).to be_present

    post_etag_query(if_none_match: etag)

    expect(response).to have_gitlab_http_status(:not_modified)
    expect(response.headers).to include('ETag' => etag, 'X-Gitlab-From-Cache' => 'true')
    expect(response.body).to be_empty

    Gitlab::EtagCaching::Store.new.touch(resource)

    post_etag_query(if_none_match: etag)

    expect(response).to have_gitlab_http_status(:ok)
    expect(response.headers['ETag']).to be_present
    expect(response.headers['ETag']).not_to eq(etag)
  end
end
