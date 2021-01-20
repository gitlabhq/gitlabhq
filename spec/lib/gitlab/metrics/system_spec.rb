# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::Metrics::System do
  context 'when /proc files exist' do
    # Fixtures pulled from:
    # Linux carbon 5.3.0-7648-generic #41~1586789791~19.10~9593806-Ubuntu SMP Mon Apr 13 17:50:40 UTC  x86_64 x86_64 x86_64 GNU/Linux
    let(:proc_status) do
      # most rows omitted for brevity
      <<~SNIP
      Name:       less
      VmHWM:      2468 kB
      VmRSS:      2468 kB
      RssAnon:    260 kB
      SNIP
    end

    let(:proc_smaps_rollup) do
      # full snapshot
      <<~SNIP
      Rss:                2564 kB
      Pss:                 503 kB
      Pss_Anon:            312 kB
      Pss_File:            191 kB
      Pss_Shmem:             0 kB
      Shared_Clean:       2100 kB
      Shared_Dirty:          0 kB
      Private_Clean:       152 kB
      Private_Dirty:       312 kB
      Referenced:         2564 kB
      Anonymous:           312 kB
      LazyFree:              0 kB
      AnonHugePages:         0 kB
      ShmemPmdMapped:        0 kB
      Shared_Hugetlb:        0 kB
      Private_Hugetlb:       0 kB
      Swap:                  0 kB
      SwapPss:               0 kB
      Locked:                0 kB
      SNIP
    end

    let(:proc_limits) do
      # full snapshot
      <<~SNIP
      Limit                     Soft Limit           Hard Limit           Units
      Max cpu time              unlimited            unlimited            seconds
      Max file size             unlimited            unlimited            bytes
      Max data size             unlimited            unlimited            bytes
      Max stack size            8388608              unlimited            bytes
      Max core file size        0                    unlimited            bytes
      Max resident set          unlimited            unlimited            bytes
      Max processes             126519               126519               processes
      Max open files            1024                 1048576              files
      Max locked memory         67108864             67108864             bytes
      Max address space         unlimited            unlimited            bytes
      Max file locks            unlimited            unlimited            locks
      Max pending signals       126519               126519               signals
      Max msgqueue size         819200               819200               bytes
      Max nice priority         0                    0
      Max realtime priority     0                    0
      Max realtime timeout      unlimited            unlimited            us
      SNIP
    end

    describe '.memory_usage_rss' do
      it "returns the process' resident set size (RSS) in bytes" do
        mock_existing_proc_file('/proc/self/status', proc_status)

        expect(described_class.memory_usage_rss).to eq(2527232)
      end
    end

    describe '.file_descriptor_count' do
      it 'returns the amount of open file descriptors' do
        expect(Dir).to receive(:glob).and_return(['/some/path', '/some/other/path'])

        expect(described_class.file_descriptor_count).to eq(2)
      end
    end

    describe '.max_open_file_descriptors' do
      it 'returns the max allowed open file descriptors' do
        mock_existing_proc_file('/proc/self/limits', proc_limits)

        expect(described_class.max_open_file_descriptors).to eq(1024)
      end
    end

    describe '.memory_usage_uss_pss' do
      it "returns the process' unique and porportional set size (USS/PSS) in bytes" do
        mock_existing_proc_file('/proc/self/smaps_rollup', proc_smaps_rollup)

        # (Private_Clean (152 kB) + Private_Dirty (312 kB) + Private_Hugetlb (0 kB)) * 1024
        expect(described_class.memory_usage_uss_pss).to eq(uss: 475136, pss: 515072)
      end
    end

    describe '.summary' do
      it 'contains a selection of the available fields' do
        stub_const('RUBY_DESCRIPTION', 'ruby-3.0-patch1')
        mock_existing_proc_file('/proc/self/status', proc_status)
        mock_existing_proc_file('/proc/self/smaps_rollup', proc_smaps_rollup)

        summary = described_class.summary

        expect(summary[:version]).to eq('ruby-3.0-patch1')
        expect(summary[:gc_stat].keys).to eq(GC.stat.keys)
        expect(summary[:memory_rss]).to eq(2527232)
        expect(summary[:memory_uss]).to eq(475136)
        expect(summary[:memory_pss]).to eq(515072)
        expect(summary[:time_cputime]).to be_a(Float)
        expect(summary[:time_realtime]).to be_a(Float)
        expect(summary[:time_monotonic]).to be_a(Float)
      end
    end
  end

  context 'when /proc files do not exist' do
    before do
      mock_missing_proc_file
    end

    describe '.memory_usage_rss' do
      it 'returns 0' do
        expect(described_class.memory_usage_rss).to eq(0)
      end
    end

    describe '.memory_usage_uss_pss' do
      it "returns 0 for all components" do
        expect(described_class.memory_usage_uss_pss).to eq(uss: 0, pss: 0)
      end
    end

    describe '.file_descriptor_count' do
      it 'returns 0' do
        expect(Dir).to receive(:glob).and_return([])

        expect(described_class.file_descriptor_count).to eq(0)
      end
    end

    describe '.max_open_file_descriptors' do
      it 'returns 0' do
        expect(described_class.max_open_file_descriptors).to eq(0)
      end
    end

    describe '.summary' do
      it 'returns only available fields' do
        summary = described_class.summary

        expect(summary[:version]).to be_a(String)
        expect(summary[:gc_stat].keys).to eq(GC.stat.keys)
        expect(summary[:memory_rss]).to eq(0)
        expect(summary[:memory_uss]).to eq(0)
        expect(summary[:memory_pss]).to eq(0)
        expect(summary[:time_cputime]).to be_a(Float)
        expect(summary[:time_realtime]).to be_a(Float)
        expect(summary[:time_monotonic]).to be_a(Float)
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

  def mock_existing_proc_file(path, content)
    allow(File).to receive(:foreach).with(path) { |_path, &block| content.each_line(&block) }
  end

  def mock_missing_proc_file
    allow(File).to receive(:foreach).and_raise(Errno::ENOENT)
  end
end
