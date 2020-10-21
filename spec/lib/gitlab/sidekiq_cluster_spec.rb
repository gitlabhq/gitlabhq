# frozen_string_literal: true

require 'fast_spec_helper'
require 'rspec-parameterized'

RSpec.describe Gitlab::SidekiqCluster do
  describe '.trap_signals' do
    it 'traps the given signals' do
      expect(described_class).to receive(:trap).ordered.with(:INT)
      expect(described_class).to receive(:trap).ordered.with(:HUP)

      described_class.trap_signals(%i(INT HUP))
    end
  end

  describe '.trap_terminate' do
    it 'traps the termination signals' do
      expect(described_class).to receive(:trap_signals)
        .with(described_class::TERMINATE_SIGNALS)

      described_class.trap_terminate { }
    end
  end

  describe '.trap_forward' do
    it 'traps the signals to forward' do
      expect(described_class).to receive(:trap_signals)
        .with(described_class::FORWARD_SIGNALS)

      described_class.trap_forward { }
    end
  end

  describe '.signal' do
    it 'sends a signal to the given process' do
      allow(Process).to receive(:kill).with(:INT, 4)
      expect(described_class.signal(4, :INT)).to eq(true)
    end

    it 'returns false when the process does not exist' do
      allow(Process).to receive(:kill).with(:INT, 4).and_raise(Errno::ESRCH)
      expect(described_class.signal(4, :INT)).to eq(false)
    end
  end

  describe '.signal_processes' do
    it 'sends a signal to every given process' do
      expect(described_class).to receive(:signal).with(1, :INT)

      described_class.signal_processes([1], :INT)
    end
  end

  describe '.start' do
    it 'starts Sidekiq with the given queues, environment and options' do
      expected_options = {
        env: :production,
        directory: 'foo/bar',
        max_concurrency: 20,
        min_concurrency: 10,
        timeout: 25,
        dryrun: true
      }

      expect(described_class).to receive(:start_sidekiq).ordered.with(%w(foo), expected_options.merge(worker_id: 0))
      expect(described_class).to receive(:start_sidekiq).ordered.with(%w(bar baz), expected_options.merge(worker_id: 1))

      described_class.start([%w(foo), %w(bar baz)], env: :production, directory: 'foo/bar', max_concurrency: 20, min_concurrency: 10, dryrun: true)
    end

    it 'starts Sidekiq with the given queues and sensible default options' do
      expected_options = {
        env: :development,
        directory: an_instance_of(String),
        max_concurrency: 50,
        min_concurrency: 0,
        worker_id: an_instance_of(Integer),
        timeout: 25,
        dryrun: false
      }

      expect(described_class).to receive(:start_sidekiq).ordered.with(%w(foo bar baz), expected_options)
      expect(described_class).to receive(:start_sidekiq).ordered.with(%w(solo), expected_options)

      described_class.start([%w(foo bar baz), %w(solo)])
    end
  end

  describe '.start_sidekiq' do
    let(:first_worker_id) { 0 }
    let(:options) do
      { env: :production, directory: 'foo/bar', max_concurrency: 20, min_concurrency: 0, worker_id: first_worker_id, timeout: 10, dryrun: false }
    end

    let(:env) { { "ENABLE_SIDEKIQ_CLUSTER" => "1", "SIDEKIQ_WORKER_ID" => first_worker_id.to_s } }
    let(:args) { ['bundle', 'exec', 'sidekiq', anything, '-eproduction', '-t10', *([anything] * 5)] }

    it 'starts a Sidekiq process' do
      allow(Process).to receive(:spawn).and_return(1)

      expect(described_class).to receive(:wait_async).with(1)
      expect(described_class.start_sidekiq(%w(foo), **options)).to eq(1)
    end

    it 'handles duplicate queue names' do
      allow(Process)
        .to receive(:spawn)
        .with(env, *args, anything)
        .and_return(1)

      expect(described_class).to receive(:wait_async).with(1)
      expect(described_class.start_sidekiq(%w(foo foo bar baz), **options)).to eq(1)
    end

    it 'runs the sidekiq process in a new process group' do
      expect(Process)
        .to receive(:spawn)
        .with(anything, *args, a_hash_including(pgroup: true))
        .and_return(1)

      allow(described_class).to receive(:wait_async)
      expect(described_class.start_sidekiq(%w(foo bar baz), **options)).to eq(1)
    end
  end

  describe '.concurrency' do
    using RSpec::Parameterized::TableSyntax

    where(:queue_count, :min, :max, :expected) do
      2 | 0 | 0 | 3 # No min or max specified
      2 | 0 | 9 | 3 # No min specified, value < max
      2 | 1 | 4 | 3 # Value between min and max
      2 | 4 | 5 | 4 # Value below range
      5 | 2 | 3 | 3 # Value above range
      2 | 1 | 1 | 1 # Value above explicit setting (min == max)
      0 | 3 | 3 | 3 # Value below explicit setting (min == max)
      1 | 4 | 3 | 3 # Min greater than max
    end

    with_them do
      let(:queues) { Array.new(queue_count) }

      it { expect(described_class.concurrency(queues, min, max)).to eq(expected) }
    end
  end

  describe '.wait_async' do
    it 'waits for a process in a separate thread' do
      thread = described_class.wait_async(Process.spawn('true'))

      # Upon success Process.wait just returns the PID.
      expect(thread.value).to be_a_kind_of(Numeric)
    end
  end

  # In the X_alive? checks, we check negative PIDs sometimes as a simple way
  # to be sure the pids are definitely for non-existent processes.
  # Note that -1 is special, and sends the signal to every process we have permission
  # for, so we use -2, -3 etc
  describe '.all_alive?' do
    it 'returns true if all processes are alive' do
      processes = [Process.pid]

      expect(described_class.all_alive?(processes)).to eq(true)
    end

    it 'returns false when a thread was not alive' do
      processes = [-2]

      expect(described_class.all_alive?(processes)).to eq(false)
    end
  end

  describe '.any_alive?' do
    it 'returns true if at least one process is alive' do
      processes = [Process.pid, -2]

      expect(described_class.any_alive?(processes)).to eq(true)
    end

    it 'returns false when all threads are dead' do
      processes = [-2, -3]

      expect(described_class.any_alive?(processes)).to eq(false)
    end
  end

  describe '.write_pid' do
    it 'writes the PID of the current process to the given file' do
      handle = double(:handle)

      allow(File).to receive(:open).with('/dev/null', 'w').and_yield(handle)

      expect(handle).to receive(:write).with(Process.pid.to_s)

      described_class.write_pid('/dev/null')
    end
  end
end
