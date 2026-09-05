# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::Auth::Otp::Strategies::DuoAuth::ManualOtp, feature_category: :system_access do
  # `freeze: false` is required in this spec: one or more `let_it_be` subjects
  # cannot be frozen by default (deep_freeze traversal failure, a non-AR
  # subject, or an in-memory mutation that survives reload/refind). Do not
  # drop these opt-outs or convert them to `let_it_be_with_reload`/`refind`
  # (see gitlab-org/gitlab#602925).
  let_it_be(:user, freeze: false) { create(:user) }

  let(:otp_code) { '042315' }
  let(:hostname) { 'duo_auth.example.com' }
  let(:integration_key) { 'int3gr4t1on' }
  let(:secret_key) { 's3cr3t' }
  let(:auth_url) { "https://#{hostname}/auth/v2/auth" }

  let(:manual_otp) { described_class.new(user) }

  subject(:response) { manual_otp.validate(otp_code) }

  before do
    stub_duo_auth_config(
      enabled: true,
      hostname: hostname,
      secret_key: secret_key,
      integration_key: integration_key
    )
  end

  def stub_duo_auth(result:, status_msg: nil, status: 200)
    body = Gitlab::Json.generate({ response: { result: result, status_msg: status_msg }.compact })
    stub_request(:post, auth_url).to_return(
      status: status,
      body: body,
      headers: { 'Content-Type' => 'application/json' }
    )
  end

  context 'when Duo allows the passcode' do
    before do
      stub_duo_auth(result: 'allow')
    end

    it 'returns success' do
      expect(response[:status]).to eq(:success)
    end

    it 'sends the passcode to Duo as a string, preserving leading zeros' do
      response

      expect(a_request(:post, auth_url).with do |req|
        body = Gitlab::Json::SafeParser.parse(req.body)
        body['passcode'] == otp_code && body['factor'] == 'passcode' && body['username'] == user.username
      end).to have_been_made
    end
  end

  context 'when Duo denies the passcode' do
    before do
      stub_duo_auth(result: 'deny', status_msg: 'Incorrect passcode. Try again.')
    end

    it "returns an error carrying Duo's status message as a string" do
      expect(response[:status]).to eq(:error)
      expect(response[:message]).to eq('Incorrect passcode. Try again.')
    end
  end

  context 'when Duo returns an unparseable body' do
    before do
      stub_request(:post, auth_url).to_return(status: 200, body: 'aaa')
    end

    it 'returns an error' do
      expect(response[:status]).to eq(:error)
      expect(response[:message]).to match(/unexpected character/)
    end
  end

  def stub_duo_auth_config(duo_auth_settings)
    allow(::Gitlab.config.duo_auth).to(receive_messages(duo_auth_settings))
  end
end
