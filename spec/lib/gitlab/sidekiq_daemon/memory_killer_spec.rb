# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::SidekiqDaemon::MemoryKiller do
  let(:memory_killer) { described_class.new }
  let(:pid) { 12345 }

  before do
    allow(Sidekiq.logger).to receive(:info)
    allow(Sidekiq.logger).to receive(:warn)
    allow(memory_killer).to receive(:pid).and_return(pid)

    # make sleep no-op
    allow(memory_killer).to receive(:sleep) {}
  end

  describe '#run_thread' do
    subject { memory_killer.send(:run_thread) }

    before do
      # let enabled? return 3 times: true, true, false
      allow(memory_killer).to receive(:enabled?).and_return(true, true, false)
    end

    context 'when structured logging is used' do
      it 'logs start message once' do
        expect(Sidekiq.logger).to receive(:info).once
          .with(
            class: described_class.to_s,
            action: 'start',
            pid: pid,
            message: 'Starting Gitlab::SidekiqDaemon::MemoryKiller Daemon')

        subject
      end

      it 'logs StandardError message twice' do
        expect(Sidekiq.logger).to receive(:warn).twice
          .with(
            class: described_class.to_s,
            pid: pid,
            message: "Exception from run_thread: My Exception")

        expect(memory_killer).to receive(:rss_within_range?)
          .twice
          .and_raise(StandardError, 'My Exception')

        expect { subject }.not_to raise_exception
      end

      it 'logs exception message once and raise exception and log stop message' do
        expect(Sidekiq.logger).to receive(:warn).once
          .with(
            class: described_class.to_s,
            pid: pid,
            message: "Exception from run_thread: My Exception")

        expect(memory_killer).to receive(:rss_within_range?)
          .once
          .and_raise(Exception, 'My Exception')

        expect(memory_killer).to receive(:sleep).with(Gitlab::SidekiqDaemon::MemoryKiller::CHECK_INTERVAL_SECONDS)
        expect(Sidekiq.logger).to receive(:warn).once
          .with(
            class: described_class.to_s,
            action: 'stop',
            pid: pid,
            message: 'Stopping Gitlab::SidekiqDaemon::MemoryKiller Daemon')

        expect { subject }.to raise_exception(Exception, 'My Exception')
      end

      it 'logs stop message once' do
        expect(Sidekiq.logger).to receive(:warn).once
          .with(
            class: described_class.to_s,
            action: 'stop',
            pid: pid,
            message: 'Stopping Gitlab::SidekiqDaemon::MemoryKiller Daemon')

        subject
      end
    end

    it 'not invoke restart_sidekiq when rss in range' do
      expect(memory_killer).to receive(:rss_within_range?)
        .twice
        .and_return(true)

      expect(memory_killer).not_to receive(:restart_sidekiq)

      subject
    end

    it 'invoke restart_sidekiq when rss not in range' do
      expect(memory_killer).to receive(:rss_within_range?)
        .at_least(:once)
        .and_return(false)

      expect(memory_killer).to receive(:restart_sidekiq)
        .at_least(:once)

      subject
    end
  end

  describe '#stop_working' do
    subject { memory_killer.send(:stop_working)}

    it 'changes enable? to false' do
      expect { subject }.to change { memory_killer.send(:enabled?) }
        .from(true).to(false)
    end
  end

  describe '#rss_within_range?' do
    let(:shutdown_timeout_seconds) { 7 }
    let(:check_interval_seconds) { 2 }
    let(:grace_balloon_seconds) { 5 }

    subject { memory_killer.send(:rss_within_range?) }

    before do
      stub_const("#{described_class}::SHUTDOWN_TIMEOUT_SECONDS", shutdown_timeout_seconds)
      stub_const("#{described_class}::CHECK_INTERVAL_SECONDS", check_interval_seconds)
      stub_const("#{described_class}::GRACE_BALLOON_SECONDS", grace_balloon_seconds)
      allow(Process).to receive(:getpgrp).and_return(pid)
      allow(Sidekiq).to receive(:options).and_return(timeout: 9)
    end

    it 'return true when everything is within limit' do
      expect(memory_killer).to receive(:get_rss).and_return(100)
      expect(memory_killer).to receive(:get_soft_limit_rss).and_return(200)
      expect(memory_killer).to receive(:get_hard_limit_rss).and_return(300)

      expect(memory_killer).to receive(:refresh_state)
        .with(:running)
        .and_call_original

      expect(Gitlab::Metrics::System).to receive(:monotonic_time).and_call_original
      expect(memory_killer).not_to receive(:log_rss_out_of_range)

      expect(subject).to be true
    end

    it 'return false when rss exceeds hard_limit_rss' do
      expect(memory_killer).to receive(:get_rss).at_least(:once).and_return(400)
      expect(memory_killer).to receive(:get_soft_limit_rss).at_least(:once).and_return(200)
      expect(memory_killer).to receive(:get_hard_limit_rss).at_least(:once).and_return(300)

      expect(memory_killer).to receive(:refresh_state)
        .with(:running)
        .and_call_original

      expect(memory_killer).to receive(:refresh_state)
        .with(:above_soft_limit)
        .and_call_original

      expect(Gitlab::Metrics::System).to receive(:monotonic_time).and_call_original

      expect(memory_killer).to receive(:log_rss_out_of_range).with(400, 300, 200)

      expect(subject).to be false
    end

    it 'return false when rss exceed hard_limit_rss after a while' do
      expect(memory_killer).to receive(:get_rss).and_return(250, 400, 400)
      expect(memory_killer).to receive(:get_soft_limit_rss).at_least(:once).and_return(200)
      expect(memory_killer).to receive(:get_hard_limit_rss).at_least(:once).and_return(300)

      expect(memory_killer).to receive(:refresh_state)
        .with(:running)
        .and_call_original

      expect(memory_killer).to receive(:refresh_state)
        .at_least(:once)
        .with(:above_soft_limit)
        .and_call_original

      expect(Gitlab::Metrics::System).to receive(:monotonic_time).twice.and_call_original
      expect(memory_killer).to receive(:sleep).with(check_interval_seconds)
      expect(memory_killer).to receive(:log_rss_out_of_range).with(400, 300, 200)

      expect(subject).to be false
    end

    it 'return true when rss below soft_limit_rss after a while within GRACE_BALLOON_SECONDS' do
      expect(memory_killer).to receive(:get_rss).and_return(250, 100)
      expect(memory_killer).to receive(:get_soft_limit_rss).and_return(200, 200)
      expect(memory_killer).to receive(:get_hard_limit_rss).and_return(300, 300)

      expect(memory_killer).to receive(:refresh_state)
        .with(:running)
        .and_call_original

      expect(memory_killer).to receive(:refresh_state)
        .with(:above_soft_limit)
        .and_call_original

      expect(Gitlab::Metrics::System).to receive(:monotonic_time).twice.and_call_original
      expect(memory_killer).to receive(:sleep).with(check_interval_seconds)

      expect(memory_killer).not_to receive(:log_rss_out_of_range)

      expect(subject).to be true
    end

    context 'when exceeding GRACE_BALLOON_SECONDS' do
      let(:grace_balloon_seconds) { 0 }

      it 'return false when rss exceed soft_limit_rss' do
        allow(memory_killer).to receive(:get_rss).and_return(250)
        allow(memory_killer).to receive(:get_soft_limit_rss).and_return(200)
        allow(memory_killer).to receive(:get_hard_limit_rss).and_return(300)

        expect(memory_killer).to receive(:refresh_state)
          .with(:running)
          .and_call_original

        expect(memory_killer).to receive(:refresh_state)
          .with(:above_soft_limit)
          .and_call_original

        expect(memory_killer).to receive(:log_rss_out_of_range)
          .with(250, 300, 200)

        expect(subject).to be false
      end
    end
  end

  describe '#restart_sidekiq' do
    let(:shutdown_timeout_seconds) { 7 }

    subject { memory_killer.send(:restart_sidekiq) }

    before do
      stub_const("#{described_class}::SHUTDOWN_TIMEOUT_SECONDS", shutdown_timeout_seconds)
      allow(Sidekiq).to receive(:options).and_return(timeout: 9)
      allow(memory_killer).to receive(:get_rss).and_return(100)
      allow(memory_killer).to receive(:get_soft_limit_rss).and_return(200)
      allow(memory_killer).to receive(:get_hard_limit_rss).and_return(300)
    end

    it 'send signal' do
      expect(memory_killer).to receive(:refresh_state)
        .with(:stop_fetching_new_jobs)
        .ordered
        .and_call_original
      expect(memory_killer).to receive(:signal_and_wait)
        .with(shutdown_timeout_seconds, 'SIGTSTP', 'stop fetching new jobs')
        .ordered

      expect(memory_killer).to receive(:refresh_state)
        .with(:shutting_down)
        .ordered
        .and_call_original
      expect(memory_killer).to receive(:signal_and_wait)
        .with(11, 'SIGTERM', 'gracefully shut down')
        .ordered

      expect(memory_killer).to receive(:refresh_state)
        .with(:killing_sidekiq)
        .ordered
        .and_call_original
      expect(memory_killer).to receive(:signal_pgroup)
        .with('SIGKILL', 'die')
        .ordered

      subject
    end
  end

  describe '#signal_and_wait' do
    let(:time) { 0 }
    let(:signal) { 'my-signal' }
    let(:explanation) { 'my-explanation' }
    let(:check_interval_seconds) { 2 }

    subject { memory_killer.send(:signal_and_wait, time, signal, explanation) }

    before do
      stub_const("#{described_class}::CHECK_INTERVAL_SECONDS", check_interval_seconds)
    end

    it 'send signal and return when all jobs finished' do
      expect(Process).to receive(:kill).with(signal, pid).ordered
      expect(Gitlab::Metrics::System).to receive(:monotonic_time).and_call_original

      expect(memory_killer).to receive(:enabled?).and_return(true)
      expect(memory_killer).to receive(:any_jobs?).and_return(false)

      expect(memory_killer).not_to receive(:sleep)

      subject
    end

    it 'send signal and wait till deadline if any job not finished' do
      expect(Process).to receive(:kill)
        .with(signal, pid)
        .ordered

      expect(Gitlab::Metrics::System).to receive(:monotonic_time)
        .and_call_original
        .at_least(:once)

      expect(memory_killer).to receive(:enabled?).and_return(true).at_least(:once)
      expect(memory_killer).to receive(:any_jobs?).and_return(true).at_least(:once)

      subject
    end
  end

  describe '#signal_pgroup' do
    let(:signal) { 'my-signal' }
    let(:explanation) { 'my-explanation' }

    subject { memory_killer.send(:signal_pgroup, signal, explanation) }

    it 'send signal to this proces if it is not group leader' do
      expect(Process).to receive(:getpgrp).and_return(pid + 1)

      expect(Sidekiq.logger).to receive(:warn).once
        .with(
          class: described_class.to_s,
          signal: signal,
          pid: pid,
          message:   "sending Sidekiq worker PID-#{pid} #{signal} (#{explanation})")
      expect(Process).to receive(:kill).with(signal, pid).ordered

      subject
    end

    it 'send signal to whole process group as group leader' do
      expect(Process).to receive(:getpgrp).and_return(pid)

      expect(Sidekiq.logger).to receive(:warn).once
        .with(
          class: described_class.to_s,
          signal: signal,
          pid: pid,
          message:   "sending Sidekiq worker PGRP-#{pid} #{signal} (#{explanation})")
      expect(Process).to receive(:kill).with(signal, 0).ordered

      subject
    end
  end

  describe '#log_rss_out_of_range' do
    let(:current_rss) { 100 }
    let(:soft_limit_rss) { 200 }
    let(:hard_limit_rss) { 300 }
    let(:reason) { 'rss out of range reason description' }

    subject { memory_killer.send(:log_rss_out_of_range, current_rss, hard_limit_rss, soft_limit_rss) }

    it 'invoke sidekiq logger warn' do
      expect(memory_killer).to receive(:out_of_range_description).with(current_rss, hard_limit_rss, soft_limit_rss).and_return(reason)
      expect(Sidekiq.logger).to receive(:warn)
        .with(
          class: described_class.to_s,
          pid: pid,
          message: 'Sidekiq worker RSS out of range',
          current_rss: current_rss,
          hard_limit_rss: hard_limit_rss,
          soft_limit_rss: soft_limit_rss,
          reason: reason)

      subject
    end
  end

  describe '#out_of_range_description' do
    let(:hard_limit) { 300 }
    let(:soft_limit) { 200 }
    let(:grace_balloon_seconds) { 12 }

    subject { memory_killer.send(:out_of_range_description, rss, hard_limit, soft_limit) }

    context 'when rss > hard_limit' do
      let(:rss) { 400 }

      it 'tells reason' do
        expect(subject).to eq("current_rss(#{rss}) > hard_limit_rss(#{hard_limit})")
      end
    end

    context 'when rss <= hard_limit' do
      let(:rss) { 300 }

      it 'tells reason' do
        stub_const("#{described_class}::GRACE_BALLOON_SECONDS", grace_balloon_seconds)
        expect(subject).to eq("current_rss(#{rss}) > soft_limit_rss(#{soft_limit}) longer than GRACE_BALLOON_SECONDS(#{grace_balloon_seconds})")
      end
    end
  end

  describe '#rss_increase_by_jobs' do
    let(:running_jobs) { { id1: 'job1', id2: 'job2' } }

    subject { memory_killer.send(:rss_increase_by_jobs) }

    it 'adds up individual rss_increase_by_job' do
      allow(Gitlab::SidekiqDaemon::Monitor).to receive_message_chain(:instance, :jobs_mutex, :synchronize).and_yield
      expect(Gitlab::SidekiqDaemon::Monitor).to receive_message_chain(:instance, :jobs).and_return(running_jobs)
      expect(memory_killer).to receive(:rss_increase_by_job).and_return(11, 22)
      expect(subject).to eq(33)
    end

    it 'return 0 if no job' do
      allow(Gitlab::SidekiqDaemon::Monitor).to receive_message_chain(:instance, :jobs_mutex, :synchronize).and_yield
      expect(Gitlab::SidekiqDaemon::Monitor).to receive_message_chain(:instance, :jobs).and_return({})
      expect(subject).to eq(0)
    end
  end

  describe '#rss_increase_by_job' do
    let(:worker_class) { Chaos::SleepWorker }
    let(:job) { { worker_class: worker_class, started_at: 321 } }
    let(:max_memory_kb) { 100000 }

    subject { memory_killer.send(:rss_increase_by_job, job) }

    before do
      stub_const("#{described_class}::DEFAULT_MAX_MEMORY_GROWTH_KB", max_memory_kb)
    end

    it 'return 0 if memory_growth_kb return 0' do
      expect(memory_killer).to receive(:get_job_options).with(job, 'memory_killer_memory_growth_kb', 0).and_return(0)
      expect(memory_killer).to receive(:get_job_options).with(job, 'memory_killer_max_memory_growth_kb', max_memory_kb).and_return(0)

      expect(Time).not_to receive(:now)
      expect(subject).to eq(0)
    end

    it 'return time factored growth value when it does not exceed max growth limit for whilited job' do
      expect(memory_killer).to receive(:get_job_options).with(job, 'memory_killer_memory_growth_kb', 0).and_return(10)
      expect(memory_killer).to receive(:get_job_options).with(job, 'memory_killer_max_memory_growth_kb', max_memory_kb).and_return(100)

      expect(Gitlab::Metrics::System).to receive(:monotonic_time).and_return(323)
      expect(subject).to eq(20)
    end

    it 'return max growth limit when time factored growth value exceed max growth limit for whilited job' do
      expect(memory_killer).to receive(:get_job_options).with(job, 'memory_killer_memory_growth_kb', 0).and_return(10)
      expect(memory_killer).to receive(:get_job_options).with(job, 'memory_killer_max_memory_growth_kb', max_memory_kb).and_return(100)

      expect(Gitlab::Metrics::System).to receive(:monotonic_time).and_return(332)
      expect(subject).to eq(100)
    end
  end

  describe '#get_job_options' do
    let(:worker_class) { Chaos::SleepWorker }
    let(:job) { { worker_class: worker_class, started_at: 321 } }
    let(:key) { 'my-key' }
    let(:default) { 'my-default' }

    subject { memory_killer.send(:get_job_options, job, key, default) }

    it 'return default if key is not defined' do
      expect(worker_class).to receive(:sidekiq_options).and_return({ "retry" => 5 })

      expect(subject).to eq(default)
    end

    it 'return default if get StandardError when retrieve sidekiq_options' do
      expect(worker_class).to receive(:sidekiq_options).and_raise(StandardError)

      expect(subject).to eq(default)
    end

    it 'return right value if sidekiq_options has the key' do
      expect(worker_class).to receive(:sidekiq_options).and_return({ key => 10 })

      expect(subject).to eq(10)
    end
  end

  describe '#refresh_state' do
    let(:metrics) { memory_killer.instance_variable_get(:@metrics) }

    subject { memory_killer.send(:refresh_state, :shutting_down) }

    it 'calls gitlab metrics gauge set methods' do
      expect(memory_killer).to receive(:get_rss) { 1010 }
      expect(memory_killer).to receive(:get_soft_limit_rss) { 1020 }
      expect(memory_killer).to receive(:get_hard_limit_rss) { 1040 }

      expect(metrics[:sidekiq_memory_killer_phase]).to receive(:set)
        .with({}, described_class::PHASE[:shutting_down])
      expect(metrics[:sidekiq_current_rss]).to receive(:set)
        .with({}, 1010)
      expect(metrics[:sidekiq_memory_killer_soft_limit_rss]).to receive(:set)
        .with({}, 1020)
      expect(metrics[:sidekiq_memory_killer_hard_limit_rss]).to receive(:set)
        .with({}, 1040)

      subject
    end
  end
end
