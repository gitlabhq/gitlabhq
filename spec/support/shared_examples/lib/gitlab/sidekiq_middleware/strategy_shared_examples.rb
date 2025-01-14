# frozen_string_literal: true

RSpec.shared_examples 'deduplicating jobs when scheduling' do |strategy_name|
  let(:fake_duplicate_job) do
    instance_double(Gitlab::SidekiqMiddleware::DuplicateJobs::DuplicateJob, duplicate_key_ttl: Gitlab::SidekiqMiddleware::DuplicateJobs::DuplicateJob::DEFAULT_DUPLICATE_KEY_TTL)
  end

  let(:humanized_strategy_name) { strategy_name.to_s.humanize.downcase }

  subject(:strategy) { Gitlab::SidekiqMiddleware::DuplicateJobs::Strategies.for(strategy_name).new(fake_duplicate_job) }

  describe '#schedule' do
    before do
      allow(Gitlab::SidekiqLogging::DeduplicationLogger.instance).to receive(:deduplicated_log)
      allow(fake_duplicate_job).to receive(:idempotency_key).and_return('abc123')
      allow(fake_duplicate_job).to receive(:strategy).and_return(:until_executed)
      allow(fake_duplicate_job).to receive(:reschedulable?).and_return(true)
    end

    it 'checks for duplicates before yielding' do
      # twice in `.deduplicatable_job?`, once in `.expiry`
      expect(fake_duplicate_job).to receive(:scheduled?).exactly(3).times.ordered.and_return(false)
      expect(fake_duplicate_job).to(
        receive(:check!)
          .with(fake_duplicate_job.duplicate_key_ttl)
          .ordered
          .and_return('a jid'))
      expect(fake_duplicate_job).to receive(:duplicate?).ordered.and_return(false)
      expect(fake_duplicate_job).to receive(:clear_signaling_key).ordered

      expect { |b| strategy.schedule({}, &b) }.to yield_control
    end

    it 'checks worker options for scheduled jobs' do
      expect(fake_duplicate_job).to receive(:scheduled?).ordered.and_return(true)
      expect(fake_duplicate_job).to receive(:deferred?).ordered.and_return(false)
      expect(fake_duplicate_job).to receive(:scheduled?).ordered.and_return(true)
      expect(fake_duplicate_job).to receive(:options).ordered.and_return({})
      expect(fake_duplicate_job).not_to receive(:check!)
      expect(fake_duplicate_job).to receive(:clear_signaling_key).ordered

      expect { |b| strategy.schedule({}, &b) }.to yield_control
    end

    context 'job marking' do
      it 'adds the jid of the existing job to the job hash' do
        allow(fake_duplicate_job).to receive(:scheduled?).and_return(false)
        allow(fake_duplicate_job).to receive(:check!).and_return('the jid')
        allow(fake_duplicate_job).to receive(:idempotent?).and_return(true)
        allow(fake_duplicate_job).to receive(:update_latest_wal_location!)
        allow(fake_duplicate_job).to receive(:options).and_return({})
        job_hash = {}

        expect(fake_duplicate_job).to receive(:duplicate?).and_return(true)
        expect(fake_duplicate_job).to receive(:existing_jid).and_return('the jid')
        expect(fake_duplicate_job).not_to receive(:clear_signaling_key)

        strategy.schedule(job_hash) {}

        expect(job_hash).to include('duplicate-of' => 'the jid')
      end

      context 'scheduled jobs' do
        let(:time_diff) { 1.minute }

        context 'scheduled in the past' do
          it 'adds the jid of the existing job to the job hash' do
            allow(fake_duplicate_job).to receive(:scheduled?).exactly(4).times.and_return(true)
            allow(fake_duplicate_job).to receive(:scheduled_at).and_return(Time.now - time_diff)
            allow(fake_duplicate_job).to receive(:options).and_return({ including_scheduled: true })
            allow(fake_duplicate_job).to(
              receive(:check!)
                .with(fake_duplicate_job.duplicate_key_ttl)
                .and_return('the jid'))
            allow(fake_duplicate_job).to receive(:idempotent?).and_return(true)
            allow(fake_duplicate_job).to receive(:update_latest_wal_location!)
            allow(fake_duplicate_job).to receive(:deferred?)
            job_hash = {}

            expect(fake_duplicate_job).to receive(:duplicate?).and_return(true)
            expect(fake_duplicate_job).to receive(:existing_jid).and_return('the jid')
            expect(fake_duplicate_job).not_to receive(:clear_signaling_key)

            strategy.schedule(job_hash) {}

            expect(job_hash).to include('duplicate-of' => 'the jid')
          end
        end

        context 'scheduled in the future' do
          it 'adds the jid of the existing job to the job hash' do
            freeze_time do
              allow(fake_duplicate_job).to receive(:scheduled?).exactly(4).times.and_return(true)
              allow(fake_duplicate_job).to receive(:scheduled_at).and_return(Time.now + time_diff)
              allow(fake_duplicate_job).to receive(:options).and_return({ including_scheduled: true })
              allow(fake_duplicate_job).to(
                receive(:check!).with(time_diff.to_i + fake_duplicate_job.duplicate_key_ttl).and_return('the jid'))
              allow(fake_duplicate_job).to receive(:idempotent?).and_return(true)
              allow(fake_duplicate_job).to receive(:update_latest_wal_location!)
              allow(fake_duplicate_job).to receive(:deferred?)
              job_hash = {}

              expect(fake_duplicate_job).to receive(:duplicate?).and_return(true)
              expect(fake_duplicate_job).to receive(:existing_jid).and_return('the jid')
              expect(fake_duplicate_job).not_to receive(:clear_signaling_key)

              strategy.schedule(job_hash) {}

              expect(job_hash).to include('duplicate-of' => 'the jid')
            end
          end
        end
      end
    end

    context "when the job is not duplicate" do
      before do
        allow(fake_duplicate_job).to receive(:scheduled?).and_return(false)
        allow(fake_duplicate_job).to receive(:check!).and_return('the jid')
        allow(fake_duplicate_job).to receive(:duplicate?).and_return(false)
        allow(fake_duplicate_job).to receive(:options).and_return({})
        allow(fake_duplicate_job).to receive(:existing_jid).and_return('the jid')
        allow(fake_duplicate_job).to receive(:idempotency_key).and_return('abc123')
      end

      it 'does not return false nor drop the job' do
        schedule_result = nil

        allow(fake_duplicate_job).to receive(:clear_signaling_key)

        expect { |b| schedule_result = strategy.schedule({}, &b) }.to yield_control

        expect(schedule_result).to be_nil
      end
    end

    context "when the job is droppable" do
      before do
        allow(fake_duplicate_job).to receive(:scheduled?).and_return(false)
        allow(fake_duplicate_job).to receive(:check!).and_return('the jid')
        allow(fake_duplicate_job).to receive(:duplicate?).and_return(true)
        allow(fake_duplicate_job).to receive(:options).and_return({})
        allow(fake_duplicate_job).to receive(:existing_jid).and_return('the jid')
        allow(fake_duplicate_job).to receive(:idempotent?).and_return(true)
        allow(fake_duplicate_job).to receive(:update_latest_wal_location!)
        allow(fake_duplicate_job).to receive(:idempotency_key).and_return('abc123')
      end

      it 'updates latest wal location' do
        expect(fake_duplicate_job).to receive(:update_latest_wal_location!)

        strategy.schedule({ 'jid' => 'new jid' }) {}
      end

      it 'returns false to drop the job' do
        schedule_result = nil

        expect(fake_duplicate_job).to receive(:idempotent?).and_return(true)

        expect { |b| schedule_result = strategy.schedule({}, &b) }.not_to yield_control
        expect(schedule_result).to be(false)
      end

      it 'logs that the job was dropped' do
        fake_logger = instance_double(Gitlab::SidekiqLogging::DeduplicationLogger)

        expect(Gitlab::SidekiqLogging::DeduplicationLogger).to receive(:instance).and_return(fake_logger)
        expect(fake_logger).to receive(:deduplicated_log).with(a_hash_including({ 'jid' => 'new jid' }), humanized_strategy_name, {})

        strategy.schedule({ 'jid' => 'new jid' }) {}
      end

      it 'logs the deduplication options of the worker' do
        fake_logger = instance_double(Gitlab::SidekiqLogging::DeduplicationLogger)

        expect(Gitlab::SidekiqLogging::DeduplicationLogger).to receive(:instance).and_return(fake_logger)
        allow(fake_duplicate_job).to receive(:options).and_return({ foo: :bar })
        expect(fake_logger).to receive(:deduplicated_log).with(a_hash_including({ 'jid' => 'new jid' }), humanized_strategy_name, { foo: :bar })

        strategy.schedule({ 'jid' => 'new jid' }) {}
      end
    end
  end

  describe '#perform' do
    let(:proc) { -> {} }
    let(:job) { { 'jid' => 'new jid', 'wal_locations' => { 'main' => '0/1234', 'ci' => '0/1234' } } }
    let(:wal_locations) do
      {
        main: '0/D525E3A8',
        ci: 'AB/12345'
      }
    end

    before do
      allow(fake_duplicate_job).to receive(:delete!)
      allow(fake_duplicate_job).to receive(:scheduled?) { false }
      allow(fake_duplicate_job).to receive(:options) { {} }
      allow(fake_duplicate_job).to receive(:latest_wal_locations).and_return(wal_locations)
      allow(fake_duplicate_job).to receive(:idempotency_key).and_return('abc123')
      allow(fake_duplicate_job).to receive(:strategy).and_return(:until_executed)
      allow(fake_duplicate_job).to receive(:reschedulable?) { false }
    end

    it 'updates job hash with dedup_wal_locations' do
      strategy.perform(job) do
        proc.call
      end

      expect(job['dedup_wal_locations']).to eq(wal_locations)
    end

    shared_examples 'does not update job hash' do
      it 'does not update job hash with dedup_wal_locations' do
        strategy.perform(job) do
          proc.call
        end

        expect(job).not_to include('dedup_wal_locations')
      end
    end

    context 'when latest_wal_location is empty' do
      before do
        allow(fake_duplicate_job).to receive(:latest_wal_locations).and_return({})
      end

      include_examples 'does not update job hash'
    end
  end
end
