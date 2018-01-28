# Specs for status checking.
#
# Requires an API request:
#   let(:request) { get api("/projects/#{project.id}/repository/branches", user) }
shared_examples_for '400 response' do
  let(:message) { nil }

  before do
    # Fires the request
    request
  end

  it 'returns 400' do
    expect(response).to have_gitlab_http_status(400)

    if message.present?
      expect(json_response['message']).to eq(message)
    end
  end
end

shared_examples_for '403 response' do
  before do
    # Fires the request
    request
  end

  it 'returns 403' do
    expect(response).to have_gitlab_http_status(403)
  end
end

shared_examples_for '404 response' do
  let(:message) { nil }

  before do
    # Fires the request
    request
  end

  it 'returns 404' do
    expect(response).to have_gitlab_http_status(404)
    expect(json_response).to be_an Object

    if message.present?
      expect(json_response['message']).to eq(message)
    end
  end
end

shared_examples_for '412 response' do
  let(:params) { nil }
  let(:success_status) { 204 }

  context 'for a modified ressource' do
    before do
      delete request, params, { 'HTTP_IF_UNMODIFIED_SINCE' => '1990-01-12T00:00:48-0600' }
    end

    it 'returns 412' do
      expect(response).to have_gitlab_http_status(412)
    end
  end

  context 'for an unmodified ressource' do
    before do
      delete request, params, { 'HTTP_IF_UNMODIFIED_SINCE' => Time.now }
    end

    it 'returns accepted' do
      expect(response).to have_gitlab_http_status(success_status)
    end
  end
end
