# frozen_string_literal: true

require 'fast_spec_helper'
require 'gitlab/rspec/all'

require_relative '../../../scripts/lib/assets_heap_sizing'

RSpec.describe AssetsHeapSizing, feature_category: :tooling do
  describe '.node_heap_size_mb' do
    it 'returns the default when memory cannot be detected' do
      expect(described_class.node_heap_size_mb(nil)).to eq(described_class::DEFAULT_HEAP_MB)
    end

    it 'returns 75% of the detected memory' do
      expect(described_class.node_heap_size_mb(32_000)).to eq(24_000)
    end

    it 'never drops below the default' do
      expect(described_class.node_heap_size_mb(8_000)).to eq(described_class::DEFAULT_HEAP_MB)
    end
  end

  describe '.container_memory_limit_mb' do
    before do
      allow(described_class).to receive(:read_first_line).and_return(nil)
    end

    it 'prefers the cgroup v2 limit' do
      allow(described_class).to receive(:read_first_line)
        .with('/sys/fs/cgroup/memory.max').and_return((16 * 1024 * 1024 * 1024).to_s)

      expect(described_class.container_memory_limit_mb).to eq(16 * 1024)
    end

    it 'falls back to the cgroup v1 limit when v2 reports "max"' do
      allow(described_class).to receive(:read_first_line)
        .with('/sys/fs/cgroup/memory.max').and_return('max')
      allow(described_class).to receive(:read_first_line)
        .with('/sys/fs/cgroup/memory/memory.limit_in_bytes').and_return((8 * 1024 * 1024 * 1024).to_s)

      expect(described_class.container_memory_limit_mb).to eq(8 * 1024)
    end

    it 'ignores the cgroup v1 unlimited sentinel and falls back to /proc/meminfo' do
      allow(described_class).to receive(:read_first_line)
        .with('/sys/fs/cgroup/memory.max').and_return('max')
      allow(described_class).to receive(:read_first_line)
        .with('/sys/fs/cgroup/memory/memory.limit_in_bytes').and_return('9223372036854771712')
      allow(described_class).to receive(:read_first_line)
        .with('/proc/meminfo').and_return('MemTotal:       32109000 kB')

      expect(described_class.container_memory_limit_mb).to eq(32109000 * 1024 / 1024 / 1024)
    end

    it 'returns nil when nothing can be read' do
      expect(described_class.container_memory_limit_mb).to be_nil
    end
  end

  describe '.read_first_line' do
    it 'returns nil for a missing file' do
      expect(described_class.read_first_line('/does/not/exist')).to be_nil
    end
  end
end
