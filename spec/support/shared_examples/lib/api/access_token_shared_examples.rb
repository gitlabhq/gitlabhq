# frozen_string_literal: true

# The context in which these shared examples are included
# need to have the following variables/objects available
#
# - `path` - The path of the specific token API not including
#          `/api/v4`.
#          Example: '/groups/:id/manage/personal_access_tokens'
# - `current_user_token` - The PAT of the user making the request
# - All tokens in the `all_token_ids` variable below.
# - `created_at_asc` - An array of tokens in ascending order of creation date
#
# It is recommended to create one or more tokens that should not match any of the filters.
# For example, if testing resource access tokens, create a human user token and
# service account token. The variable name does not matter as long as it
# isn't one of the `all_token_ids` below.
RSpec.shared_examples 'an access token GET API with access token params' do
  let(:api_request) { api(path, personal_access_token: current_user_token) }
  let_it_be(:created_at_desc) { created_at_asc.reverse }
  let_it_be(:all_token_ids) do
    [
      active_token1.id,
      active_token2.id,
      expired_token1.id,
      expired_token2.id,
      revoked_token1.id,
      revoked_token2.id,
      named_token.id,
      created_2_days_ago_token.id,
      last_used_2_days_ago_token.id,
      last_used_2_months_ago_token.id
    ]
  end

  it 'returns all tokens by default' do
    get api_request

    expect(response).to have_gitlab_http_status(:ok)
    expect_paginated_array_response_contain_exactly(*all_token_ids)
    # Entities::PersonalAccessToken default response
    expect(json_response[0].keys).to include(
      'id', 'name', 'description', 'revoked', 'created_at', 'scopes', 'user_id', 'last_used_at', 'active', 'expires_at'
    )
  end

  context 'when filtering by state' do
    it 'returns active tokens when state is active' do
      get api_request, params: { state: 'active' }

      expect_paginated_array_response_contain_exactly(
        *all_token_ids.excluding(expired_token1.id, expired_token2.id, revoked_token1.id, revoked_token2.id)
      )
    end

    it 'returns inactive tokens when state is inactive' do
      get api_request, params: { state: 'inactive' }

      expect_paginated_array_response_contain_exactly(
        expired_token1.id, expired_token2.id, revoked_token1.id, revoked_token2.id
      )
    end

    it 'returns bad request when state is invalid' do
      get api(path, personal_access_token: current_user_token), params: { state: 'invalid' }

      expect(response).to have_gitlab_http_status(:bad_request)
      expect(json_response['error']).to eq('state does not have a valid value')
    end
  end

  context 'when filtering by revoked' do
    it 'returns not-revoked tokens when revoked is false' do
      get api_request, params: { revoked: false }

      expect_paginated_array_response_contain_exactly(*all_token_ids.excluding(revoked_token1.id, revoked_token2.id))
    end

    it 'returns revoked tokens when revoked is true' do
      get api_request, params: { revoked: true }

      expect_paginated_array_response_contain_exactly(revoked_token1.id, revoked_token2.id)
    end
  end

  context 'when filtering by created dates' do
    it 'returns tokens created before specified date' do
      get api_request, params: { created_before: 1.day.ago }

      expect(json_response.pluck('id')).to match_array(created_2_days_ago_token.id)
    end

    it 'returns tokens created after specified date' do
      get api_request, params: { created_after: 1.day.ago }

      expect_paginated_array_response_contain_exactly(*all_token_ids.excluding(created_2_days_ago_token.id))
    end
  end

  context 'when filtering by last used dates' do
    it 'returns tokens last used before specified date' do
      get api_request, params: { last_used_before: Time.current }

      expect_paginated_array_response_contain_exactly(last_used_2_days_ago_token.id, last_used_2_months_ago_token.id)
    end

    it 'returns tokens last used after specified date' do
      get api_request, params: { last_used_after: 1.week.ago }

      expect_paginated_array_response_contain_exactly(last_used_2_days_ago_token.id)
    end
  end

  context 'when searching by name' do
    it 'returns tokens matching the search term' do
      get api_request, params: { search: 'test' }

      expect_paginated_array_response_contain_exactly(named_token.id)
    end
  end

  context 'when sorting' do
    it 'sorts tokens by created_at_desc when specified' do
      get api_request, params: { sort: 'created_at_desc' }

      expect(response).to have_gitlab_http_status(:ok)
      expect(json_response.pluck('id')).to eq(created_at_desc.pluck('id')) # Use eq because order is important
    end

    it 'sorts tokens by created_at_asc when specified' do
      get api_request, params: { sort: 'created_at_asc' }

      expect(response).to have_gitlab_http_status(:ok)
      expect(json_response.pluck('id')).to eq(created_at_asc.pluck('id')) # Use eq because order is important
    end
  end
end
