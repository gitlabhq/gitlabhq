# frozen_string_literal: true

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

    describe '.max_open_file_descriptors' do
      it 'returns the max allowed open file descriptors' do
        expect(described_class.max_open_file_descriptors).to be > 0
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

    describe '.max_open_file_descriptors' do
      it 'returns 0' do
        expect(described_class.max_open_file_descriptors).to eq(0)
      end
    end
  end

  describe '.cpu_time' do
    it 'returns a Float' do
      expect(described_class.cpu_time).to be_an(Float)
    end
  end

  describe '.real_time' do
    it 'returns a Float' do
      expect(described_class.real_time).to be_an(Float)
    end
  end

  describe '.monotonic_time' do
    it 'returns a Float' do
      expect(described_class.monotonic_time).to be_an(Float)
    end
  end

  describe '.thread_cpu_time' do
    it 'returns cpu_time on supported platform' do
      stub_const("Process::CLOCK_THREAD_CPUTIME_ID", 16)

      expect(Process).to receive(:clock_gettime)
        .with(16, kind_of(Symbol)) { 0.111222333 }

      expect(described_class.thread_cpu_time).to eq(0.111222333)
    end

    it 'returns nil on unsupported platform' do
      hide_const("Process::CLOCK_THREAD_CPUTIME_ID")

      expect(described_class.thread_cpu_time).to be_nil
    end
  end

  describe '.thread_cpu_duration' do
    let(:start_time) { described_class.thread_cpu_time }

    it 'returns difference between start and current time' do
      stub_const("Process::CLOCK_THREAD_CPUTIME_ID", 16)

      expect(Process).to receive(:clock_gettime)
        .with(16, kind_of(Symbol))
        .and_return(
          0.111222333,
          0.222333833
        )

      expect(described_class.thread_cpu_duration(start_time)).to eq(0.1111115)
    end

    it 'returns nil on unsupported platform' do
      hide_const("Process::CLOCK_THREAD_CPUTIME_ID")

      expect(described_class.thread_cpu_duration(start_time)).to be_nil
    end
  end
end
