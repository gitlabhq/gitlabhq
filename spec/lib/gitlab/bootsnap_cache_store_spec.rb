# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::BootsnapCacheStore, feature_category: :observability do
  # This is a process-wide singleton fed by the live Bootsnap.instrumentation
  # callback installed in config/boot.rb, so it accumulates real compile cache
  # events (during boot and whenever code is later loaded). These are unit tests
  # for the store's own methods, so disable the live feed and reset the store
  # around each example to keep the counts deterministic regardless of run order.
  around do |example|
    saved = (Bootsnap.instance_variable_get(:@instrumentation) if defined?(Bootsnap))
    Bootsnap.instrumentation = nil if defined?(Bootsnap)
    described_class.reset!

    example.run
  ensure
    described_class.reset!
    Bootsnap.instrumentation = saved if defined?(Bootsnap)
  end

  describe '.increment and .counts' do
    it 'starts with a zero count for every known event' do
      expect(described_class.counts).to eq(hit: 0, revalidated: 0, miss: 0, stale: 0)
    end

    it 'tallies events cumulatively' do
      described_class.increment(:hit)
      described_class.increment(:hit)
      described_class.increment(:miss)

      expect(described_class.counts).to include(hit: 2, miss: 1, revalidated: 0, stale: 0)
    end

    it 'only exposes known events' do
      described_class.increment(:unknown)

      expect(described_class.counts.keys).to match_array(described_class::EVENTS)
    end
  end

  describe '.hit_ratio' do
    it 'returns nil when no events were recorded' do
      expect(described_class.hit_ratio).to be_nil
    end

    it 'counts hit and revalidated as cache hits' do
      described_class.increment(:hit)
      described_class.increment(:revalidated)
      described_class.increment(:miss)
      described_class.increment(:stale)

      expect(described_class.hit_ratio).to eq(0.5)
    end

    it 'returns 1.0 when every lookup avoided a recompilation' do
      described_class.increment(:hit)
      described_class.increment(:revalidated)

      expect(described_class.hit_ratio).to eq(1.0)
    end

    it 'derives the ratio from a provided snapshot instead of the live counts' do
      described_class.increment(:miss) # live state that must be ignored

      snapshot = { hit: 3, revalidated: 1, miss: 0, stale: 0 }

      expect(described_class.hit_ratio(snapshot)).to eq(1.0)
    end
  end

  describe '.enable! and .enabled?' do
    it 'is disabled by default' do
      expect(described_class.enabled?).to be(false)
    end

    it 'becomes enabled once the callback is installed' do
      described_class.enable!

      expect(described_class.enabled?).to be(true)
    end
  end

  describe '.reset!' do
    it 'clears counts and the enabled flag' do
      described_class.enable!
      described_class.increment(:hit)

      described_class.reset!

      expect(described_class.enabled?).to be(false)
      expect(described_class.counts).to eq(hit: 0, revalidated: 0, miss: 0, stale: 0)
    end
  end
end
