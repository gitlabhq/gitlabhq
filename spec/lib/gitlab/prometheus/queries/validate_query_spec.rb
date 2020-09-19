# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::Prometheus::Queries::ValidateQuery do
  include PrometheusHelpers

  let(:api_url) { 'https://prometheus.example.com' }
  let(:client) { Gitlab::PrometheusClient.new(api_url) }
  let(:query) { 'avg(metric)' }

  subject { described_class.new(client) }

  context 'valid query' do
    before do
      allow(client).to receive(:query).with(query)
    end

    it 'passess query to prometheus' do
      expect(subject.query(query)).to eq(valid: true)

      expect(client).to have_received(:query).with(query)
    end
  end

  context 'invalid query' do
    let(:query) { 'invalid query' }
    let(:error_message) { "invalid parameter 'query': 1:9: parse error: unexpected identifier \"query\"" }

    it 'returns invalid' do
      freeze_time do
        stub_prometheus_query_error(
          prometheus_query_with_time_url(query, Time.now),
          error_message
        )

        expect(subject.query(query)).to eq(valid: false, error: error_message)
      end
    end
  end

  context 'when exceptions occur' do
    context 'Gitlab::HTTP::BlockedUrlError' do
      let(:api_url) { 'http://192.168.1.1' }

      let(:message) do
        "URL 'http://192.168.1.1/api/v1/query?query=avg%28metric%29&time=#{Time.now.to_f}'" \
        " is blocked: Requests to the local network are not allowed"
      end

      before do
        stub_application_setting(allow_local_requests_from_web_hooks_and_services: false)
      end

      it 'catches exception and returns invalid' do
        freeze_time do
          expect(subject.query(query)).to eq(valid: false, error: message)
        end
      end
    end
  end
end
