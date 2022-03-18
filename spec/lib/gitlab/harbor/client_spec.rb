# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::Harbor::Client do
  let(:harbor_integration) { build(:harbor_integration) }

  subject(:client) { described_class.new(harbor_integration) }

  describe '#ping' do
    let!(:harbor_ping_request) { stub_harbor_request("https://demo.goharbor.io/api/v2.0/ping") }

    it "calls api/v2.0/ping successfully" do
      expect(client.ping).to eq(success: true)
    end
  end

  private

  def stub_harbor_request(url, body: {}, status: 200, headers: {})
    stub_request(:get, url)
      .to_return(
        status: status,
        headers: { 'Content-Type' => 'application/json' }.merge(headers),
        body: body.to_json
      )
  end
end
