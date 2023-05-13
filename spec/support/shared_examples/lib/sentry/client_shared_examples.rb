# frozen_string_literal: true

# Requires sentry_api_request and subject to be defined
RSpec.shared_examples 'calls sentry api' do
  it 'calls sentry api' do
    subject

    expect(sentry_api_request).to have_been_requested
  end
end

# Requires sentry_api_url and subject to be defined
RSpec.shared_examples 'no Sentry redirects' do |http_method|
  let(:redirect_to) { 'https://redirected.example.com' }
  let(:other_url) { 'https://other.example.org' }

  let!(:redirected_req_stub) { stub_sentry_request(other_url) }

  let!(:redirect_req_stub) do
    stub_sentry_request(
      sentry_api_url,
      http_method || :get,
      status: 302,
      headers: { location: redirect_to }
    )
  end

  it 'does not follow redirects' do
    expect { subject }.to raise_exception(ErrorTracking::SentryClient::Error, 'Sentry response status code: 302')
    expect(redirect_req_stub).to have_been_requested
    expect(redirected_req_stub).not_to have_been_requested
  end
end

RSpec.shared_examples 'maps Sentry exceptions' do |http_method|
  exceptions = {
    Gitlab::HTTP::Error => 'Error when connecting to Sentry',
    Net::OpenTimeout => 'Connection to Sentry timed out',
    SocketError => 'Received SocketError when trying to connect to Sentry',
    OpenSSL::SSL::SSLError => 'Sentry returned invalid SSL data',
    Errno::ECONNREFUSED => 'Connection refused',
    StandardError => 'Sentry request failed due to StandardError'
  }

  exceptions.each do |exception, message|
    context exception do
      before do
        stub_request(
          http_method || :get,
          sentry_request_url
        ).to_raise(exception)
      end

      it do
        expect { subject }
          .to raise_exception(ErrorTracking::SentryClient::Error, message)
      end
    end
  end
end

RSpec.shared_examples 'non-numeric input handling in Sentry response' do |field|
  context 'with non-numeric error id' do
    where(:id_input) do
      ['string', '-1', '1\n2']
    end

    with_them do
      it 'raises exception' do
        message = %(Sentry API response contains invalid value for field "#{field}": #{id_input.inspect} is not numeric)

        expect { subject }.to raise_error(ErrorTracking::SentryClient::InvalidFieldValueError, message)
      end
    end
  end
end

# Expects to following variables:
#   - subject
#   - sentry_api_response
#   - sentry_url, token
RSpec.shared_examples 'Sentry API response size limit' do
  let(:invalid_deep_size) { instance_double(Gitlab::Utils::DeepSize, valid?: false) }

  before do
    allow(Gitlab::Utils::DeepSize)
      .to receive(:new)
      .with(sentry_api_response, any_args)
      .and_return(invalid_deep_size)
  end

  it 'raises an exception when response is too large' do
    expect { subject }.to raise_error(
      ErrorTracking::SentryClient::ResponseInvalidSizeError,
      'Sentry API response is too big. Limit is 1 MB.'
    )
  end
end
