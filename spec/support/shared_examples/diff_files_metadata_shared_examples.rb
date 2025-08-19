# frozen_string_literal: true

RSpec.shared_examples 'diff files metadata' do
  it 'returns a json response' do
    send_request

    expect(response).to have_gitlab_http_status(:success)
    expect(json_response['diff_files']).to be_an Array
  end
end

RSpec.shared_examples 'missing diff files metadata' do
  it 'returns a 404 status' do
    send_request

    expect(response).to have_gitlab_http_status(:not_found)
  end
end
