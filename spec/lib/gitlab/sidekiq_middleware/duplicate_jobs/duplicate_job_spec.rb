# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::SidekiqMiddleware::DuplicateJobs::DuplicateJob,
  :clean_gitlab_redis_queues_metadata, feature_category: :shared do
  using RSpec::Parameterized::TableSyntax

  subject(:duplicate_job) do
    described_class.new(job, queue)
  end

  let(:wal_locations) do
    {
      'main' => '0/D525E3A8',
      'ci' => 'AB/12345'
    }
  end

  let(:job) { { 'class' => 'AuthorizedProjectsWorker', 'args' => [1], 'jid' => '123', 'wal_locations' => wal_locations } }
  let(:queue) { 'authorized_projects' }

  let(:idempotency_key) do
    hash = Digest::SHA256.hexdigest("#{job['class']}:#{Sidekiq.dump_json(job['args'])}")
    "#{Gitlab::Redis::Queues::SIDEKIQ_NAMESPACE}:duplicate:#{queue}:#{hash}"
  end

  describe '#schedule' do
    shared_examples 'scheduling with deduplication class' do |strategy_class|
      it 'calls schedule on the strategy' do
        expect do |block|
          expect_next_instance_of("Gitlab::SidekiqMiddleware::DuplicateJobs::Strategies::#{strategy_class}".constantize) do |strategy|
            expect(strategy).to receive(:schedule).with(job, &block)
          end

          duplicate_job.schedule(&block)
        end.to yield_control
      end
    end

    it_behaves_like 'scheduling with deduplication class', 'UntilExecuted'

    context 'when the deduplication depends on a FF' do
      before do
        skip_default_enabled_yaml_check

        allow(AuthorizedProjectsWorker).to receive(:get_deduplication_options).and_return(feature_flag: :my_feature_flag)
      end

      context 'when the feature flag is enabled' do
        before do
          stub_feature_flags(my_feature_flag: true)
        end

        it_behaves_like 'scheduling with deduplication class', 'UntilExecuted'
      end

      context 'when the feature flag is disabled' do
        before do
          stub_feature_flags(my_feature_flag: false)
        end

        it_behaves_like 'scheduling with deduplication class', 'None'
      end
    end
  end

  describe '#perform' do
    it 'calls perform on the strategy' do
      expect do |block|
        expect_next_instance_of(Gitlab::SidekiqMiddleware::DuplicateJobs::Strategies::UntilExecuted) do |strategy|
          expect(strategy).to receive(:perform).with(job, &block)
        end

        duplicate_job.perform(&block)
      end.to yield_control
    end
  end

  context 'with Redis cookies' do
    def with_redis(&block)
      Gitlab::Redis::QueuesMetadata.with(&block)
    end

    let(:cookie_key) { "#{Gitlab::Redis::Queues::SIDEKIQ_NAMESPACE}:#{idempotency_key}:cookie:v2" }
    let(:cookie) { duplicate_job.send(:get_cookie) }

    describe '#check!' do
      context 'when there was no job in the queue yet' do
        it { expect(duplicate_job.check!).to eq('123') }

        shared_examples 'sets Redis keys with correct TTL' do
          it "adds an idempotency key with correct ttl" do
            expected_cookie = {
              'jid' => '123',
              'offsets' => {},
              'wal_locations' => {},
              'existing_wal_locations' => wal_locations
            }

            duplicate_job.check!
            expect(cookie).to eq(expected_cookie)
            expect(redis_ttl(cookie_key)).to be_within(1).of(expected_ttl)
          end
        end

        context 'when TTL option is not set' do
          let(:expected_ttl) { described_class::DEFAULT_DUPLICATE_KEY_TTL }

          it_behaves_like 'sets Redis keys with correct TTL'
        end

        context 'when TTL option is set' do
          let(:expected_ttl) { 5.minutes }

          before do
            allow(duplicate_job).to receive(:options).and_return({ ttl: expected_ttl })
          end

          it_behaves_like 'sets Redis keys with correct TTL'
        end

        it "adds the idempotency key to the jobs payload" do
          expect { duplicate_job.check! }.to change { job['idempotency_key'] }.from(nil).to(idempotency_key)
        end
      end

      context 'when there was already a job with same arguments in the same queue' do
        before do
          set_idempotency_key(cookie_key, existing_cookie.to_msgpack)
        end

        let(:existing_cookie) { { 'jid' => 'existing-jid' } }

        it { expect(duplicate_job.check!).to eq('existing-jid') }

        it "does not change the existing key's TTL" do
          expect { duplicate_job.check! }
            .not_to change { redis_ttl(cookie_key) }
                  .from(-1)
        end

        it 'sets the existing jid' do
          duplicate_job.check!

          expect(duplicate_job.existing_jid).to eq('existing-jid')
        end
      end
    end

    describe '#update_latest_wal_location!' do
      before do
        allow(Gitlab::Database).to receive(:database_base_models).and_return(
          { main: ::ActiveRecord::Base,
            ci: ::ActiveRecord::Base })

        with_redis { |r| r.set(cookie_key, initial_cookie.to_msgpack, ex: expected_ttl) }

        # read existing_wal_locations
        duplicate_job.check!
      end

      let(:initial_cookie) do
        {
          'jid' => 'foobar',
          'existing_wal_locations' => { 'main' => '0/D525E3A0', 'ci' => 'AB/12340' },
          'offsets' => {},
          'wal_locations' => {}
        }
      end

      let(:expected_ttl) { 123 }
      let(:new_wal) do
        {
          # offset is relative to `existing_wal`
          'main' => { location: '0/D525E3A8', offset: '8' },
          'ci' => { location: 'AB/12345', offset: '5' }
        }
      end

      let(:wal_locations) { new_wal.transform_values { |v| v[:location] } }

      it 'stores a wal location to redis with an offset relative to existing wal location' do
        duplicate_job.update_latest_wal_location!

        expect(cookie['wal_locations']).to eq(wal_locations)
        expect(cookie['offsets']).to eq(new_wal.transform_values { |v| v[:offset].to_i })
        expect(redis_ttl(cookie_key)).to be_within(1).of(expected_ttl)
      end
    end

    describe '#latest_wal_locations' do
      context 'when job was deduplicated and wal locations were already persisted' do
        before do
          cookie = { 'wal_locations' => { 'main' => 'abc', 'ci' => 'def' } }.to_msgpack
          set_idempotency_key(cookie_key, cookie)
        end

        it { expect(duplicate_job.latest_wal_locations).to eq({ 'main' => 'abc', 'ci' => 'def' }) }
      end

      context 'when job is not deduplication and wal locations were not persisted' do
        it { expect(duplicate_job.latest_wal_locations).to be_empty }
      end
    end

    describe '#delete!' do
      context "when we didn't track the definition" do
        it { expect { duplicate_job.delete! }.not_to raise_error }
      end

      context 'when the key exists in redis' do
        before do
          set_idempotency_key(cookie_key, "garbage")
        end

        shared_examples 'deleting the duplicate job' do
          shared_examples 'deleting keys from redis' do |key_name|
            it "removes the #{key_name} from redis" do
              expect { duplicate_job.delete! }
                .to change { with_redis { |r| r.get(key) } }
                      .from(from_value)
                      .to(nil)
            end
          end

          it_behaves_like 'deleting keys from redis', 'cookie key' do
            let(:key) { cookie_key }
            let(:from_value) { "garbage" }
          end
        end

        context 'when the idempotency key is not part of the job' do
          it_behaves_like 'deleting the duplicate job'

          it 'recalculates the idempotency hash' do
            expect(duplicate_job).to receive(:idempotency_hash).and_call_original

            duplicate_job.delete!
          end
        end

        context 'when the idempotency key is part of the job' do
          let(:idempotency_key) { 'not the same as what we calculate' }
          let(:job) { super().merge('idempotency_key' => idempotency_key) }

          it_behaves_like 'deleting the duplicate job'

          it 'does not recalculate the idempotency hash' do
            expect(duplicate_job).not_to receive(:idempotency_hash)

            duplicate_job.delete!
          end
        end
      end
    end

    describe '#duplicate?' do
      it "raises an error if the check wasn't performed" do
        expect { duplicate_job.duplicate? }.to raise_error(/Call `#check!` first/)
      end

      it 'returns false if the existing jid equals the job jid' do
        duplicate_job.check!

        expect(duplicate_job.duplicate?).to be(false)
      end

      it 'returns true if the existing jid is different from the job jid' do
        set_idempotency_key(cookie_key, { 'jid' => 'a different jid' }.to_msgpack)
        duplicate_job.check!

        expect(duplicate_job.duplicate?).to be(true)
      end
    end

    def set_idempotency_key(key, value)
      with_redis { |r| r.set(key, value) }
    end

    def get_redis_msgpack(key)
      MessagePack.unpack(with_redis { |redis| redis.get(key) })
    end

    def redis_ttl(key)
      with_redis { |redis| redis.ttl(key) }
    end
  end

  describe '#scheduled?' do
    it 'returns false for non-scheduled jobs' do
      expect(duplicate_job.scheduled?).to be(false)
    end

    context 'scheduled jobs' do
      let(:job) do
        { 'class' => 'AuthorizedProjectsWorker',
          'args' => [1],
          'jid' => '123',
          'at' => 42 }
      end

      it 'returns true' do
        expect(duplicate_job.scheduled?).to be(true)
      end
    end
  end

  describe '#reschedule' do
    it 'reschedules the current job' do
      fake_logger = instance_double(Gitlab::SidekiqLogging::DeduplicationLogger)
      expect(Gitlab::SidekiqLogging::DeduplicationLogger).to receive(:instance).and_return(fake_logger)
      expect(fake_logger).to receive(:rescheduled_log).with(a_hash_including({ 'jid' => '123' }))
      expect(AuthorizedProjectsWorker).to receive_message_chain(:rescheduled_once, :perform_async)

      duplicate_job.reschedule
    end
  end

  describe '#scheduled_at' do
    let(:scheduled_at) { 42 }
    let(:job) do
      { 'class' => 'AuthorizedProjectsWorker',
        'args' => [1],
        'jid' => '123',
        'at' => scheduled_at }
    end

    it 'returns when the job is scheduled at' do
      expect(duplicate_job.scheduled_at).to eq(scheduled_at)
    end
  end

  describe '#options' do
    let(:worker_options) { { foo: true } }

    it 'returns worker options' do
      allow(AuthorizedProjectsWorker).to(
        receive(:get_deduplication_options).and_return(worker_options))

      expect(duplicate_job.options).to eq(worker_options)
    end
  end

  describe '#idempotent?' do
    context 'when worker class does not exist' do
      let(:job) { { 'class' => '' } }

      it 'returns false' do
        expect(duplicate_job).not_to be_idempotent
      end
    end

    context 'when worker class does not respond to #idempotent?' do
      before do
        stub_const('AuthorizedProjectsWorker', Class.new)
      end

      it 'returns false' do
        expect(duplicate_job).not_to be_idempotent
      end
    end

    context 'when worker class is not idempotent' do
      before do
        allow(AuthorizedProjectsWorker).to receive(:idempotent?).and_return(false)
      end

      it 'returns false' do
        expect(duplicate_job).not_to be_idempotent
      end
    end

    context 'when worker class is idempotent' do
      before do
        allow(AuthorizedProjectsWorker).to receive(:idempotent?).and_return(true)
      end

      it 'returns true' do
        expect(duplicate_job).to be_idempotent
      end
    end

    context 'when worker class is utilizing load balancing capabilities' do
      before do
        allow(AuthorizedProjectsWorker).to receive(:utilizes_load_balancing_capabilities?).and_return(true)
      end

      it 'returns true' do
        expect(duplicate_job).to be_idempotent
      end
    end
  end
end
