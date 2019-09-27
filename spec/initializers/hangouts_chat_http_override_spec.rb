# frozen_string_literal: true

require 'spec_helper'

describe 'HangoutsChat::Sender Gitlab::HTTP override' do
  describe 'HangoutsChat::Sender::HTTP#post' do
    it 'calls Gitlab::HTTP.post with default protection settings' do
      webhook_url = 'https://example.gitlab.com'
      payload = { key: 'value' }
      http = HangoutsChat::Sender::HTTP.new(webhook_url)
      mock_response = double(response: 'the response')

      expect(Gitlab::HTTP).to receive(:post)
        .with(
          URI.parse(webhook_url),
          body: payload.to_json,
          headers: { 'Content-Type' => 'application/json' },
          parse: nil
        )
        .and_return(mock_response)

      expect(http.post(payload)).to eq(mock_response.response)
    end

    it_behaves_like 'a request using Gitlab::UrlBlocker' do
      let(:http_method) { :post }
      let(:url_blocked_error_class) { Gitlab::HTTP::BlockedUrlError }

      def make_request(uri)
        HangoutsChat::Sender::HTTP.new(uri).post({})
      end
    end
  end
end
