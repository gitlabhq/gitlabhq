# frozen_string_literal: true

# Requires sentry_api_request and subject to be defined
RSpec.shared_examples 'calls sentry api' do
  it 'calls sentry api' do
    subject

    expect(sentry_api_request).to have_been_requested
  end
end

# Requires sentry_api_url and subject to be defined
RSpec.shared_examples 'no Sentry redirects' do
  let(:redirect_to) { 'https://redirected.example.com' }
  let(:other_url) { 'https://other.example.org' }

  let!(:redirected_req_stub) { stub_sentry_request(other_url) }

  let!(:redirect_req_stub) do
    stub_sentry_request(
      sentry_api_url,
      status: 302,
      headers: { location: redirect_to }
    )
  end

  it 'does not follow redirects' do
    expect { subject }.to raise_exception(Sentry::Client::Error, 'Sentry response status code: 302')
    expect(redirect_req_stub).to have_been_requested
    expect(redirected_req_stub).not_to have_been_requested
  end
end

RSpec.shared_examples 'maps Sentry exceptions' do
  exceptions = {
    Gitlab::HTTP::Error => 'Error when connecting to Sentry',
    Net::OpenTimeout => 'Connection to Sentry timed out',
    SocketError => 'Received SocketError when trying to connect to Sentry',
    OpenSSL::SSL::SSLError => 'Sentry returned invalid SSL data',
    Errno::ECONNREFUSED => 'Connection refused',
    StandardError => 'Sentry request failed due to StandardError'
  }

  exceptions.each do |exception, message|
    context "#{exception}" do
      before do
        stub_request(:get, sentry_request_url).to_raise(exception)
      end

      it do
        expect { subject }
          .to raise_exception(Sentry::Client::Error, message)
      end
    end
  end
end
