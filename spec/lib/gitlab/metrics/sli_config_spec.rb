# frozen_string_literal: true

require 'spec_helper'

module SliConfigTest
  class PumaSli
    include Gitlab::Metrics::SliConfig

    puma_enabled!
  end

  class SidekiqSli
    include Gitlab::Metrics::SliConfig

    sidekiq_enabled!
  end
end

RSpec.describe Gitlab::Metrics::SliConfig, feature_category: :error_budgets do
  describe '.enabled_slis' do
    context 'when runtime is puma' do
      specify do
        allow(Gitlab::Runtime).to receive_messages(puma?: true, sidekiq?: false)

        expect(described_class.enabled_slis).to include(SliConfigTest::PumaSli)
      end
    end

    context 'when runtime is sidekiq' do
      specify do
        allow(Gitlab::Runtime).to receive_messages(puma?: false, sidekiq?: true)

        expect(described_class.enabled_slis).to include(SliConfigTest::SidekiqSli)
      end
    end
  end
end
