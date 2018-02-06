require 'spec_helper'

describe Gitlab::SidekiqThrottler do
  describe '#execute!' do
    context 'when job throttling is enabled' do
      before do
        Sidekiq.options[:concurrency] = 35

        stub_application_setting(
          sidekiq_throttling_enabled: true,
          sidekiq_throttling_factor: 0.1,
          sidekiq_throttling_queues: %w[build project_cache]
        )
      end

      it 'requires sidekiq-limit_fetch' do
        expect(described_class).to receive(:require).with('sidekiq-limit_fetch').and_call_original

        described_class.execute!
      end

      it 'sets limits on the selected queues' do
        described_class.execute!

        expect(Sidekiq::Queue['build'].limit).to eq 4
        expect(Sidekiq::Queue['project_cache'].limit).to eq 4
      end

      it 'does not set limits on other queues' do
        described_class.execute!

        expect(Sidekiq::Queue['merge'].limit).to be_nil
      end
    end

    context 'when job throttling is disabled' do
      it 'does not require sidekiq-limit_fetch' do
        expect(described_class).not_to receive(:require).with('sidekiq-limit_fetch')

        described_class.execute!
      end
    end
  end
end
