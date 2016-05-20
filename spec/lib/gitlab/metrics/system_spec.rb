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

  describe '.load_average' do
    it 'returns the amount of load as 3 values array' do
      expect(described_class.load_average[0]).to be >= 0.0
      expect(described_class.load_average[1]).to be >= 0.0
      expect(described_class.load_average[2]).to be >= 0.0
    end
  end

  describe '.cpu_time' do
    it 'returns a Fixnum' do
      expect(described_class.cpu_time).to be_an_instance_of(Fixnum)
    end
  end
end
