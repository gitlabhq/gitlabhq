# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::GrapeLogging::Loggers::CloudflareLogger do
  subject { described_class.new }

  describe "#parameters" do
    let(:mock_request) { ActionDispatch::Request.new({}) }
    let(:start_time) { Time.new(2018, 01, 01) }

    describe 'with no Cloudflare headers' do
      it 'returns an empty hash' do
        expect(subject.parameters(mock_request, nil)).to eq({})
      end
    end

    describe 'with Cloudflare headers' do
      before do
        mock_request.headers['Cf-Ray'] = SecureRandom.hex
        mock_request.headers['Cf-Request-Id'] = SecureRandom.hex
      end

      it 'returns the correct duration in seconds' do
        data = subject.parameters(mock_request, nil)

        expect(data.keys).to contain_exactly(:cf_ray, :cf_request_id)
      end
    end
  end
end
