# frozen_string_literal: true

require 'spec_helper'

RSpec.describe ::Gitlab::BeyondIdentity::Client, feature_category: :source_code_management do
  let_it_be_with_reload(:integration) { create(:beyond_identity_integration) }

  let(:stubbed_response) do
    { 'authorized' => true }.to_json
  end

  let(:params) { { key_id: 'key-id', committer_email: 'email@example.com' } }
  let(:status) { 200 }

  let!(:request) do
    stub_request(:get, ::Gitlab::BeyondIdentity::Client::API_URL).with(
      query: params,
      headers: { 'Content-Type' => 'application/json', Authorization: "Bearer #{integration.token}" }
    ).to_return(
      status: status,
      body: stubbed_response
    )
  end

  subject(:client) { described_class.new(integration) }

  context 'when integration is not activated' do
    it 'raises a config error' do
      integration.active = false

      expect do
        client.execute(params)
      end.to raise_error(::Gitlab::BeyondIdentity::Client::Error).with_message(
        'integration is not activated'
      )

      expect(request).not_to have_been_requested
    end
  end

  it 'executes successfully' do
    expect(client.execute(params)).to eq({ 'authorized' => true })
    expect(request).to have_been_requested
  end

  context 'with invalid response' do
    let(:stubbed_response) { 'invalid' }

    it 'executes successfully' do
      expect { client.execute(params) }.to raise_error(
        ::Gitlab::BeyondIdentity::Client::ApiError
      ).with_message('invalid response format')
    end
  end

  context 'with an error response' do
    let(:stubbed_response) do
      { 'error' => { 'message' => 'gpg_key is invalid' } }.to_json
    end

    let(:status) { 400 }

    it 'returns an error' do
      expect { client.execute(params) }.to raise_error do |error|
        expect(error).to be_a(::Gitlab::BeyondIdentity::Client::ApiError)
        expect(error.message).to eq('gpg_key is invalid')
        expect(error.code).to eq(status)
        expect(error).not_to be_acceptable_error
      end
    end

    context 'when the error is acceptable' do
      let(:status) { 404 }

      it 'returns an error' do
        expect { client.execute(params) }.to raise_error do |error|
          expect(error).to be_a(::Gitlab::BeyondIdentity::Client::ApiError)
          expect(error.message).to eq('gpg_key is invalid')
          expect(error.code).to eq(status)
          expect(error).to be_acceptable_error
        end
      end
    end
  end

  context 'when key is unauthorized' do
    let(:stubbed_response) do
      { 'authorized' => false, 'message' => 'key is unauthorized' }.to_json
    end

    it 'returns an error' do
      expect { client.execute(params) }.to raise_error do |error|
        expect(error).to be_a(::Gitlab::BeyondIdentity::Client::ApiError)
        expect(error.message).to eq('key is unauthorized')
        expect(error.code).to eq(status)
        expect(error).not_to be_acceptable_error
      end
    end
  end
end
