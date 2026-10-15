# frozen_string_literal: true

# Requires `api_request_path` and `user`. The unpaginated response must hold at least two records, and every
# record on the first page must be readable by `user`: pagination runs before the policy filter, so an unreadable
# record there shortens the page and breaks the `all_ids.first(page_size)` comparison.
RSpec.shared_examples 'a work item endpoint paginated by cursor' do
  let(:all_ids) do
    get api(api_request_path, user)
    json_response.pluck('id')
  end

  let(:page_size) { all_ids.size - 1 }

  it 'pages through the collection with X-Next-Cursor and emits no offset headers' do
    expect(all_ids.size).to be >= 2

    get api(api_request_path, user), params: { per_page: page_size }

    expect(response).to have_gitlab_http_status(:ok)
    expect(json_response.pluck('id')).to eq(all_ids.first(page_size))
    expect(response.headers['X-Next-Cursor']).to be_present
    expect(response.headers).not_to include('X-Total', 'X-Total-Pages', 'X-Page', 'X-Next-Page', 'X-Prev-Page',
      'X-Per-Page')

    get api(api_request_path, user), params: { per_page: page_size, cursor: response.headers['X-Next-Cursor'] }

    expect(response).to have_gitlab_http_status(:ok)
    expect(json_response.pluck('id')).to eq(all_ids.last(1))
    expect(response.headers['X-Next-Cursor']).to be_nil
  end

  it 'ignores the page parameter' do
    get api(api_request_path, user), params: { per_page: page_size, page: 2 }

    expect(response).to have_gitlab_http_status(:ok)
    expect(json_response.pluck('id')).to eq(all_ids.first(page_size))
  end

  it 'returns 400 when per_page is outside 1..100' do
    [0, -1, 101].each do |per_page|
      get api(api_request_path, user), params: { per_page: per_page }

      expect(response).to have_gitlab_http_status(:bad_request)
      expect(json_response['error']).to include('per_page')
    end
  end
end
