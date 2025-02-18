# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::Usage::Metrics::Instrumentations::TestGitlabNetConnectivityMetric,
  feature_category: :service_ping do
  let(:uuid) { 'test-uuid' }
  let(:snowplow_url) { "#{described_class::GITLAB_NET_TEST_URL}#{uuid}" }

  before do
    allow(Gitlab::CurrentSettings).to receive(:uuid).and_return(uuid)
    allow(Gitlab).to receive(:dev_or_test_env?).and_return(false)
    allow(ServicePing::ServicePingSettings).to receive(:enabled_and_consented?).and_return(true)
  end

  subject(:metric) do
    described_class.new({ time_frame: 'none' }).value
  end

  context 'in dev or test' do
    before do
      allow(Gitlab).to receive(:dev_or_test_env?).and_return(true)
    end

    it 'returns false without making HTTP request' do
      expect(Gitlab::HTTP).not_to receive(:post)
      expect(metric).to be(false)
    end
  end

  context 'when service ping is not enabled and consented' do
    before do
      allow(ServicePing::ServicePingSettings).to receive(:enabled_and_consented?).and_return(false)
    end

    it 'returns false without making HTTP request' do
      expect(Gitlab::HTTP).not_to receive(:post)
      expect(metric).to be(false)
    end
  end

  context 'when HTTP request succeeds' do
    before do
      stub_request(:post, snowplow_url).to_return(status: 200)
    end

    it 'returns true' do
      expect(metric).to be(true)
    end
  end

  context 'when HTTP request fails' do
    before do
      stub_request(:post, snowplow_url).to_raise(StandardError)
    end

    it 'returns false' do
      expect(metric).to be(false)
    end
  end
end
