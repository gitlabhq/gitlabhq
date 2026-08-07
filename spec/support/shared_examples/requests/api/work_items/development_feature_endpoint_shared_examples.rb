# frozen_string_literal: true

# Shared behaviour for the Work Item development-widget sub-endpoints
# (closing_merge_requests, related_merge_requests, related_branches, ...).
#
# It covers the invariant behaviour every such endpoint shares: work-item lookup,
# feature-flag gating, pagination, and N+1 safety. The feature-specific payload
# assertions stay inline in each request spec.
#
# The including context must define:
#   - `api_request_path`  the endpoint path, containing "/<work_item.iid>/"
#   - `work_item`         the parent work item
#   - `user`              a user who can read the work item
#   - `expected_total`    the number of records the happy-path request returns
#   - `add_development_feature_record` a method that creates one more visible record
#                          (used to prove the endpoint does not N+1 as the collection grows)
#   - `n_plus_one_threshold` queries tolerated on top of the control. Use 0 for light entities;
#                          heavy entities such as MergeRequestBasic reuse the core /merge_requests
#                          API's threshold (3) to absorb their irreducible per-record queries.
RSpec.shared_examples 'a work item development feature endpoint' do
  it 'returns 404 when the work item does not exist' do
    get api(api_request_path.sub("/#{work_item.iid}/", "/#{non_existing_record_iid}/"), user)

    expect(response).to have_gitlab_http_status(:not_found)
  end

  it 'returns forbidden when the work_item_rest_api feature flag is disabled' do
    stub_feature_flags(work_item_rest_api: false)

    get api(api_request_path, user)

    expect(response).to have_gitlab_http_status(:forbidden)
  end

  it 'paginates the response' do
    get api(api_request_path, user), params: { per_page: 1 }

    expect(response).to have_gitlab_http_status(:ok)
    expect(json_response.size).to eq(1)
    expect(response.headers['X-Total']).to eq(expected_total.to_s)
  end

  # Mirrors spec/requests/api/merge_requests_spec.rb: :use_sql_query_cache collapses repeated
  # identical queries and the per-spec `n_plus_one_threshold` absorbs the entity's irreducible
  # per-record queries, so a real N+1 (linear growth) still trips the limit.
  it 'avoids N+1 queries as the collection grows', :request_store, :use_sql_query_cache, :aggregate_failures do
    # Warm up so first-request lazy writes (e.g. Users::ActivityService) do not skew the baseline.
    get api(api_request_path, user)

    control = ActiveRecord::QueryRecorder.new(skip_cached: false) do
      get api(api_request_path, user)
    end

    add_development_feature_record

    expect { get api(api_request_path, user) }
      .not_to exceed_query_limit(control).allow_skip_cache_inconsistency.with_threshold(n_plus_one_threshold)
    expect(response).to have_gitlab_http_status(:ok)
  end
end
