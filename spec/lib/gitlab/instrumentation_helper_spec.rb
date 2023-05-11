# frozen_string_literal: true

require 'spec_helper'
require 'rspec-parameterized'
require 'support/helpers/rails_helpers'

RSpec.describe Gitlab::InstrumentationHelper, :clean_gitlab_redis_repository_cache, :clean_gitlab_redis_cache,
               :use_null_store_as_repository_cache, feature_category: :scalability do
  using RSpec::Parameterized::TableSyntax

  describe '.init_instrumentation_data' do
    it 'clears instrumentation storage' do
      expect(::Gitlab::Instrumentation::Storage).to receive(:clear!)

      described_class.init_instrumentation_data
    end
  end

  describe '.add_instrumentation_data', :request_store do
    let(:payload) { {} }

    subject { described_class.add_instrumentation_data(payload) }

    before do
      described_class.init_instrumentation_data
    end

    it 'includes DB counts' do
      subject

      expect(payload).to include(db_count: 0, db_cached_count: 0, db_write_count: 0)
    end

    context 'when Gitaly calls are made' do
      it 'adds Gitaly and Redis data' do
        project = create(:project)
        ::Gitlab::Instrumentation::Storage.clear!
        project.repository.exists?

        subject

        expect(payload[:gitaly_calls]).to eq(1)
        expect(payload[:gitaly_duration_s]).to be >= 0
        expect(payload[:redis_calls]).to eq(nil)
        expect(payload[:redis_duration_ms]).to be_nil
      end
    end

    context 'when Redis calls are made' do
      it 'adds Redis data and omits Gitaly data' do
        stub_rails_env('staging') # to avoid raising CrossSlotError
        Gitlab::Redis::Cache.with { |redis| redis.mset('test-cache', 123, 'test-cache2', 123) }
        Gitlab::Instrumentation::RedisClusterValidator.allow_cross_slot_commands do
          Gitlab::Redis::Cache.with { |redis| redis.mget('cache-test', 'cache-test-2') }
        end
        Gitlab::Redis::Queues.with { |redis| redis.set('test-queues', 321) }

        subject

        # Aggregated payload
        expect(payload[:redis_calls]).to eq(3)
        expect(payload[:redis_cross_slot_calls]).to eq(1)
        expect(payload[:redis_allowed_cross_slot_calls]).to eq(1)
        expect(payload[:redis_duration_s]).to be >= 0
        expect(payload[:redis_read_bytes]).to be >= 0
        expect(payload[:redis_write_bytes]).to be >= 0

        # Queue payload
        expect(payload[:redis_queues_calls]).to eq(1)
        expect(payload[:redis_queues_duration_s]).to be >= 0
        expect(payload[:redis_queues_read_bytes]).to be >= 0
        expect(payload[:redis_queues_write_bytes]).to be >= 0

        # Cache payload
        expect(payload[:redis_cache_calls]).to eq(2)
        expect(payload[:redis_cache_cross_slot_calls]).to eq(1)
        expect(payload[:redis_cache_allowed_cross_slot_calls]).to eq(1)
        expect(payload[:redis_cache_duration_s]).to be >= 0
        expect(payload[:redis_cache_read_bytes]).to be >= 0
        expect(payload[:redis_cache_write_bytes]).to be >= 0

        # Gitaly
        expect(payload[:gitaly_calls]).to be_nil
        expect(payload[:gitaly_duration]).to be_nil
      end
    end

    context 'when LDAP requests are made' do
      let(:provider) { 'ldapmain' }
      let(:adapter) { Gitlab::Auth::Ldap::Adapter.new(provider) }
      let(:conn) { instance_double(Net::LDAP::Connection, search: search) }
      let(:search) { double(:search, result_code: 200) } # rubocop: disable RSpec/VerifiedDoubles

      it 'adds LDAP data' do
        allow_next_instance_of(Net::LDAP) do |net_ldap|
          allow(net_ldap).to receive(:use_connection).and_yield(conn)
        end

        adapter.users('uid', 'foo')
        subject

        # Query count should be 2, as it will call `open` then `search`
        expect(payload[:net_ldap_count]).to eq(2)
        expect(payload[:net_ldap_duration_s]).to be >= 0
      end
    end

    context 'when the request matched a Rack::Attack safelist' do
      it 'logs the safelist name' do
        Gitlab::Instrumentation::Throttle.safelist = 'foobar'

        subject

        expect(payload[:throttle_safelist]).to eq('foobar')
      end
    end

    context 'rate-limiting gates' do
      context 'when the request did not pass through any rate-limiting gates' do
        it 'logs an empty array of gates' do
          subject

          expect(payload[:rate_limiting_gates]).to eq([])
        end
      end

      context 'when the request passed through rate-limiting gates' do
        it 'logs an array of gates used' do
          Gitlab::Instrumentation::RateLimitingGates.track(:foo)
          Gitlab::Instrumentation::RateLimitingGates.track(:bar)

          subject

          expect(payload[:rate_limiting_gates]).to contain_exactly(:foo, :bar)
        end
      end
    end

    it 'logs cpu_s duration' do
      subject

      expect(payload).to include(:cpu_s)
    end

    it 'logs the process ID' do
      subject

      expect(payload).to include(:pid)
    end

    it 'logs the worker ID' do
      expect(Prometheus::PidProvider).to receive(:worker_id).and_return('puma_1')

      subject

      expect(payload).to include(worker_id: 'puma_1')
    end

    context 'when logging memory allocations' do
      include MemoryInstrumentationHelper

      before do
        verify_memory_instrumentation_available!
      end

      it 'logs memory usage metrics' do
        subject

        expect(payload).to include(
          :mem_objects,
          :mem_bytes,
          :mem_mallocs
        )
      end
    end

    it 'includes DB counts' do
      subject

      expect(payload).to include(db_replica_count: 0,
                                 db_replica_cached_count: 0,
                                 db_primary_count: 0,
                                 db_primary_cached_count: 0,
                                 db_primary_wal_count: 0,
                                 db_replica_wal_count: 0,
                                 db_primary_wal_cached_count: 0,
                                 db_replica_wal_cached_count: 0)
    end

    context 'when replica caught up search was made' do
      before do
        ::Gitlab::Instrumentation::Storage[:caught_up_replica_pick_ok] = 2
        ::Gitlab::Instrumentation::Storage[:caught_up_replica_pick_fail] = 1
      end

      it 'includes related metrics' do
        subject

        expect(payload).to include(caught_up_replica_pick_ok: 2)
        expect(payload).to include(caught_up_replica_pick_fail: 1)
      end
    end

    context 'when only a single counter was updated' do
      before do
        ::Gitlab::Instrumentation::Storage[:caught_up_replica_pick_ok] = 1
        ::Gitlab::Instrumentation::Storage[:caught_up_replica_pick_fail] = nil
      end

      it 'includes only that counter into logging' do
        subject

        expect(payload).to include(caught_up_replica_pick_ok: 1)
        expect(payload).not_to include(:caught_up_replica_pick_fail)
      end
    end

    context 'when there is an uploaded file' do
      it 'adds upload data' do
        uploaded_file = UploadedFile.from_params({
          'name' => 'dir/foo.txt',
          'sha256' => 'sha256',
          'remote_url' => 'http://localhost/file',
          'remote_id' => '1234567890',
          'etag' => 'etag1234567890',
          'upload_duration' => '5.05',
          'size' => '123456'
        }, nil)

        subject

        expect(payload[:uploaded_file_upload_duration_s]).to eq(uploaded_file.upload_duration)
        expect(payload[:uploaded_file_size_bytes]).to eq(uploaded_file.size)
      end
    end

    context 'when an api call to the search api is made' do
      before do
        Gitlab::Instrumentation::GlobalSearchApi.set_information(
          type: 'basic',
          level: 'global',
          scope: 'issues',
          search_duration_s: 0.1
        )
      end

      it 'adds search data' do
        subject

        expect(payload).to include({
         'meta.search.type' => 'basic',
         'meta.search.level' => 'global',
         'meta.search.scope' => 'issues',
         global_search_duration_s: 0.1
        })
      end
    end
  end

  describe 'duration calculations' do
    where(:end_time, :start_time, :time_now, :expected_duration) do
      "2019-06-01T00:00:00.000+0000" | nil                            | "2019-06-01T02:00:00.000+0000" | 2.hours.to_f
      "2019-06-01T02:00:00.000+0000" | nil                            | "2019-06-01T02:00:00.001+0000" | 0.001
      "2019-06-01T02:00:00.000+0000" | "2019-05-01T02:00:00.000+0000" | "2019-06-01T02:00:01.000+0000" | 1
      nil                            | "2019-06-01T02:00:00.000+0000" | "2019-06-01T02:00:00.001+0000" | 0.001
      nil                            | nil                            | "2019-06-01T02:00:00.001+0000" | nil
      "2019-06-01T02:00:00.000+0200" | nil                            | "2019-06-01T02:00:00.000-0200" | 4.hours.to_f
      1571825569.998168              | nil                            | "2019-10-23T12:13:16.000+0200" | 26.001832
      1571825569                     | nil                            | "2019-10-23T12:13:16.000+0200" | 27
      "invalid_date"                 | nil                            | "2019-10-23T12:13:16.000+0200" | nil
      ""                             | nil                            | "2019-10-23T12:13:16.000+0200" | nil
      0                              | nil                            | "2019-10-23T12:13:16.000+0200" | nil
      -1                             | nil                            | "2019-10-23T12:13:16.000+0200" | nil
      "2019-06-01T02:00:00.000+0000" | nil                            | "2019-06-01T00:00:00.000+0000" | 0
      Time.at(1571999233).utc        | nil                            | "2019-10-25T12:29:16.000+0200" | 123
    end

    describe '.queue_duration_for_job' do
      with_them do
        let(:job) { { 'enqueued_at' => end_time, 'created_at' => start_time } }

        it "returns the correct duration" do
          travel_to(Time.iso8601(time_now)) do
            expect(described_class.queue_duration_for_job(job)).to eq(expected_duration)
          end
        end
      end
    end

    describe '.enqueue_latency_for_scheduled_job' do
      with_them do
        let(:job) { { 'enqueued_at' => end_time, 'scheduled_at' => start_time } }

        it "returns the correct duration" do
          travel_to(Time.iso8601(time_now)) do
            expect(described_class.enqueue_latency_for_scheduled_job(job)).to eq(expected_duration)
          end
        end
      end
    end
  end
end
