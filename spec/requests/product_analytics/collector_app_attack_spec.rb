# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'ProductAnalytics::CollectorApp throttle' do
  include RackAttackSpecHelpers

  include_context 'rack attack cache store'

  let(:project1) { create(:project) }
  let(:project2) { create(:project) }

  before do
    allow(ProductAnalyticsEvent).to receive(:create).and_return(true)
  end

  context 'per application id' do
    let(:params) do
      {
        aid: project1.id,
        eid: SecureRandom.uuid
      }
    end

    it 'throttles the endpoint' do
      # Allow requests under the rate limit.
      100.times do
        expect_ok { get '/-/collector/i', params: params }
      end

      # Ensure its not related to ip address
      random_next_ip

      # Reject request over the limit
      expect_rejection { get '/-/collector/i', params: params }

      # But allows request for different aid
      expect_ok { get '/-/collector/i', params: params.merge(aid: project2.id) }
    end
  end
end
