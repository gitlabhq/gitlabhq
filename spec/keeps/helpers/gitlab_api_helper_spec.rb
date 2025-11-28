# frozen_string_literal: true

require 'spec_helper'
require './keeps/helpers/gitlab_api_helper'

RSpec.describe Keeps::Helpers::GitlabApiHelper, feature_category: :tooling do
  let(:helper) { described_class.new }
  let(:api_url) { 'https://gitlab.com/api/v4/projects/278964/issues' }

  before do
    allow(helper).to receive(:print)
    allow(helper).to receive(:puts)
  end

  describe '#query_api' do
    let(:first_page_response) do
      instance_double(
        HTTParty::Response,
        parsed_response: [{ id: 1 }, { id: 2 }],
        headers: {
          'x-next-page' => '2',
          'ratelimit-remaining' => '100',
          'ratelimit-reset' => (Time.now + 3600).to_i.to_s
        }
      )
    end

    let(:second_page_response) do
      instance_double(
        HTTParty::Response,
        parsed_response: [{ id: 3 }],
        headers: {
          'x-next-page' => '',
          'ratelimit-remaining' => '99',
          'ratelimit-reset' => (Time.now + 3600).to_i.to_s
        }
      )
    end

    it 'yields each result from paginated API responses' do
      allow(Gitlab::HTTP_V2).to receive(:get)
        .with(api_url, anything)
        .and_return(first_page_response)
      allow(Gitlab::HTTP_V2).to receive(:get)
        .with("#{api_url}&page=2", anything)
        .and_return(second_page_response)

      results = []
      helper.query_api(api_url) { |result| results << result }

      expect(results).to eq([{ id: 1 }, { id: 2 }, { id: 3 }])
    end
  end

  describe '#get' do
    let(:http_response) do
      instance_double(
        HTTParty::Response,
        parsed_response: [{ id: 1 }],
        headers: {
          'x-next-page' => '2',
          'ratelimit-remaining' => '50',
          'ratelimit-reset' => '1234567890'
        }
      )
    end

    it 'returns parsed response data with pagination info' do
      allow(Gitlab::HTTP_V2).to receive(:get).and_return(http_response)

      result = helper.get(api_url)

      expect(result).to include(
        more_pages: true,
        results: [{ id: 1 }],
        ratelimit_remaining: '50',
        ratelimit_reset_at: '1234567890'
      )
    end
  end

  describe '#next_page_url' do
    let(:http_response) do
      instance_double(
        HTTParty::Response,
        headers: { 'x-next-page' => '3' }
      )
    end

    it 'constructs next page URL' do
      url = 'https://gitlab.com/api/v4/projects/278964/issues?state=opened&page=2'

      result = helper.next_page_url(url, http_response)

      expect(result).to eq('https://gitlab.com/api/v4/projects/278964/issues?state=opened&page=3')
    end
  end

  describe '#rate_limit_wait' do
    before do
      allow(helper).to receive(:puts)
    end

    it 'sleeps when rate limit is below threshold' do
      current_time = Time.now
      reset_time = current_time + 60

      get_result = {
        ratelimit_remaining: '20',
        ratelimit_reset_at: reset_time.to_i.to_s
      }

      # Mock Time.now to return values in sequence
      time_sequence = [current_time, current_time, reset_time]
      allow(Time).to receive(:now) { time_sequence.shift }

      # Stub Time.at
      allow(Time).to receive(:at).with(reset_time.to_i).and_return(reset_time)

      expect(helper).to receive(:sleep).with(1).once

      helper.rate_limit_wait(get_result)
    end
  end
end
