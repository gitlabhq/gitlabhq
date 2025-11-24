# frozen_string_literal: true

require 'fast_spec_helper'

RSpec.describe Gitlab::Usage::Metrics::Instrumentations::UniqueInstanceIdMetric,
  feature_category: :service_ping do
  let(:uuid) { 'test-uuid' }

  before do
    allow(Gitlab::GlobalAnonymousId).to receive(:instance_uuid).and_return(uuid)
  end

  subject(:metric) do
    described_class.new({ time_frame: 'none' }).value
  end

  it 'returns the unique instance ID' do
    expect(metric).to eq(uuid)
  end
end
