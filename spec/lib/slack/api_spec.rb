# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Slack::API, feature_category: :integrations do
  describe '#post' do
    let(:slack_installation) { build(:slack_integration) }
    let(:api_method) { 'api_method_call' }
    let(:api_url) { "#{described_class::BASE_URL}/#{api_method}" }
    let(:payload) { { foo: 'bar' } }

    subject(:post) { described_class.new(slack_installation).post(api_method, payload) }

    before do
      stub_request(:post, api_url)
    end

    it 'posts to the Slack API correctly' do
      post

      expect(WebMock).to have_requested(:post, api_url).with(
        body: payload.to_json,
        headers: {
          'Authorization' => "Bearer #{slack_installation.bot_access_token}",
          'Content-Type' => 'application/json; charset=utf-8'
        })
    end

    it 'returns the response' do
      is_expected.to be_kind_of(HTTParty::Response)
    end

    context 'when the slack installation has no bot token' do
      let(:slack_installation) { build(:slack_integration, :legacy) }

      it 'raises an error' do
        expect { post }.to raise_error(ArgumentError)
      end
    end
  end
end
