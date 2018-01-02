require 'spec_helper'

describe Gitlab::Metrics::System do
  if File.exist?('/proc')
    describe '.memory_usage' do
      it "returns the process' memory usage in bytes" do
        expect(described_class.memory_usage).to be > 0
      end
    end

    describe '.file_descriptor_count' do
      it 'returns the amount of open file descriptors' do
        expect(described_class.file_descriptor_count).to be > 0
      end
    end
  else
    describe '.memory_usage' do
      it 'returns 0.0' do
        expect(described_class.memory_usage).to eq(0.0)
      end
    end

    describe '.file_descriptor_count' do
      it 'returns 0' do
        expect(described_class.file_descriptor_count).to eq(0)
      end
    end
  end

  describe '.cpu_time' do
    it 'returns a Fixnum' do
      expect(described_class.cpu_time).to be_an(Float)
    end
  end

  describe '.real_time' do
    it 'returns a Fixnum' do
      expect(described_class.real_time).to be_an(Float)
    end
  end

  describe '.monotonic_time' do
    it 'returns a Float' do
      expect(described_class.monotonic_time).to be_an(Float)
    end
  end
end
