# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::Auth::Otp::Strategies::DuoAuth::ManualOtp, feature_category: :system_access do
  let_it_be(:user, freeze: false) { create(:user) }

  let_it_be(:otp_code, freeze: false) { 42 }

  let_it_be(:hostname, freeze: false) { 'duo_auth.example.com' }
  let_it_be(:integration_key, freeze: false) { 'int3gr4t1on' }
  let_it_be(:secret_key, freeze: false) { 's3cr3t' }

  let_it_be(:duo_response_builder, freeze: false) { Struct.new(:body) }

  let_it_be(:response_status, freeze: false) { 200 }

  let_it_be(:duo_auth_url, freeze: false) { "https://#{hostname}/auth/v2/auth/" }
  let_it_be(:params, freeze: false) do
    { username: user.username,
      factor: "passcode",
      passcode: otp_code }
  end

  let_it_be(:manual_otp, freeze: false) { described_class.new(user) }

  subject(:response) { manual_otp.validate(otp_code) }

  before do
    stub_duo_auth_config(
      enabled: true,
      hostname: hostname,
      secret_key: secret_key,
      integration_key: integration_key
    )
  end

  context 'when successful validation' do
    before do
      allow(duo_client).to receive(:request)
        .with("POST", "/auth/v2/auth", params)
        .and_return(duo_response_builder.new('{ "response": { "result": "allow" }}'))

      allow(manual_otp).to receive(:duo_client).and_return(duo_client)
    end

    it 'returns success' do
      response

      expect(response[:status]).to eq(:success)
    end
  end

  context 'when unsuccessful validation' do
    before do
      allow(duo_client).to receive(:request)
        .with("POST", "/auth/v2/auth", params)
        .and_return(duo_response_builder.new('{ "response": { "result": "deny" }}'))

      allow(manual_otp).to receive(:duo_client).and_return(duo_client)
    end

    it 'returns error' do
      response

      expect(response[:status]).to eq(:error)
    end
  end

  context 'when unexpected error' do
    before do
      allow(duo_client).to receive(:request)
      .with("POST", "/auth/v2/auth", params)
      .and_return(duo_response_builder.new('aaa'))

      allow(manual_otp).to receive(:duo_client).and_return(duo_client)
    end

    it 'returns error' do
      response

      expect(response[:status]).to eq(:error)
      expect(response[:message]).to match(/unexpected character/)
    end
  end

  def stub_duo_auth_config(duo_auth_settings)
    allow(::Gitlab.config.duo_auth).to(receive_messages(duo_auth_settings))
  end

  def duo_client
    manual_otp.send(:duo_client)
  end
end
