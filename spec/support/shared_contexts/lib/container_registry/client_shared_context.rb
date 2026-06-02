# frozen_string_literal: true

RSpec.shared_context 'container registry client' do
  let(:token) { '12345' }
  let(:options) { { token: token } }
  let(:registry_api_url) { 'http://container-registry' }
  let(:client) { described_class.new(registry_api_url, options) }
  let(:accept_header) { ContainerRegistry::Client::ACCEPTED_TYPES.join(', ') }

  let(:push_blob_headers) do
    {
      'Accept' => accept_header,
      'Authorization' => "bearer #{token}",
      'Content-Type' => 'application/octet-stream',
      'User-Agent' => "GitLab/#{Gitlab::VERSION}"
    }
  end

  let(:headers_with_accept_types) do
    {
      'Accept' => accept_header,
      'Authorization' => "bearer #{token}",
      'User-Agent' => "GitLab/#{Gitlab::VERSION}"
    }
  end

  let(:expected_faraday_headers) { { user_agent: "GitLab/#{Gitlab::VERSION}" } }
  let(:expected_faraday_request_options) { Gitlab::HTTP::DEFAULT_TIMEOUT_OPTIONS }
end
