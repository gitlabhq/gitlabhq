# frozen_string_literal: true

require 'spec_helper'

describe Gitlab::SidekiqMiddleware::DuplicateJobs::DuplicateJob, :clean_gitlab_redis_queues do
  using RSpec::Parameterized::TableSyntax

  subject(:duplicate_job) do
    described_class.new(job, queue)
  end

  let(:job) { { 'class' => 'AuthorizedProjectsWorker', 'args' => [1], 'jid' => '123' } }
  let(:queue) { 'authorized_projects' }

  let(:idempotency_key) do
    hash = Digest::SHA256.hexdigest("#{job['class']}:#{job['args'].join('-')}")
    "#{Gitlab::Redis::Queues::SIDEKIQ_NAMESPACE}:duplicate:#{queue}:#{hash}"
  end

  describe '#schedule' do
    it 'calls schedule on the strategy' do
      expect do |block|
        expect_next_instance_of(Gitlab::SidekiqMiddleware::DuplicateJobs::Strategies::UntilExecuting) do |strategy|
          expect(strategy).to receive(:schedule).with(job, &block)
        end

        duplicate_job.schedule(&block)
      end.to yield_control
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

      it "adds a key with ttl set to #{described_class::DUPLICATE_KEY_TTL}" do
        expect { duplicate_job.check! }
          .to change { read_idempotency_key_with_ttl(idempotency_key) }
                .from([nil, -2])
                .to(['123', be_within(1).of(described_class::DUPLICATE_KEY_TTL)])
      end
    end

    context 'when there was already a job with same arguments in the same queue' do
      before do
        set_idempotency_key(idempotency_key, 'existing-key')
      end

      it { expect(duplicate_job.check!).to eq('existing-key') }

      it "does not change the existing key's TTL" do
        expect { duplicate_job.check! }
          .not_to change { read_idempotency_key_with_ttl(idempotency_key) }
                .from(['existing-key', -1])
      end

      it 'sets the existing jid' do
        duplicate_job.check!

        expect(duplicate_job.existing_jid).to eq('existing-key')
      end
    end
  end

  describe '#delete!' do
    context "when we didn't track the definition" do
      it { expect { duplicate_job.delete! }.not_to raise_error }
    end

    context 'when the key exists in redis' do
      before do
        set_idempotency_key(idempotency_key, 'existing-key')
      end

      it 'removes the key from redis' do
        expect { duplicate_job.delete! }
          .to change { read_idempotency_key_with_ttl(idempotency_key) }
                .from(['existing-key', -1])
                .to([nil, -2])
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

  describe 'droppable?' do
    where(:idempotent, :duplicate, :prevent_deduplication) do
      # [true, false].repeated_permutation(3)
      [[true, true, true],
       [true, true, false],
       [true, false, true],
       [true, false, false],
       [false, true, true],
       [false, true, false],
       [false, false, true],
       [false, false, false]]
    end

    with_them do
      before do
        allow(AuthorizedProjectsWorker).to receive(:idempotent?).and_return(idempotent)
        allow(duplicate_job).to receive(:duplicate?).and_return(duplicate)
        stub_feature_flags("disable_#{queue}_deduplication" => prevent_deduplication)
      end

      it 'is droppable when all conditions are met' do
        if idempotent && duplicate && !prevent_deduplication
          expect(duplicate_job).to be_droppable
        else
          expect(duplicate_job).not_to be_droppable
        end
      end
    end
  end

  def set_idempotency_key(key, value = '1')
    Sidekiq.redis { |r| r.set(key, value) }
  end

  def read_idempotency_key_with_ttl(key)
    Sidekiq.redis do |redis|
      redis.pipelined do |p|
        p.get(key)
        p.ttl(key)
      end
    end
  end
end
