# frozen_string_literal: true

require_relative '../../../lib/gitlab/process_management'

RSpec.describe Gitlab::ProcessManagement do
  describe '.trap_signals' do
    it 'traps the given signals' do
      expect(described_class).to receive(:trap).ordered.with(:INT)
      expect(described_class).to receive(:trap).ordered.with(:HUP)

      described_class.trap_signals(%i[INT HUP])
    end
  end

  describe '.modify_signals' do
    it 'traps the given signals with the given command' do
      expect(described_class).to receive(:trap).ordered.with(:INT, 'DEFAULT')
      expect(described_class).to receive(:trap).ordered.with(:HUP, 'DEFAULT')

      described_class.modify_signals(%i[INT HUP], 'DEFAULT')
    end
  end

  describe '.signal_processes' do
    it 'sends a signal to every given process' do
      expect(described_class).to receive(:signal).with(1, :INT)

      described_class.signal_processes([1], :INT)
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

  describe '.process_alive?' do
    it 'returns true if the process is alive' do
      process = Process.pid

      expect(described_class.process_alive?(process)).to eq(true)
    end

    it 'returns false when a thread was not alive' do
      process = -2

      expect(described_class.process_alive?(process)).to eq(false)
    end

    it 'returns false when no pid is given' do
      process = nil

      expect(described_class.process_alive?(process)).to eq(false)
    end
  end

  describe '.process_died?' do
    it 'returns false if the process is alive' do
      process = Process.pid

      expect(described_class.process_died?(process)).to eq(false)
    end

    it 'returns true when a thread was not alive' do
      process = -2

      expect(described_class.process_died?(process)).to eq(true)
    end

    it 'returns true when no pid is given' do
      process = nil

      expect(described_class.process_died?(process)).to eq(true)
    end
  end

  describe '.pids_alive' do
    it 'returns the pids that are alive, from a given array' do
      pids = [Process.pid, -2]

      expect(described_class.pids_alive(pids)).to match_array([Process.pid])
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
