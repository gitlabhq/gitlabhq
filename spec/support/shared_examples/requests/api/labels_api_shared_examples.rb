# frozen_string_literal: true

RSpec.shared_examples 'fetches labels' do
  it 'returns correct labels' do
    request

    expect(response).to have_gitlab_http_status(:ok)
    expect(response).to include_pagination_headers
    expect(json_response).to be_an Array
    expect(json_response).to all(match_schema('public_api/v4/labels/label'))
    expect(json_response.size).to eq(expected_labels.size)
    expect(json_response.pluck('name')).to match_array(expected_labels)
  end
end
