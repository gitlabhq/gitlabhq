# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::SidekiqMiddleware::DuplicateJobs::DuplicateJob, :clean_gitlab_redis_queues do
  using RSpec::Parameterized::TableSyntax

  subject(:duplicate_job) do
    described_class.new(job, queue)
  end

  let(:wal_locations) do
    {
      main: '0/D525E3A8',
      ci: 'AB/12345'
    }
  end

  let(:job) { { 'class' => 'AuthorizedProjectsWorker', 'args' => [1], 'jid' => '123', 'wal_locations' => wal_locations } }
  let(:queue) { 'authorized_projects' }

  let(:idempotency_key) do
    hash = Digest::SHA256.hexdigest("#{job['class']}:#{Sidekiq.dump_json(job['args'])}")
    "#{Gitlab::Redis::Queues::SIDEKIQ_NAMESPACE}:duplicate:#{queue}:#{hash}"
  end

  let(:deduplicated_flag_key) do
    "#{idempotency_key}:deduplicate_flag"
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

    it_behaves_like 'scheduling with deduplication class', 'UntilExecuting'

    context 'when the deduplication depends on a FF' do
      before do
        skip_feature_flags_yaml_validation
        skip_default_enabled_yaml_check

        allow(AuthorizedProjectsWorker).to receive(:get_deduplication_options).and_return(feature_flag: :my_feature_flag)
      end

      context 'when the feature flag is enabled' do
        before do
          stub_feature_flags(my_feature_flag: true)
        end

        it_behaves_like 'scheduling with deduplication class', 'UntilExecuting'
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
        expect_next_instance_of(Gitlab::SidekiqMiddleware::DuplicateJobs::Strategies::UntilExecuting) do |strategy|
          expect(strategy).to receive(:perform).with(job, &block)
        end

        duplicate_job.perform(&block)
      end.to yield_control
    end
  end

  describe '#check!' do
    context 'when there was no job in the queue yet' do
      it { expect(duplicate_job.check!).to eq('123') }

      shared_examples 'sets Redis keys with correct TTL' do
        it "adds an idempotency key with correct ttl" do
          expect { duplicate_job.check! }
            .to change { read_idempotency_key_with_ttl(idempotency_key) }
                  .from([nil, -2])
                  .to(['123', be_within(1).of(expected_ttl)])
        end

        context 'when wal locations is not empty' do
          it "adds an existing wal locations key with correct ttl" do
            expect { duplicate_job.check! }
              .to change { read_idempotency_key_with_ttl(existing_wal_location_key(idempotency_key, :main)) }
                    .from([nil, -2])
                    .to([wal_locations[:main], be_within(1).of(expected_ttl)])
              .and change { read_idempotency_key_with_ttl(existing_wal_location_key(idempotency_key, :ci)) }
                    .from([nil, -2])
                    .to([wal_locations[:ci], be_within(1).of(expected_ttl)])
          end
        end
      end

      context 'with TTL option is not set' do
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
        set_idempotency_key(idempotency_key, 'existing-key')
        wal_locations.each do |config_name, location|
          set_idempotency_key(existing_wal_location_key(idempotency_key, config_name), location)
        end
      end

      it { expect(duplicate_job.check!).to eq('existing-key') }

      it "does not change the existing key's TTL" do
        expect { duplicate_job.check! }
          .not_to change { read_idempotency_key_with_ttl(idempotency_key) }
                .from(['existing-key', -1])
      end

      it "does not change the existing wal locations key's TTL" do
        expect { duplicate_job.check! }
          .to not_change { read_idempotency_key_with_ttl(existing_wal_location_key(idempotency_key, :main)) }
                .from([wal_locations[:main], -1])
          .and not_change { read_idempotency_key_with_ttl(existing_wal_location_key(idempotency_key, :ci)) }
                .from([wal_locations[:ci], -1])
      end

      it 'sets the existing jid' do
        duplicate_job.check!

        expect(duplicate_job.existing_jid).to eq('existing-key')
      end
    end
  end

  describe '#update_latest_wal_location!' do
    before do
      allow(Gitlab::Database).to receive(:database_base_models).and_return(
        { main: ::ActiveRecord::Base,
          ci: ::ActiveRecord::Base })

      set_idempotency_key(existing_wal_location_key(idempotency_key, :main), existing_wal[:main])
      set_idempotency_key(existing_wal_location_key(idempotency_key, :ci), existing_wal[:ci])

      # read existing_wal_locations
      duplicate_job.check!
    end

    context "when the key doesn't exists in redis" do
      let(:existing_wal) do
        {
          main: '0/D525E3A0',
          ci: 'AB/12340'
        }
      end

      let(:new_wal_location_with_offset) do
        {
          # offset is relative to `existing_wal`
          main: ['0/D525E3A8', '8'],
          ci: ['AB/12345', '5']
        }
      end

      let(:wal_locations) { new_wal_location_with_offset.transform_values(&:first) }

      it 'stores a wal location to redis with an offset relative to existing wal location' do
        expect { duplicate_job.update_latest_wal_location! }
          .to change { read_range_from_redis(wal_location_key(idempotency_key, :main)) }
                .from([])
                .to(new_wal_location_with_offset[:main])
          .and change { read_range_from_redis(wal_location_key(idempotency_key, :ci)) }
                .from([])
                .to(new_wal_location_with_offset[:ci])
      end
    end

    context "when the key exists in redis" do
      before do
        rpush_to_redis_key(wal_location_key(idempotency_key, :main), *stored_wal_location_with_offset[:main])
        rpush_to_redis_key(wal_location_key(idempotency_key, :ci), *stored_wal_location_with_offset[:ci])
      end

      let(:wal_locations) { new_wal_location_with_offset.transform_values(&:first) }

      context "when the new offset is bigger then the existing one" do
        let(:existing_wal) do
          {
            main: '0/D525E3A0',
            ci: 'AB/12340'
          }
        end

        let(:stored_wal_location_with_offset) do
          {
            # offset is relative to `existing_wal`
            main: ['0/D525E3A3', '3'],
            ci: ['AB/12342', '2']
          }
        end

        let(:new_wal_location_with_offset) do
          {
            # offset is relative to `existing_wal`
            main: ['0/D525E3A8', '8'],
            ci: ['AB/12345', '5']
          }
        end

        it 'updates a wal location to redis with an offset' do
          expect { duplicate_job.update_latest_wal_location! }
            .to change { read_range_from_redis(wal_location_key(idempotency_key, :main)) }
                  .from(stored_wal_location_with_offset[:main])
                  .to(new_wal_location_with_offset[:main])
            .and change { read_range_from_redis(wal_location_key(idempotency_key, :ci)) }
                  .from(stored_wal_location_with_offset[:ci])
                  .to(new_wal_location_with_offset[:ci])
        end
      end

      context "when the old offset is not bigger then the existing one" do
        let(:existing_wal) do
          {
            main: '0/D525E3A0',
            ci: 'AB/12340'
          }
        end

        let(:stored_wal_location_with_offset) do
          {
            # offset is relative to `existing_wal`
            main: ['0/D525E3A8', '8'],
            ci: ['AB/12345', '5']
          }
        end

        let(:new_wal_location_with_offset) do
          {
            # offset is relative to `existing_wal`
            main: ['0/D525E3A2', '2'],
            ci: ['AB/12342', '2']
          }
        end

        it "does not update a wal location to redis with an offset" do
          expect { duplicate_job.update_latest_wal_location! }
            .to not_change { read_range_from_redis(wal_location_key(idempotency_key, :main)) }
                  .from(stored_wal_location_with_offset[:main])
            .and not_change { read_range_from_redis(wal_location_key(idempotency_key, :ci)) }
                   .from(stored_wal_location_with_offset[:ci])
        end
      end
    end
  end

  describe '#latest_wal_locations' do
    context 'when job was deduplicated and wal locations were already persisted' do
      before do
        rpush_to_redis_key(wal_location_key(idempotency_key, :main), wal_locations[:main], 1024)
        rpush_to_redis_key(wal_location_key(idempotency_key, :ci), wal_locations[:ci], 1024)
      end

      it { expect(duplicate_job.latest_wal_locations).to eq(wal_locations) }
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
        set_idempotency_key(idempotency_key, 'existing-jid')
        set_idempotency_key(deduplicated_flag_key, 1)
        wal_locations.each do |config_name, location|
          set_idempotency_key(existing_wal_location_key(idempotency_key, config_name), location)
          set_idempotency_key(wal_location_key(idempotency_key, config_name), location)
        end
      end

      shared_examples 'deleting the duplicate job' do
        shared_examples 'deleting keys from redis' do |key_name|
          it "removes the #{key_name} from redis" do
            expect { duplicate_job.delete! }
              .to change { read_idempotency_key_with_ttl(key) }
                    .from([from_value, -1])
                    .to([nil, -2])
          end
        end

        shared_examples 'does not delete key from redis' do |key_name|
          it "does not remove the #{key_name} from redis" do
            expect { duplicate_job.delete! }
              .to not_change { read_idempotency_key_with_ttl(key) }
                    .from([from_value, -1])
          end
        end

        it_behaves_like 'deleting keys from redis', 'idempotent key' do
          let(:key) { idempotency_key }
          let(:from_value) { 'existing-jid' }
        end

        it_behaves_like 'deleting keys from redis', 'deduplication counter key' do
          let(:key) { deduplicated_flag_key }
          let(:from_value) { '1' }
        end

        it_behaves_like 'deleting keys from redis', 'existing wal location keys for main database' do
          let(:key) { existing_wal_location_key(idempotency_key, :main) }
          let(:from_value) { wal_locations[:main] }
        end

        it_behaves_like 'deleting keys from redis', 'existing wal location keys for ci database' do
          let(:key) { existing_wal_location_key(idempotency_key, :ci) }
          let(:from_value) { wal_locations[:ci] }
        end

        it_behaves_like 'deleting keys from redis', 'latest wal location keys for main database' do
          let(:key) { wal_location_key(idempotency_key, :main) }
          let(:from_value) { wal_locations[:main] }
        end

        it_behaves_like 'deleting keys from redis', 'latest wal location keys for ci database' do
          let(:key) { wal_location_key(idempotency_key, :ci) }
          let(:from_value) { wal_locations[:ci] }
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
      expect(AuthorizedProjectsWorker).to receive(:perform_async).with(1).once

      duplicate_job.reschedule
    end
  end

  describe '#should_reschedule?' do
    subject { duplicate_job.should_reschedule? }

    context 'when the job is reschedulable' do
      before do
        allow(duplicate_job).to receive(:reschedulable?) { true }
      end

      it { is_expected.to eq(false) }

      context 'with deduplicated flag' do
        before do
          duplicate_job.set_deduplicated_flag!
        end

        it { is_expected.to eq(true) }
      end
    end

    context 'when the job is not reschedulable' do
      before do
        allow(duplicate_job).to receive(:reschedulable?) { false }
      end

      it { is_expected.to eq(false) }

      context 'with deduplicated flag' do
        before do
          duplicate_job.set_deduplicated_flag!
        end

        it { is_expected.to eq(false) }
      end
    end
  end

  describe '#set_deduplicated_flag!' do
    context 'when the job is reschedulable' do
      before do
        allow(duplicate_job).to receive(:reschedulable?) { true }
      end

      it 'sets the key in Redis' do
        duplicate_job.set_deduplicated_flag!

        flag = Sidekiq.redis { |redis| redis.get(deduplicated_flag_key) }

        expect(flag).to eq(described_class::DEDUPLICATED_FLAG_VALUE.to_s)
      end

      it 'sets, gets and cleans up the deduplicated flag' do
        expect(duplicate_job.should_reschedule?).to eq(false)

        duplicate_job.set_deduplicated_flag!
        expect(duplicate_job.should_reschedule?).to eq(true)

        duplicate_job.delete!
        expect(duplicate_job.should_reschedule?).to eq(false)
      end
    end

    context 'when the job is not reschedulable' do
      before do
        allow(duplicate_job).to receive(:reschedulable?) { false }
      end

      it 'does not set the key in Redis' do
        duplicate_job.set_deduplicated_flag!

        flag = Sidekiq.redis { |redis| redis.get(deduplicated_flag_key) }

        expect(flag).to be_nil
      end

      it 'does not set the deduplicated flag' do
        expect(duplicate_job.should_reschedule?).to eq(false)

        duplicate_job.set_deduplicated_flag!
        expect(duplicate_job.should_reschedule?).to eq(false)

        duplicate_job.delete!
        expect(duplicate_job.should_reschedule?).to eq(false)
      end
    end
  end

  describe '#duplicate?' do
    it "raises an error if the check wasn't performed" do
      expect { duplicate_job.duplicate? }.to raise_error /Call `#check!` first/
    end

    it 'returns false if the existing jid equals the job jid' do
      duplicate_job.check!

      expect(duplicate_job.duplicate?).to be(false)
    end

    it 'returns false if the existing jid is different from the job jid' do
      set_idempotency_key(idempotency_key, 'a different jid')
      duplicate_job.check!

      expect(duplicate_job.duplicate?).to be(true)
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

  def existing_wal_location_key(idempotency_key, connection_name)
    "#{idempotency_key}:#{connection_name}:existing_wal_location"
  end

  def wal_location_key(idempotency_key, connection_name)
    "#{idempotency_key}:#{connection_name}:wal_location"
  end

  def set_idempotency_key(key, value = '1')
    Sidekiq.redis { |r| r.set(key, value) }
  end

  def rpush_to_redis_key(key, wal, offset)
    Sidekiq.redis { |r| r.rpush(key, [wal, offset]) }
  end

  def read_idempotency_key_with_ttl(key)
    Sidekiq.redis do |redis|
      redis.pipelined do |p|
        p.get(key)
        p.ttl(key)
      end
    end
  end

  def read_range_from_redis(key)
    Sidekiq.redis do |redis|
      redis.lrange(key, 0, -1)
    end
  end
end
