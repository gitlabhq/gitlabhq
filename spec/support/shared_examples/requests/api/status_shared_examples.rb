# frozen_string_literal: true

# Specs for status checking.
#
# Requires an API request:
#   let(:request) { get api("/projects/#{project.id}/repository/branches", user) }
RSpec.shared_examples '400 response' do
  let(:message) { nil }

  before do
    # Fires the request
    request
  end

  it 'returns 400' do
    expect(response).to have_gitlab_http_status(:bad_request)

    if message.present?
      expect(json_response['message']).to eq(message)
    end
  end
end

RSpec.shared_examples '401 response' do
  let(:message) { nil }

  before do
    # Fires the request
    request
  end

  it 'returns 401' do
    expect(response).to have_gitlab_http_status(:unauthorized)

    if message.present?
      expect(json_response['message']).to eq(message)
    end
  end
end

RSpec.shared_examples '403 response' do
  before do
    # Fires the request
    request
  end

  it 'returns 403' do
    expect(response).to have_gitlab_http_status(:forbidden)
  end
end

RSpec.shared_examples '404 response' do
  let(:message) { nil }

  before do
    # Fires the request
    request
  end

  it 'returns 404' do
    expect(response).to have_gitlab_http_status(:not_found)
    expect(json_response).to be_an Object

    if message.present?
      expect(json_response['message']).to eq(message)
    end
  end
end

RSpec.shared_examples '412 response' do
  let(:params) { nil }
  let(:success_status) { 204 }

  context 'for a modified resource' do
    before do
      delete request, params: params, headers: { 'HTTP_IF_UNMODIFIED_SINCE' => '1990-01-12T00:00:48-0600' }
    end

    it 'returns 412 with a JSON error' do
      expect(response).to have_gitlab_http_status(:precondition_failed)
      expect(json_response).to eq('message' => '412 Precondition Failed')
    end
  end

  context 'for an unmodified resource' do
    before do
      delete request, params: params, headers: { 'HTTP_IF_UNMODIFIED_SINCE' => Time.now }
    end

    it 'returns 204 with an empty body' do
      expect(response).to have_gitlab_http_status(success_status)
      expect(response.body).to eq('') if success_status == 204
    end
  end
end

RSpec.shared_examples '422 response' do
  let(:message) { nil }

  before do
    # Fires the request
    request
  end

  it 'returns 422' do
    expect(response).to have_gitlab_http_status(:unprocessable_entity)
    expect(json_response).to be_an Object

    if message.present?
      expect(json_response['message']).to eq(message)
    end
  end
end

RSpec.shared_examples '503 response' do
  before do
    # Fires the request
    request
  end

  it 'returns 503' do
    expect(response).to have_gitlab_http_status(:service_unavailable)
  end
end
