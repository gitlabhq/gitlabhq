# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::SidekiqDaemon::Monitor do
  let(:monitor) { described_class.new }

  describe '#within_job' do
    it 'tracks thread, jid and worker_class' do
      blk = proc do
        monitor.jobs do |jobs|
          jobs.each do |jid, job|
            expect(job[:thread]).not_to be_nil
            expect(jid).to eq('jid')
            expect(job[:worker_class]).to eq('worker_class')
          end
        end

        "OK"
      end

      expect(monitor.within_job('worker_class', 'jid', 'queue', &blk)).to eq("OK")
    end

    context 'when job is canceled' do
      let(:jid) { SecureRandom.hex }

      before do
        described_class.cancel_job(jid)
      end

      it 'does not execute a block' do
        expect do |blk|
          monitor.within_job('worker_class', jid, 'queue', &blk)
        rescue described_class::CancelledError
        end.not_to yield_control
      end

      it 'raises exception' do
        expect { monitor.within_job('worker_class', jid, 'queue') }.to raise_error(
          described_class::CancelledError)
      end
    end
  end

  describe '#jobs' do
    it 'returns running jobs hash' do
      jid = SecureRandom.hex
      running_jobs = { jid => hash_including(worker_class: 'worker_class') }

      monitor.within_job('worker_class', jid, 'queue') do
        expect(monitor.jobs).to match(running_jobs)
      end
    end
  end

  describe '#run_thread when notification channel not enabled' do
    subject { monitor.send(:run_thread) }

    it 'return directly' do
      allow(monitor).to receive(:notification_channel_enabled?).and_return(nil)

      expect(Sidekiq.logger).not_to receive(:info)
      expect(Sidekiq.logger).not_to receive(:warn)
      expect(monitor).not_to receive(:enabled?)
      expect(monitor).not_to receive(:process_messages)

      subject
    end
  end

  describe '#run_thread when notification channel enabled' do
    subject { monitor.send(:run_thread) }

    before do
      # we want to run at most once cycle
      # we toggle `enabled?` flag after the first call
      stub_const('Gitlab::SidekiqDaemon::Monitor::RECONNECT_TIME', 0)
      allow(monitor).to receive(:enabled?).and_return(true, false)
      allow(monitor).to receive(:notification_channel_enabled?).and_return(1)

      allow(Sidekiq.logger).to receive(:info)
      allow(Sidekiq.logger).to receive(:warn)
    end

    context 'when structured logging is used' do
      it 'logs start message' do
        expect(Sidekiq.logger).to receive(:info)
          .with(
            class: described_class.to_s,
            action: 'start',
            message: 'Starting Monitor Daemon')

        expect(::Gitlab::Redis::SharedState).to receive(:with)

        subject
      end

      it 'logs stop message' do
        expect(Sidekiq.logger).to receive(:warn)
          .with(
            class: described_class.to_s,
            action: 'stop',
            message: 'Stopping Monitor Daemon')

        expect(::Gitlab::Redis::SharedState).to receive(:with)

        subject
      end

      it 'logs StandardError message' do
        expect(Sidekiq.logger).to receive(:warn)
          .with(
            class: described_class.to_s,
            action: 'exception',
            message: 'My Exception')

        expect(::Gitlab::Redis::SharedState).to receive(:with)
          .and_raise(StandardError, 'My Exception')

        expect { subject }.not_to raise_error
      end

      it 'logs and raises Exception message' do
        expect(Sidekiq.logger).to receive(:warn)
          .with(
            class: described_class.to_s,
            action: 'exception',
            message: 'My Exception')

        expect(::Gitlab::Redis::SharedState).to receive(:with)
          .and_raise(Exception, 'My Exception')

        expect { subject }.to raise_error(Exception, 'My Exception')
      end
    end

    context 'when StandardError is raised' do
      it 'does retry connection' do
        expect(::Gitlab::Redis::SharedState).to receive(:with)
          .and_raise(StandardError, 'My Exception')

        expect(::Gitlab::Redis::SharedState).to receive(:with)

        # we expect to run `process_messages` twice
        expect(monitor).to receive(:enabled?).and_return(true, true, false)

        subject
      end
    end

    context 'when message is published' do
      let(:subscribed) { double }

      before do
        expect_any_instance_of(::Redis).to receive(:subscribe)
          .and_yield(subscribed)

        expect(subscribed).to receive(:message)
          .and_yield(
            described_class::NOTIFICATION_CHANNEL,
            payload
          )

        expect(Sidekiq.logger).to receive(:info)
          .with(
            class: described_class.to_s,
            action: 'start',
            message: 'Starting Monitor Daemon')

        expect(Sidekiq.logger).to receive(:info)
          .with(
            class: described_class.to_s,
            channel: described_class::NOTIFICATION_CHANNEL,
            message: 'Received payload on channel',
            payload: payload
          )
      end

      context 'and message is valid' do
        let(:payload) { '{"action":"cancel","jid":"my-jid"}' }

        it 'processes cancel' do
          expect(monitor).to receive(:process_job_cancel).with('my-jid')

          subject
        end
      end

      context 'and message is not valid json' do
        let(:payload) { '{"action"}' }

        it 'skips processing' do
          expect(monitor).not_to receive(:process_job_cancel)

          subject
        end
      end
    end
  end

  describe '#stop' do
    let!(:monitor_thread) { monitor.start }

    it 'does stop the thread' do
      expect(monitor_thread).to be_alive

      expect { monitor.stop }.not_to raise_error

      expect(monitor_thread).not_to be_alive
      expect { monitor_thread.value }.to raise_error(Interrupt)
    end
  end

  describe '#process_job_cancel' do
    subject { monitor.send(:process_job_cancel, jid) }

    context 'when jid is missing' do
      let(:jid) { nil }

      it 'does not run thread' do
        expect(subject).to be_nil
      end
    end

    context 'when jid is provided' do
      let(:jid) { 'my-jid' }

      context 'when jid is not found' do
        it 'does not log cancellation message' do
          expect(Sidekiq.logger).not_to receive(:warn)
          expect(subject).to be_nil
        end
      end

      context 'when jid is found' do
        let(:thread) { Thread.new { sleep 1000 } }

        before do
          allow(monitor).to receive(:find_thread_unsafe).with(jid).and_return(thread)
        end

        after do
          thread.kill
        rescue StandardError
        end

        it 'does log cancellation message' do
          expect(Sidekiq.logger).to receive(:warn)
            .with(
              class: described_class.to_s,
              action: 'cancel',
              message: 'Canceling thread with CancelledError',
              jid: 'my-jid',
              thread_id: thread.object_id)

          expect(subject).to be_a(Thread)

          subject.join
        end

        it 'does cancel the thread' do
          expect(subject).to be_a(Thread)

          subject.join

          # we wait for the thread to be cancelled
          # by `process_job_cancel`
          expect { thread.join(5) }.to raise_error(described_class::CancelledError)
        end
      end
    end
  end

  describe '.cancel_job' do
    subject { described_class.cancel_job('my-jid') }

    it 'sets a redis key' do
      expect_any_instance_of(::Redis).to receive(:setex)
        .with('sidekiq:cancel:my-jid', anything, 1)

      subject
    end

    it 'notifies all workers' do
      payload = '{"action":"cancel","jid":"my-jid"}'

      expect_any_instance_of(::Redis).to receive(:publish)
        .with('sidekiq:cancel:notifications', payload)

      subject
    end
  end

  describe '#notification_channel_enabled?' do
    subject { monitor.send(:notification_channel_enabled?) }

    it 'return nil when SIDEKIQ_MONITOR_WORKER is not set' do
      expect(subject).to be nil
    end

    it 'return nil when SIDEKIQ_MONITOR_WORKER set to 0' do
      allow(ENV).to receive(:fetch).with('SIDEKIQ_MONITOR_WORKER', 0).and_return("0")

      expect(subject).to be nil
    end

    it 'return 1 when SIDEKIQ_MONITOR_WORKER set to 1' do
      allow(ENV).to receive(:fetch).with('SIDEKIQ_MONITOR_WORKER', 0).and_return("1")

      expect(subject).to be 1
    end
  end
end
