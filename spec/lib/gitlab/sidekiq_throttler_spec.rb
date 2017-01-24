require 'spec_helper'

describe Gitlab::SidekiqThrottler do
  before do
    Sidekiq.options[:concurrency] = 35

    stub_application_setting(
      sidekiq_throttling_enabled: true,
      sidekiq_throttling_factor: 0.1,
      sidekiq_throttling_queues: %w[build project_cache]
    )
  end

  describe '#execute!' do
    it 'sets limits on the selected queues' do
      Gitlab::SidekiqThrottler.execute!

      expect(Sidekiq::Queue['build'].limit).to eq 4
      expect(Sidekiq::Queue['project_cache'].limit).to eq 4
    end

    it 'does not set limits on other queues' do
      Gitlab::SidekiqThrottler.execute!

      expect(Sidekiq::Queue['merge'].limit).to be_nil
    end
  end
end
