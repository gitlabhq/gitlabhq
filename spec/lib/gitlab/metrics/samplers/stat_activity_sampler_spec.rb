# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::Metrics::Samplers::StatActivitySampler, feature_category: :scalability do
  subject(:sample) { described_class.new.sample }

  it_behaves_like 'metrics sampler', 'STAT_ACTIVITY_SAMPLER'

  describe '#sample' do
    it 'invokes the Gitlab::Database::StatActivitySampler' do
      times = Gitlab::Database::LoadBalancing.base_models.count
      expect_next_instances_of(Gitlab::Database::StatActivitySampler, times) do |service|
        expect(service).to receive(:execute)
      end

      sample
    end

    context 'when sample_pg_stat_activity feature flag is disabled' do
      before do
        stub_feature_flags(sample_pg_stat_activity: false)
      end

      it 'does not invokes any Gitlab::Database::StatActivitySampler' do
        expect(Gitlab::Database::StatActivitySampler).not_to receive(:new)

        sample
      end
    end
  end
end
