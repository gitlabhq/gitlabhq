# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::Auth::Otp::Strategies::FortiTokenCloud do
  let_it_be(:user) { create(:user) }

  let(:otp_code) { 42 }

  let(:url) { 'https://ftc.example.com:9696/api/v1' }
  let(:client_id) { 'client_id' }
  let(:client_secret) { 's3cr3t' }
  let(:access_token_create_url) { url + '/login' }
  let(:otp_verification_url) { url + '/auth' }
  let(:access_token) { 'an_access_token' }
  let(:access_token_create_response_body) { '' }
  let(:access_token_request_body) { { client_id: client_id, client_secret: client_secret } }
  let(:headers) { { 'Content-Type': 'application/json' } }

  subject(:validate) { described_class.new(user).validate(otp_code) }

  before do
    stub_feature_flags(forti_token_cloud: user)

    stub_const("#{described_class}::BASE_API_URL", url)

    stub_forti_token_cloud_config(
      enabled: true,
      client_id: client_id,
      client_secret: client_secret
    )

    stub_request(:post, access_token_create_url)
      .with(body: JSON(access_token_request_body), headers: headers)
      .to_return(
        status: access_token_create_response_status,
        body: Gitlab::Json.generate(access_token_create_response_body),
        headers: {}
      )
  end

  context 'access token is created successfully' do
    let(:access_token_create_response_body) { { access_token: access_token, expires_in: 3600 } }
    let(:access_token_create_response_status) { 201 }

    before do
      otp_verification_request_body = { username: user.username,
                                        token: otp_code }

      stub_request(:post, otp_verification_url)
        .with(
          body: JSON(otp_verification_request_body),
          headers: {
            'Content-Type' => 'application/json',
            'Authorization' => "Bearer #{access_token}"
          }
        )
        .to_return(status: otp_verification_response_status, body: '', headers: {})
    end

    context 'otp verification is successful' do
      let(:otp_verification_response_status) { 200 }

      it 'returns success' do
        expect(validate[:status]).to eq(:success)
      end
    end

    context 'otp verification is not successful' do
      let(:otp_verification_response_status) { 401 }

      it 'returns error' do
        expect(validate[:status]).to eq(:error)
      end
    end
  end

  context 'access token creation fails' do
    let(:access_token_create_response_status) { 400 }

    it 'returns error' do
      expect(validate[:status]).to eq(:error)
    end
  end

  context 'SSL Verification' do
    let(:access_token_create_response_status) { 400 }

    context 'with `Gitlab::HTTP`' do
      it 'does not use a `verify` argument,'\
         'thereby always performing SSL verification while making API calls' do
        expect(Gitlab::HTTP).to receive(:post)
          .with(access_token_create_url, body: JSON(access_token_request_body), headers: headers).and_call_original

        validate
      end
    end
  end

  def stub_forti_token_cloud_config(forti_token_cloud_settings)
    allow(::Gitlab.config.forti_token_cloud).to(receive_messages(forti_token_cloud_settings))
  end
end
