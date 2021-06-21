# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Spam::SpamParams do
  describe '.new_from_request' do
    let(:captcha_response) { 'abc123' }
    let(:spam_log_id) { 42 }
    let(:ip_address) { '0.0.0.0' }
    let(:user_agent) { 'Lynx' }
    let(:referer) { 'http://localhost' }
    let(:headers) do
      {
        'X-GitLab-Captcha-Response' => captcha_response,
        'X-GitLab-Spam-Log-Id' => spam_log_id
      }
    end

    let(:env) do
      {
        'action_dispatch.remote_ip' => ip_address,
        'HTTP_USER_AGENT' => user_agent,
        'HTTP_REFERER' => referer
      }
    end

    let(:request) {double(:request, headers: headers, env: env)}

    it 'constructs from a request' do
      expected = ::Spam::SpamParams.new(
        captcha_response: captcha_response,
        spam_log_id: spam_log_id,
        ip_address: ip_address,
        user_agent: user_agent,
        referer: referer
      )
      expect(described_class.new_from_request(request: request)).to eq(expected)
    end
  end
end
