# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::ExternalAuthorization::Response do
  let(:http_response) { double }

  subject(:response) { described_class.new(http_response) }

  describe '#valid?' do
    it 'is valid for 200, 401, and 403 responses' do
      [200, 401, 403].each do |code|
        allow(http_response).to receive(:code).and_return(code)

        expect(response).to be_valid
      end
    end

    it "is invalid for other statuses" do
      expect(http_response).to receive(:code).and_return(500)

      expect(response).not_to be_valid
    end
  end

  describe '#reason' do
    it 'returns a reason if it was included in the response body' do
      expect(http_response).to receive(:body).and_return({ reason: 'Not authorized' }.to_json)

      expect(response.reason).to eq('Not authorized')
    end

    it 'returns nil when there was no body' do
      expect(http_response).to receive(:body).and_return('')

      expect(response.reason).to eq(nil)
    end
  end

  describe '#successful?' do
    it 'is `true` if the status is 200' do
      allow(http_response).to receive(:code).and_return(200)

      expect(response).to be_successful
    end

    it 'is `false` if the status is 401 or 403' do
      [401, 403].each do |code|
        allow(http_response).to receive(:code).and_return(code)

        expect(response).not_to be_successful
      end
    end
  end
end
