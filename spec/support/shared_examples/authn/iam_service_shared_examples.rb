# frozen_string_literal: true

RSpec.shared_examples 'iam service error response' do |reason:, message:|
  it 'returns an error response and logs the failure', :aggregate_failures do
    allow(Gitlab::AuthLogger).to receive(:error)

    result

    expect(result).to be_error
    expect(result.reason).to eq(reason)
    expect(result.message).to eq(message)
    expect(Gitlab::AuthLogger).to have_received(:error)
  end
end

RSpec.shared_examples 'iam service error response with user' do |reason:, message:|
  it 'returns an error response and logs the failure with user id', :aggregate_failures do
    allow(Gitlab::AuthLogger).to receive(:error)

    result

    expect(result).to be_error
    expect(result.reason).to eq(reason)
    expect(result.message).to eq(message)
    expect(Gitlab::AuthLogger).to have_received(:error)
      .with(hash_including(Labkit::Fields::GL_USER_ID => user.id))
  end
end

RSpec.shared_examples 'iam service transport failure' do |http_method:|
  context 'when a network error occurs' do
    before do
      allow(Gitlab::HTTP).to receive(http_method).and_raise(Errno::ECONNREFUSED)
    end

    it 'returns a service_unavailable error and tracks the exception', :aggregate_failures do
      expect(Gitlab::ErrorTracking).to receive(:track_exception).with(instance_of(Errno::ECONNREFUSED))

      expect(result).to be_error
      expect(result.reason).to eq(:service_unavailable)
      expect(result.message).to eq('Failed to connect to IAM service')
    end
  end

  context 'when the IAM service is not configured' do
    before do
      allow(Authn::IamAuthService).to receive(:url)
        .and_raise(Authn::IamAuthService::ConfigurationError, 'IAM service is not configured')
    end

    it 'returns a service_unavailable error' do
      expect(result).to be_error
      expect(result.reason).to eq(:service_unavailable)
      expect(result.message).to eq('IAM service is not configured')
    end
  end
end
