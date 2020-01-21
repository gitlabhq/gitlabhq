# frozen_string_literal: true

RSpec.shared_examples 'LFS http 200 response' do
  it_behaves_like 'LFS http expected response code and message' do
    let(:response_code) { 200 }
  end
end

RSpec.shared_examples 'LFS http 401 response' do
  it_behaves_like 'LFS http expected response code and message' do
    let(:response_code) { 401 }
  end
end

RSpec.shared_examples 'LFS http 403 response' do
  it_behaves_like 'LFS http expected response code and message' do
    let(:response_code) { 403 }
    let(:message) { 'Access forbidden. Check your access level.' }
  end
end

RSpec.shared_examples 'LFS http 501 response' do
  it_behaves_like 'LFS http expected response code and message' do
    let(:response_code) { 501 }
    let(:message) { 'Git LFS is not enabled on this GitLab server, contact your admin.' }
  end
end

RSpec.shared_examples 'LFS http 404 response' do
  it_behaves_like 'LFS http expected response code and message' do
    let(:response_code) { 404 }
  end
end

RSpec.shared_examples 'LFS http expected response code and message' do
  let(:response_code) { }
  let(:message) { }

  it 'responds with the expected response code and message' do
    expect(response).to have_gitlab_http_status(response_code)
    expect(json_response['message']).to eq(message) if message
  end
end
