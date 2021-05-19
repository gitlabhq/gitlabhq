# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::Ci::Trace, :clean_gitlab_redis_shared_state, factory_default: :keep do
  let_it_be(:project) { create_default(:project).freeze }
  let_it_be_with_reload(:build) { create(:ci_build, :success) }

  let(:trace) { described_class.new(build) }

  describe "associations" do
    it { expect(trace).to respond_to(:job) }
    it { expect(trace).to delegate_method(:old_trace).to(:job) }
  end

  context 'when trace is migrated to object storage' do
    let!(:job) { create(:ci_build, :trace_artifact) }
    let!(:artifact1) { job.job_artifacts_trace }
    let!(:artifact2) { job.reload.job_artifacts_trace }
    let(:test_data) { "hello world" }

    before do
      stub_artifacts_object_storage

      artifact1.file.migrate!(ObjectStorage::Store::REMOTE)
    end

    it 'reloads the trace after is it migrated' do
      stub_const('Gitlab::HttpIO::BUFFER_SIZE', test_data.length)

      expect_next_instance_of(Gitlab::HttpIO) do |http_io|
        expect(http_io).to receive(:get_chunk).and_return(test_data, "")
      end

      expect(artifact2.job.trace.raw).to eq(test_data)
    end

    it 'reloads the trace in case of a chunk error' do
      chunk_error = described_class::ChunkedIO::FailedToGetChunkError

      allow_any_instance_of(described_class::Stream)
        .to receive(:raw).and_raise(chunk_error)

      expect(build).to receive(:reset).and_return(build)
      expect { trace.raw }.to raise_error(chunk_error)
    end
  end

  context 'when live trace feature is disabled' do
    before do
      stub_feature_flags(ci_enable_live_trace: false)
    end

    it_behaves_like 'trace with disabled live trace feature'
  end

  context 'when live trace feature is enabled' do
    before do
      stub_feature_flags(ci_enable_live_trace: true)
    end

    it_behaves_like 'trace with enabled live trace feature'
  end

  describe '#update_interval' do
    context 'it is not being watched' do
      it { expect(trace.update_interval).to eq(60.seconds) }
    end

    context 'it is being watched' do
      before do
        trace.being_watched!
      end

      it 'returns 3 seconds' do
        expect(trace.update_interval).to eq(3.seconds)
      end
    end
  end

  describe '#being_watched!' do
    let(:cache_key) { "gitlab:ci:trace:#{build.id}:watched" }

    it 'sets gitlab:ci:trace:<job.id>:watched in redis' do
      trace.being_watched!

      result = Gitlab::Redis::SharedState.with do |redis|
        redis.exists(cache_key)
      end

      expect(result).to eq(true)
    end

    it 'updates the expiry of gitlab:ci:trace:<job.id>:watched in redis', :clean_gitlab_redis_shared_state do
      Gitlab::Redis::SharedState.with do |redis|
        redis.set(cache_key, true, ex: 4.seconds)
      end

      expect do
        trace.being_watched!
      end.to change { Gitlab::Redis::SharedState.with { |redis| redis.pttl(cache_key) } }
    end
  end

  describe '#being_watched?' do
    context 'gitlab:ci:trace:<job.id>:watched in redis is set', :clean_gitlab_redis_shared_state do
      before do
        Gitlab::Redis::SharedState.with do |redis|
          redis.set("gitlab:ci:trace:#{build.id}:watched", true)
        end
      end

      it 'returns true' do
        expect(trace.being_watched?).to be(true)
      end
    end

    context 'gitlab:ci:trace:<job.id>:watched in redis is not set' do
      it 'returns false' do
        expect(trace.being_watched?).to be(false)
      end
    end
  end

  describe '#lock' do
    it 'acquires an exclusive lease on the trace' do
      trace.lock do
        expect { trace.lock }
          .to raise_error described_class::LockedError
      end
    end
  end
end
