shared_examples 'a Sidekiq fetcher' do
  let(:queues) { ['assigned'] }
  let(:options) { { queues: queues } }
  let(:config) { Sidekiq::Config.new(options) }
  let(:capsule) { Sidekiq::Capsule.new("default", config) }

  before do
    config.queues = queues
    Sidekiq.redis(&:flushdb)
  end

  describe '#retrieve_work' do
    let(:job) { Sidekiq.dump_json(class: 'Bob', args: [1, 2, 'foo']) }
    let(:fetcher) { described_class.new(capsule) }

    it 'does not clean up orphaned jobs more than once per cleanup interval' do
      Sidekiq::Client.via(Sidekiq::RedisConnection.create(url: REDIS_URL, size: 10)) do
        expect(fetcher).to receive(:clean_working_queues!).once

        threads = 10.times.map do
          Thread.new do
            fetcher.retrieve_work
          end
        end

        threads.map(&:join)
      end
    end

    context 'when strictly order is enabled' do
      let(:queues) { ['first', 'second'] }
      let(:options) { { strict: true, queues: queues } }

      it 'retrieves by order' do
        fetcher = described_class.new(capsule)

        Sidekiq.redis do |conn|
          conn.rpush('queue:first', ['msg3', 'msg2', 'msg1'])
          conn.rpush('queue:second', 'msg4')
        end

        jobs = (1..4).map { fetcher.retrieve_work.job }

        expect(jobs).to eq ['msg1', 'msg2', 'msg3', 'msg4']
      end
    end

    context 'when queues are not strictly ordered' do
      let(:queues) { ['first', 'second'] }

      it 'does not starve any queue' do
        fetcher = described_class.new(capsule)

        Sidekiq.redis do |conn|
          conn.rpush('queue:first', (1..200).map { |i| "msg#{i}" })
          conn.rpush('queue:second', 'this_job_should_not_stuck')
        end

        jobs = (1..100).map { fetcher.retrieve_work.job }

        expect(jobs).to include 'this_job_should_not_stuck'
      end
    end

    shared_examples "basic queue handling" do |queue|
      let(:queues) { [queue] }
      let(:fetcher) { described_class.new(capsule) }

      it 'retrieves the job and puts it to working queue' do
        Sidekiq.redis { |conn| conn.rpush("queue:#{queue}", job) }

        uow = fetcher.retrieve_work

        expect(working_queue_size(queue)).to eq 1
        expect(uow.queue_name).to eq queue
        expect(uow.job).to eq job
        expect(Sidekiq::Queue.new(queue).size).to eq 0
      end

      it 'does not retrieve a job from foreign queue' do
        Sidekiq.redis { |conn| conn.rpush("'queue:#{queue}:not", job) }
        expect(fetcher.retrieve_work).to be_nil

        Sidekiq.redis { |conn| conn.rpush("'queue:not_#{queue}", job) }
        expect(fetcher.retrieve_work).to be_nil

        Sidekiq.redis { |conn| conn.rpush("'queue:random_name", job) }
        expect(fetcher.retrieve_work).to be_nil
      end

      it 'requeues jobs from legacy dead working queue with incremented interrupted_count' do
        Sidekiq.redis do |conn|
          conn.rpush(legacy_other_process_working_queue_name(queue), job)
        end

        expected_job = Sidekiq.load_json(job)
        expected_job['interrupted_count'] = 1
        expected_job = Sidekiq.dump_json(expected_job)

        uow = fetcher.retrieve_work

        expect(uow).to_not be_nil
        expect(uow.job).to eq expected_job

        Sidekiq.redis do |conn|
          expect(conn.llen(legacy_other_process_working_queue_name(queue))).to eq 0
        end
      end

      it 'ignores working queue keys in unknown formats' do
        # Add a spurious non-numeric char segment at the end; this simulates any other
        # incorrect form in general
        malformed_key = "#{other_process_working_queue_name(queue)}:X"
        Sidekiq.redis do |conn|
          conn.rpush(malformed_key, job)
        end

        uow = fetcher.retrieve_work

        Sidekiq.redis do |conn|
          expect(conn.llen(malformed_key)).to eq 1
        end
      end

      it 'requeues jobs from dead working queue with incremented interrupted_count' do
        Sidekiq.redis do |conn|
          conn.rpush(other_process_working_queue_name(queue), job)
        end

        expected_job = Sidekiq.load_json(job)
        expected_job['interrupted_count'] = 1
        expected_job = Sidekiq.dump_json(expected_job)

        uow = fetcher.retrieve_work

        expect(uow).to_not be_nil
        expect(uow.job).to eq expected_job

        Sidekiq.redis do |conn|
          expect(conn.llen(other_process_working_queue_name(queue))).to eq 0
        end
      end

      it 'does not requeue jobs from live working queue' do
        working_queue = live_other_process_working_queue_name(queue)

        Sidekiq.redis do |conn|
          conn.rpush(working_queue, job)
        end

        uow = fetcher.retrieve_work

        expect(uow).to be_nil

        Sidekiq.redis do |conn|
          expect(conn.llen(working_queue)).to eq 1
        end
      end
    end

    context 'with various queues' do
      %w[assigned namespace:assigned namespace:deeper:assigned].each do |queue|
        it_behaves_like "basic queue handling", queue
      end
    end

    context 'with short cleanup interval' do
      let(:short_interval) { 1 }
      let(:options) { { queues: queues, lease_interval: short_interval, cleanup_interval: short_interval } }
      let(:fetcher) { described_class.new(capsule) }

      it 'requeues when there is no heartbeat' do
        Sidekiq.redis { |conn| conn.rpush('queue:assigned', job) }
        # Use of retrieve_work twice with a sleep ensures we have exercised the
        # `identity` method to create the working queue key name and that it
        # matches the patterns used in the cleanup
        uow = fetcher.retrieve_work
        sleep(short_interval + 1)
        uow = fetcher.retrieve_work

        # Will only receive a UnitOfWork if the job was detected as failed and requeued
        expect(uow).to_not be_nil
      end
    end
  end
end

def working_queue_size(queue_name)
  Sidekiq.redis do |c|
    c.llen(Sidekiq::BaseReliableFetch.working_queue_name("queue:#{queue_name}"))
  end
end

def legacy_other_process_working_queue_name(queue)
  "#{Sidekiq::BaseReliableFetch::WORKING_QUEUE_PREFIX}:queue:#{queue}:#{Socket.gethostname}:#{::Process.pid + 1}"
end

def other_process_working_queue_name(queue)
  "#{Sidekiq::BaseReliableFetch::WORKING_QUEUE_PREFIX}:queue:#{queue}:#{Socket.gethostname}:#{::Process.pid + 1}:#{::SecureRandom.hex(6)}"
end

def live_other_process_working_queue_name(queue)
  pid = ::Process.pid + 1
  hostname = Socket.gethostname
  nonce = SecureRandom.hex(6)

  Sidekiq.redis do |conn|
    conn.set(Sidekiq::BaseReliableFetch.heartbeat_key("#{hostname}-#{pid}-#{nonce}"), 1)
  end

  "#{Sidekiq::BaseReliableFetch::WORKING_QUEUE_PREFIX}:queue:#{queue}:#{hostname}:#{pid}:#{nonce}"
end
