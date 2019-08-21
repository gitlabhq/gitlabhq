# frozen_string_literal: true

require 'spec_helper'

describe Gitlab::SidekiqMonitor do
  let(:monitor) { described_class.new }

  describe '#within_job' do
    it 'tracks thread' do
      blk = proc do
        expect(monitor.jobs_thread['jid']).not_to be_nil

        "OK"
      end

      expect(monitor.within_job('jid', 'queue', &blk)).to eq("OK")
    end

    context 'when job is canceled' do
      let(:jid) { SecureRandom.hex }

      before do
        described_class.cancel_job(jid)
      end

      it 'does not execute a block' do
        expect do |blk|
          monitor.within_job(jid, 'queue', &blk)
        rescue described_class::CancelledError
        end.not_to yield_control
      end

      it 'raises exception' do
        expect { monitor.within_job(jid, 'queue') }.to raise_error(
          described_class::CancelledError)
      end
    end
  end

  describe '#start_working' do
    subject { monitor.send(:start_working) }

    before do
      # we want to run at most once cycle
      # we toggle `enabled?` flag after the first call
      stub_const('Gitlab::SidekiqMonitor::RECONNECT_TIME', 0)
      allow(monitor).to receive(:enabled?).and_return(true, false)

      allow(Sidekiq.logger).to receive(:info)
      allow(Sidekiq.logger).to receive(:warn)
    end

    context 'when structured logging is used' do
      it 'logs start message' do
        expect(Sidekiq.logger).to receive(:info)
          .with(
            class: described_class,
            action: 'start',
            message: 'Starting Monitor Daemon')

        expect(::Gitlab::Redis::SharedState).to receive(:with)

        subject
      end

      it 'logs stop message' do
        expect(Sidekiq.logger).to receive(:warn)
          .with(
            class: described_class,
            action: 'stop',
            message: 'Stopping Monitor Daemon')

        expect(::Gitlab::Redis::SharedState).to receive(:with)

        subject
      end

      it 'logs StandardError message' do
        expect(Sidekiq.logger).to receive(:warn)
          .with(
            class: described_class,
            action: 'exception',
            message: 'My Exception')

        expect(::Gitlab::Redis::SharedState).to receive(:with)
          .and_raise(StandardError, 'My Exception')

        expect { subject }.not_to raise_error
      end

      it 'logs and raises Exception message' do
        expect(Sidekiq.logger).to receive(:warn)
          .with(
            class: described_class,
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
            class: described_class,
            action: 'start',
            message: 'Starting Monitor Daemon')

        expect(Sidekiq.logger).to receive(:info)
          .with(
            class: described_class,
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
          monitor.jobs_thread[jid] = thread
        end

        after do
          thread.kill
        rescue
        end

        it 'does log cancellation message' do
          expect(Sidekiq.logger).to receive(:warn)
            .with(
              class: described_class,
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
end
