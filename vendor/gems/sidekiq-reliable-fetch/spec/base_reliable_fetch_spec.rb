require 'spec_helper'
require 'fetch_shared_examples'
require 'sidekiq/base_reliable_fetch'
require 'sidekiq/reliable_fetch'
require 'sidekiq/semi_reliable_fetch'
require 'sidekiq/interruptions_exhausted'
require 'sidekiq/capsule'

describe Sidekiq::BaseReliableFetch do
  let(:job) { Sidekiq.dump_json(class: 'Bob', args: [1, 2, 'foo'], jid: 55) }
  let(:queues) { ['foo'] }
  let(:options) { { queues: queues } }
  let(:config) { Sidekiq::Config.new(options) }
  let(:capsule) { Sidekiq::Capsule.new("default", config) }
  let(:fetcher) { Sidekiq::ReliableFetch.new(capsule) }

  before { Sidekiq.redis(&:flushdb) }

  describe 'UnitOfWork' do
    before { config.queues = queues }

    describe '#requeue' do
      it 'requeues job' do
        Sidekiq.redis { |conn| conn.rpush('queue:foo', job) }

        uow = fetcher.retrieve_work

        uow.requeue

        expect(Sidekiq::Queue.new('foo').size).to eq 1
        expect(working_queue_size('foo')).to eq 0
      end
    end

    describe '#acknowledge' do
      it 'acknowledges job' do
        Sidekiq.redis { |conn| conn.rpush('queue:foo', job) }

        uow = fetcher.retrieve_work

        expect { uow.acknowledge }
          .to change { working_queue_size('foo') }.by(-1)

        expect(Sidekiq::Queue.new('foo').size).to eq 0
      end
    end
  end

  describe '#bulk_requeue' do
    let(:queues) { %w[foo bar] }
    let!(:queue1) { Sidekiq::Queue.new('foo') }
    let!(:queue2) { Sidekiq::Queue.new('bar') }

    before { config.queues = queues }

    it 'requeues the bulk' do
      uow = described_class::UnitOfWork
      jobs = [ uow.new('queue:foo', job), uow.new('queue:foo', job), uow.new('queue:bar', job) ]

      jobs.map(&:queue).each do |q|
        expect(Sidekiq.logger).to receive(:info).with(
         message: "Pushed job 55 back to queue #{q}",
          jid: 55,
          class: 'Bob',
          queue: q
        )
      end

      described_class.new(capsule).bulk_requeue(jobs)

      expect(queue1.size).to eq 2
      expect(queue2.size).to eq 1
    end

    it 'puts jobs into interrupted queue' do
      stub_const 'Bob', Class.new

      uow = described_class::UnitOfWork
      interrupted_job = Sidekiq.dump_json(class: 'Bob', args: [1, 2, 'foo'], interrupted_count: 3)
      jobs = [ uow.new('queue:foo', interrupted_job), uow.new('queue:foo', job), uow.new('queue:bar', job) ]
      described_class.new(capsule).bulk_requeue(jobs)

      expect(queue1.size).to eq 1
      expect(queue2.size).to eq 1
      expect(Sidekiq::InterruptedSet.new.size).to eq 1
    end

    context 'when sidekiq_interruption_exhausted callback is defined' do
      before do
        stub_const 'Bob', Class.new

        Bob.class_eval do
          include Sidekiq::InterruptionsExhausted

          sidekiq_interruptions_exhausted do |msg|
            self.handle_interruptions_exhausted(msg)
          end

          # mock method to test interruptions exhausted behavior
          def self.handle_interruptions_exhausted(msg); end
        end
      end

      it 'calls sidekiq_interruption_exhausted callback and sends job to the InterruptedSet' do
        expect(Bob).to receive(:handle_interruptions_exhausted).with(
          { 'args' => [1, 2, 'foo'], 'class' => 'Bob', 'interrupted_count' => 4 }
        )

        uow = described_class::UnitOfWork
        interrupted_job = Sidekiq.dump_json(class: 'Bob', args: [1, 2, 'foo'], interrupted_count: 3)
        jobs = [uow.new('queue:foo', interrupted_job), uow.new('queue:foo', job), uow.new('queue:bar', job)]
        described_class.new(capsule).bulk_requeue(jobs)

        expect(queue1.size).to eq 1
        expect(queue2.size).to eq 1
        expect(Sidekiq::InterruptedSet.new.size).to eq 1
      end

      context 'when an exception is raised during the excecution of the sidekiq_interruptions_exhausted callback' do
        it 'logs the error and still sends job to the InterruptedSet' do
          expect(Bob).to receive(:handle_interruptions_exhausted).and_raise(StandardError, 'Error!')
          expect(Sidekiq.logger).to receive(:error).with(
            message: 'Failed to call sidekiq_interruption_exhausted',
            class: 'Bob',
            jid: nil,
            exception: {
              class: 'StandardError',
              message: 'Error!'
            }
          )

          uow = described_class::UnitOfWork
          interrupted_job = Sidekiq.dump_json(class: 'Bob', args: [1, 2, 'foo'], interrupted_count: 3)
          jobs = [ uow.new('queue:foo', interrupted_job), uow.new('queue:foo', job), uow.new('queue:bar', job)]
          described_class.new(capsule).bulk_requeue(jobs)

          expect(queue1.size).to eq 1
          expect(queue2.size).to eq 1
          expect(Sidekiq::InterruptedSet.new.size).to eq 1
        end
      end

      context 'when interrupted_count is less than max_retries_after_interruption' do
        it 'does not call sidekiq_interruption_exhausted callback' do
          expect(Bob).not_to receive(:handle_interruptions_exhausted)

          uow = described_class::UnitOfWork
          interrupted_job = Sidekiq.dump_json(class: 'Bob', args: [1, 2, 'foo'], interrupted_count: 1)
          jobs = [ uow.new('queue:foo', interrupted_job), uow.new('queue:foo', job), uow.new('queue:bar', job)]
          described_class.new(capsule).bulk_requeue(jobs)

          expect(queue1.size).to eq 2
          expect(queue2.size).to eq 1
          expect(Sidekiq::InterruptedSet.new.size).to eq 0
        end
      end
    end

    context 'when max_retries_after_interruption is disabled' do
      let(:options) { { queues: queues, max_retries_after_interruption: -1 } }

      it 'does not put jobs into interrupted queue' do
        uow = described_class::UnitOfWork
        interrupted_job = Sidekiq.dump_json(class: 'Bob', args: [1, 2, 'foo'], interrupted_count: 3)
        jobs = [ uow.new('queue:foo', interrupted_job), uow.new('queue:foo', job), uow.new('queue:bar', job) ]
        described_class.new(capsule).bulk_requeue(jobs)

        expect(queue1.size).to eq 2
        expect(queue2.size).to eq 1
        expect(Sidekiq::InterruptedSet.new.size).to eq 0
      end
    end

    it 'does not put jobs into interrupted queue if it is disabled on the worker' do
      stub_const('Bob', double(sidekiq_options: { 'max_retries_after_interruption' => -1 }))

      uow = described_class::UnitOfWork
      interrupted_job = Sidekiq.dump_json(class: 'Bob', args: [1, 2, 'foo'], interrupted_count: 3)
      jobs = [ uow.new('queue:foo', interrupted_job), uow.new('queue:foo', job), uow.new('queue:bar', job) ]
      described_class.new(capsule).bulk_requeue(jobs)

      expect(queue1.size).to eq 2
      expect(queue2.size).to eq 1
      expect(Sidekiq::InterruptedSet.new.size).to eq 0
    end
  end

  it 'sets heartbeat' do
    config = double(:sidekiq_config, options: { queues: %w[foo bar] })

    heartbeat_thread = described_class.setup_reliable_fetch!(config)

    Sidekiq.redis do |conn|
      sleep 0.2 # Give the time to heartbeat thread to make a loop

      heartbeat_key = described_class.heartbeat_key(described_class.identity)
      heartbeat = conn.get(heartbeat_key)

      expect(heartbeat).not_to be_nil
    end

    heartbeat_thread.kill
  end
end
