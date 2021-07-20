# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Ci::BuildTraceChunk, :clean_gitlab_redis_shared_state, :clean_gitlab_redis_trace_chunks do
  include ExclusiveLeaseHelpers

  let_it_be(:build) { create(:ci_build, :running) }

  let(:chunk_index) { 0 }
  let(:data_store) { :redis_trace_chunks }
  let(:raw_data) { nil }

  let(:build_trace_chunk) do
    described_class.new(build: build, chunk_index: chunk_index, data_store: data_store, raw_data: raw_data)
  end

  it_behaves_like 'having unique enum values'

  before do
    stub_feature_flags(ci_enable_live_trace: true)
    stub_artifacts_object_storage
  end

  def redis_instance
    {
      redis: Gitlab::Redis::SharedState,
      redis_trace_chunks: Gitlab::Redis::TraceChunks
    }[data_store]
  end

  describe 'chunk creation' do
    let(:metrics) { spy('metrics') }

    before do
      allow(::Gitlab::Ci::Trace::Metrics)
        .to receive(:new)
        .and_return(metrics)
    end

    it 'increments trace operation chunked metric' do
      build_trace_chunk.save!

      expect(metrics)
        .to have_received(:increment_trace_operation)
        .with(operation: :chunked)
        .once
    end
  end

  context 'FastDestroyAll' do
    let(:parent) { create(:project) }
    let(:pipeline) { create(:ci_pipeline, project: parent) }
    let!(:build) { create(:ci_build, :running, :trace_live, pipeline: pipeline, project: parent) }
    let(:subjects) { build.trace_chunks }

    describe 'Forbid #destroy and #destroy_all' do
      it 'does not delete database rows and associted external data' do
        expect(external_data_counter).to be > 0
        expect(subjects.count).to be > 0

        expect { subjects.first.destroy! }.to raise_error('`destroy` and `destroy_all` are forbidden. Please use `fast_destroy_all`')
        expect { subjects.destroy_all }.to raise_error('`destroy` and `destroy_all` are forbidden. Please use `fast_destroy_all`') # rubocop: disable Cop/DestroyAll

        expect(subjects.count).to be > 0
        expect(external_data_counter).to be > 0
      end
    end

    describe '.fast_destroy_all' do
      it 'deletes database rows and associted external data' do
        expect(external_data_counter).to be > 0
        expect(subjects.count).to be > 0

        expect { subjects.fast_destroy_all }.not_to raise_error

        expect(subjects.count).to eq(0)
        expect(external_data_counter).to eq(0)
      end
    end

    describe '.use_fast_destroy' do
      it 'performs cascading delete with fast_destroy_all' do
        expect(external_data_counter).to be > 0
        expect(subjects.count).to be > 0

        expect { parent.destroy! }.not_to raise_error

        expect(subjects.count).to eq(0)
        expect(external_data_counter).to eq(0)
      end
    end

    def external_data_counter
      redis_instance.with do |redis|
        redis.scan_each(match: "gitlab:ci:trace:*:chunks:*").to_a.size
      end
    end
  end

  describe 'CHUNK_SIZE' do
    it 'chunk size can not be changed without special care' do
      expect(described_class::CHUNK_SIZE).to eq(128.kilobytes)
    end
  end

  describe '.all_stores' do
    subject { described_class.all_stores }

    it 'returns a correctly ordered array' do
      is_expected.to eq(%i[redis database fog redis_trace_chunks])
    end
  end

  describe '#data' do
    subject { build_trace_chunk.data }

    where(:data_store) { %i[redis redis_trace_chunks] }

    with_them do
      before do
        build_trace_chunk.send(:unsafe_set_data!, +'Sample data in redis')
      end

      it { is_expected.to eq('Sample data in redis') }
    end

    context 'when data_store is database' do
      let(:data_store) { :database }
      let(:raw_data) { +'Sample data in database' }

      it { is_expected.to eq('Sample data in database') }
    end

    context 'when data_store is fog' do
      let(:data_store) { :fog }

      before do
        build_trace_chunk.send(:unsafe_set_data!, +'Sample data in fog')
      end

      it { is_expected.to eq('Sample data in fog') }

      it 'returns a new Fog store' do
        expect(described_class.get_store_class(data_store)).to be_a(Ci::BuildTraceChunks::Fog)
      end
    end
  end

  describe '#data_store' do
    subject { described_class.new.data_store }

    context 'default value' do
      it { expect(subject).to eq('redis_trace_chunks') }
    end
  end

  describe '#get_store_class' do
    using RSpec::Parameterized::TableSyntax

    where(:data_store, :expected_store) do
      :redis | Ci::BuildTraceChunks::Redis
      :database | Ci::BuildTraceChunks::Database
      :fog | Ci::BuildTraceChunks::Fog
      :redis_trace_chunks | Ci::BuildTraceChunks::RedisTraceChunks
    end

    with_them do
      context "with store" do
        it 'returns an instance of the right class' do
          expect(expected_store).to receive(:new).twice.and_call_original
          expect(described_class.get_store_class(data_store.to_s)).to be_a(expected_store)
          expect(described_class.get_store_class(data_store.to_sym)).to be_a(expected_store)
        end
      end
    end

    it 'raises an error' do
      expect { described_class.get_store_class('unknown') }.to raise_error('Unknown store type: unknown')
    end
  end

  describe '#append' do
    subject { build_trace_chunk.append(new_data, offset) }

    let(:new_data) { +'Sample new data' }
    let(:offset) { 0 }
    let(:merged_data) { data + new_data.to_s }

    shared_examples_for 'Appending correctly' do
      context 'when offset is negative' do
        let(:offset) { -1 }

        it { expect { subject }.to raise_error('Offset is out of range') }
      end

      context 'when offset is bigger than data size' do
        let(:offset) { data.bytesize + 1 }

        it { expect { subject }.to raise_error('Offset is out of range') }
      end

      context 'when new data overflows chunk size' do
        let(:new_data) { 'a' * (described_class::CHUNK_SIZE + 1) }

        it { expect { subject }.to raise_error('Chunk size overflow') }
      end

      context 'when offset is EOF' do
        let(:offset) { data.bytesize }

        it 'appends' do
          subject

          expect(build_trace_chunk.data).to eq(merged_data)
        end

        context 'when the other process is appending' do
          let(:lease_key) { "trace_write:#{build_trace_chunk.build.id}:chunks:#{build_trace_chunk.chunk_index}" }

          before do
            stub_exclusive_lease_taken(lease_key)
          end

          it 'raise an error' do
            expect { subject }.to raise_error('Failed to obtain a lock')
          end
        end

        context 'when new_data is nil' do
          let(:new_data) { nil }

          it 'raises an error' do
            expect { subject }.to raise_error('New data is missing')
          end
        end

        context 'when new_data is empty' do
          let(:new_data) { +'' }

          it 'does not append' do
            subject

            expect(build_trace_chunk.data).to eq(data)
          end

          it 'does not execute UPDATE' do
            ActiveRecord::QueryRecorder.new { subject }.log.map do |query|
              expect(query).not_to include('UPDATE')
            end
          end
        end
      end

      context 'when offset is middle of datasize' do
        let(:offset) { data.bytesize / 2 }

        it 'appends' do
          subject

          expect(build_trace_chunk.data).to eq(data.byteslice(0, offset) + new_data)
        end
      end
    end

    shared_examples_for 'Scheduling sidekiq worker to flush data to persist store' do
      context 'when new data fulfilled chunk size' do
        let(:new_data) { +'a' * described_class::CHUNK_SIZE }

        it 'schedules trace chunk flush worker' do
          expect(Ci::BuildTraceChunkFlushWorker).to receive(:perform_async).once

          subject
        end

        it 'migrates data to object storage', :sidekiq_might_not_need_inline do
          perform_enqueued_jobs do
            subject

            build_trace_chunk.reload

            expect(build_trace_chunk.checksum).to be_present
            expect(build_trace_chunk.fog?).to be_truthy
            expect(build_trace_chunk.data).to eq(new_data)
          end
        end
      end
    end

    shared_examples_for 'Scheduling no sidekiq worker' do
      context 'when new data fulfilled chunk size' do
        let(:new_data) { +'a' * described_class::CHUNK_SIZE }

        it 'does not schedule trace chunk flush worker' do
          expect(Ci::BuildTraceChunkFlushWorker).not_to receive(:perform_async)

          subject
        end

        it 'does not migrate data to object storage' do
          perform_enqueued_jobs do
            data_store = build_trace_chunk.data_store

            subject

            build_trace_chunk.reload
            expect(build_trace_chunk.data_store).to eq(data_store)
          end
        end
      end
    end

    where(:data_store) { %i[redis redis_trace_chunks] }

    with_them do
      context 'when there are no data' do
        let(:data) { +'' }

        it 'has no data' do
          expect(build_trace_chunk.data).to be_empty
        end

        it 'does not read data when appending' do
          expect(build_trace_chunk).not_to receive(:data)

          build_trace_chunk.append(new_data, offset)
        end

        it_behaves_like 'Appending correctly'
        it_behaves_like 'Scheduling sidekiq worker to flush data to persist store'
      end

      context 'when there are some data' do
        let(:data) { +'Sample data in redis' }

        before do
          build_trace_chunk.send(:unsafe_set_data!, data)
        end

        it 'has data' do
          expect(build_trace_chunk.data).to eq(data)
        end

        it_behaves_like 'Appending correctly'
        it_behaves_like 'Scheduling sidekiq worker to flush data to persist store'
      end
    end

    context 'when data_store is database' do
      let(:data_store) { :database }

      context 'when there are no data' do
        let(:data) { +'' }

        it 'has no data' do
          expect(build_trace_chunk.data).to be_empty
        end

        it_behaves_like 'Appending correctly'
        it_behaves_like 'Scheduling no sidekiq worker'
      end

      context 'when there are some data' do
        let(:raw_data) { +'Sample data in database' }
        let(:data) { raw_data }

        it 'has data' do
          expect(build_trace_chunk.data).to eq(data)
        end

        it_behaves_like 'Appending correctly'
        it_behaves_like 'Scheduling no sidekiq worker'
      end
    end

    context 'when data_store is fog' do
      let(:data_store) { :fog }

      context 'when there are no data' do
        let(:data) { +'' }

        it 'has no data' do
          expect(build_trace_chunk.data).to be_empty
        end

        it_behaves_like 'Appending correctly'
        it_behaves_like 'Scheduling no sidekiq worker'
      end

      context 'when there are some data' do
        let(:data) { +'Sample data in fog' }

        before do
          build_trace_chunk.send(:unsafe_set_data!, data)
        end

        it 'has data' do
          expect(build_trace_chunk.data).to eq(data)
        end

        it_behaves_like 'Appending correctly'
        it_behaves_like 'Scheduling no sidekiq worker'
      end
    end

    describe 'append metrics' do
      let(:metrics) { spy('metrics') }

      before do
        allow(::Gitlab::Ci::Trace::Metrics)
          .to receive(:new)
          .and_return(metrics)
      end

      it 'increments trace operation appended metric' do
        build_trace_chunk.append('123456', 0)

        expect(metrics)
          .to have_received(:increment_trace_operation)
          .with(operation: :appended)
      end
    end
  end

  describe '#truncate' do
    subject { build_trace_chunk.truncate(offset) }

    shared_examples_for 'truncates' do
      context 'when offset is negative' do
        let(:offset) { -1 }

        it { expect { subject }.to raise_error('Offset is out of range') }
      end

      context 'when offset is bigger than data size' do
        let(:offset) { data.bytesize + 1 }

        it { expect { subject }.to raise_error('Offset is out of range') }
      end

      context 'when offset is 10' do
        let(:offset) { 10 }

        it 'truncates' do
          subject

          expect(build_trace_chunk.data).to eq(data.byteslice(0, offset))
        end
      end
    end

    where(:data_store) { %i[redis redis_trace_chunks] }

    with_them do
      let(:data) { +'Sample data in redis' }

      before do
        build_trace_chunk.send(:unsafe_set_data!, data)
      end

      it_behaves_like 'truncates'
    end

    context 'when data_store is database' do
      let(:data_store) { :database }
      let(:raw_data) { +'Sample data in database' }
      let(:data) { raw_data }

      it_behaves_like 'truncates'
    end

    context 'when data_store is fog' do
      let(:data_store) { :fog }
      let(:data) { +'Sample data in fog' }

      before do
        build_trace_chunk.send(:unsafe_set_data!, data)
      end

      it_behaves_like 'truncates'
    end
  end

  describe '#size' do
    subject { build_trace_chunk.size }

    where(:data_store) { %i[redis redis_trace_chunks] }

    with_them do
      context 'when data exists' do
        let(:data) { +'Sample data in redis' }

        before do
          build_trace_chunk.send(:unsafe_set_data!, data)
        end

        it { is_expected.to eq(data.bytesize) }
      end

      context 'when data exists' do
        it { is_expected.to eq(0) }
      end
    end

    context 'when data_store is database' do
      let(:data_store) { :database }

      context 'when data exists' do
        let(:raw_data) { +'Sample data in database' }
        let(:data) { raw_data }

        it { is_expected.to eq(data.bytesize) }
      end

      context 'when data does not exist' do
        it { is_expected.to eq(0) }
      end
    end

    context 'when data_store is fog' do
      let(:data_store) { :fog }

      context 'when data exists' do
        let(:data) { +'Sample data in fog' }
        let(:key) { "tmp/builds/#{build.id}/chunks/#{chunk_index}.log" }

        before do
          build_trace_chunk.send(:unsafe_set_data!, data)
        end

        it { is_expected.to eq(data.bytesize) }
      end

      context 'when data does not exist' do
        it { is_expected.to eq(0) }
      end
    end
  end

  describe '#persist_data!' do
    let(:build) { create(:ci_build, :running) }

    before do
      build_trace_chunk.save!
    end

    subject { build_trace_chunk.persist_data! }

    where(:data_store, :redis_class) do
      [
        [:redis, Ci::BuildTraceChunks::Redis],
        [:redis_trace_chunks, Ci::BuildTraceChunks::RedisTraceChunks]
      ]
    end

    with_them do
      context 'when data exists' do
        before do
          build_trace_chunk.send(:unsafe_set_data!, data)
        end

        context 'when data size reached CHUNK_SIZE' do
          let(:data) { +'a' * described_class::CHUNK_SIZE }

          it 'persists the data' do
            expect(build_trace_chunk.data_store).to eq(data_store.to_s)
            expect(redis_class.new.data(build_trace_chunk)).to eq(data)
            expect(Ci::BuildTraceChunks::Database.new.data(build_trace_chunk)).to be_nil
            expect(Ci::BuildTraceChunks::Fog.new.data(build_trace_chunk)).to be_nil

            subject

            expect(build_trace_chunk.fog?).to be_truthy
            expect(redis_class.new.data(build_trace_chunk)).to be_nil
            expect(Ci::BuildTraceChunks::Database.new.data(build_trace_chunk)).to be_nil
            expect(Ci::BuildTraceChunks::Fog.new.data(build_trace_chunk)).to eq(data)
          end

          it 'calculates CRC32 checksum' do
            subject

            expect(build_trace_chunk.reload.checksum).to eq '3398914352'
          end
        end

        context 'when data size has not reached CHUNK_SIZE' do
          let(:data) { +'Sample data in redis' }

          it 'does not persist the data and the orignal data is intact' do
            expect { subject }.to raise_error(described_class::FailedToPersistDataError)

            expect(build_trace_chunk.data_store).to eq(data_store.to_s)
            expect(redis_class.new.data(build_trace_chunk)).to eq(data)
            expect(Ci::BuildTraceChunks::Database.new.data(build_trace_chunk)).to be_nil
            expect(Ci::BuildTraceChunks::Fog.new.data(build_trace_chunk)).to be_nil
          end

          context 'when chunk is a final one' do
            before do
              create(:ci_build_pending_state, build: build)
            end

            it 'persists the data' do
              subject

              expect(build_trace_chunk.fog?).to be_truthy
            end
          end

          context 'when the chunk has been modifed by a different worker' do
            it 'reloads the chunk before migration' do
              described_class
                .find(build_trace_chunk.id)
                .update!(data_store: :fog)

              build_trace_chunk.persist_data!
            end

            it 'verifies the operation using optimistic locking' do
              allow(build_trace_chunk)
                .to receive(:save!)
                .and_raise(ActiveRecord::StaleObjectError)

              expect { build_trace_chunk.persist_data! }
                .to raise_error(described_class::FailedToPersistDataError)
            end

            it 'does not allow flushing unpersisted chunk' do
              build_trace_chunk.checksum = '12345'

              expect { build_trace_chunk.persist_data! }
                .to raise_error(described_class::FailedToPersistDataError,
                                /Modifed build trace chunk detected/)
            end
          end

          context 'when the chunk is being locked by a different worker' do
            let(:metrics) { spy('metrics') }

            it 'increments stalled chunk trace metric' do
              allow(build_trace_chunk)
                .to receive(:metrics)
                .and_return(metrics)

              expect do
                subject

                expect(metrics)
                  .to have_received(:increment_trace_operation)
                    .with(operation: :stalled)
                    .once
              end.to raise_error(described_class::FailedToPersistDataError)
            end

            def lock_chunk(&block)
              "trace_write:#{build.id}:chunks:#{chunk_index}".then do |key|
                build_trace_chunk.in_lock(key, &block)
              end
            end
          end
        end
      end

      context 'when data does not exist' do
        it 'does not persist' do
          expect { subject }.to raise_error(described_class::FailedToPersistDataError)
        end
      end
    end

    context 'when data_store is database' do
      let(:data_store) { :database }

      context 'when data exists' do
        before do
          build_trace_chunk.send(:unsafe_set_data!, data)
        end

        context 'when data size reached CHUNK_SIZE' do
          let(:data) { +'a' * described_class::CHUNK_SIZE }

          it 'persists the data' do
            expect(build_trace_chunk.database?).to be_truthy
            expect(Ci::BuildTraceChunks::Redis.new.data(build_trace_chunk)).to be_nil
            expect(Ci::BuildTraceChunks::Database.new.data(build_trace_chunk)).to eq(data)
            expect(Ci::BuildTraceChunks::Fog.new.data(build_trace_chunk)).to be_nil

            subject

            expect(build_trace_chunk.fog?).to be_truthy
            expect(Ci::BuildTraceChunks::Redis.new.data(build_trace_chunk)).to be_nil
            expect(Ci::BuildTraceChunks::Database.new.data(build_trace_chunk)).to be_nil
            expect(Ci::BuildTraceChunks::Fog.new.data(build_trace_chunk)).to eq(data)
          end
        end

        context 'when data size has not reached CHUNK_SIZE' do
          let(:data) { +'Sample data in database' }

          it 'does not persist the data and the orignal data is intact' do
            expect { subject }.to raise_error(described_class::FailedToPersistDataError)

            expect(build_trace_chunk.database?).to be_truthy
            expect(Ci::BuildTraceChunks::Redis.new.data(build_trace_chunk)).to be_nil
            expect(Ci::BuildTraceChunks::Database.new.data(build_trace_chunk)).to eq(data)
            expect(Ci::BuildTraceChunks::Fog.new.data(build_trace_chunk)).to be_nil
          end

          context 'when chunk is a final one' do
            before do
              create(:ci_build_pending_state, build: build)
            end

            it 'persists the data' do
              subject

              expect(build_trace_chunk.fog?).to be_truthy
            end
          end
        end
      end

      context 'when data does not exist' do
        it 'does not persist' do
          expect { subject }.to raise_error(described_class::FailedToPersistDataError)
        end
      end
    end

    context 'when data_store is fog' do
      let(:data_store) { :fog }

      context 'when data exists' do
        before do
          build_trace_chunk.send(:unsafe_set_data!, data)
        end

        context 'when data size reached CHUNK_SIZE' do
          let(:data) { 'a' * described_class::CHUNK_SIZE }

          it 'does not change data store' do
            expect(build_trace_chunk.fog?).to be_truthy
            expect(Ci::BuildTraceChunks::Redis.new.data(build_trace_chunk)).to be_nil
            expect(Ci::BuildTraceChunks::Database.new.data(build_trace_chunk)).to be_nil
            expect(Ci::BuildTraceChunks::Fog.new.data(build_trace_chunk)).to eq(data)

            subject

            expect(build_trace_chunk.fog?).to be_truthy
            expect(Ci::BuildTraceChunks::Redis.new.data(build_trace_chunk)).to be_nil
            expect(Ci::BuildTraceChunks::Database.new.data(build_trace_chunk)).to be_nil
            expect(Ci::BuildTraceChunks::Fog.new.data(build_trace_chunk)).to eq(data)
          end
        end

        context 'when data size has not reached CHUNK_SIZE' do
          let(:data) { +'Sample data in fog' }

          it 'does not raise error' do
            expect { subject }.not_to raise_error
          end
        end
      end
    end
  end

  describe 'final?' do
    let(:build) { create(:ci_build, :running) }

    context 'when build pending state exists' do
      before do
        create(:ci_build_pending_state, build: build)
      end

      context 'when chunks is not the last one' do
        before do
          create(:ci_build_trace_chunk, chunk_index: 1, build: build)
        end

        it 'is not a final chunk' do
          expect(build.reload.pending_state).to be_present
          expect(build_trace_chunk).not_to be_final
        end
      end

      context 'when chunks is the last one' do
        it 'is a final chunk' do
          expect(build.reload.pending_state).to be_present
          expect(build_trace_chunk).to be_final
        end
      end
    end

    context 'when build pending state does not exist' do
      context 'when chunks is not the last one' do
        before do
          create(:ci_build_trace_chunk, chunk_index: 1, build: build)
        end

        it 'is not a final chunk' do
          expect(build.reload.pending_state).not_to be_present
          expect(build_trace_chunk).not_to be_final
        end
      end

      context 'when chunks is the last one' do
        it 'is not a final chunk' do
          expect(build.reload.pending_state).not_to be_present
          expect(build_trace_chunk).not_to be_final
        end
      end
    end
  end

  describe 'deletes data in redis after a parent record destroyed' do
    let(:project) { create(:project) }

    before do
      pipeline = create(:ci_pipeline, project: project)
      create(:ci_build, :running, :trace_live, pipeline: pipeline, project: project)
      create(:ci_build, :running, :trace_live, pipeline: pipeline, project: project)
      create(:ci_build, :running, :trace_live, pipeline: pipeline, project: project)
    end

    shared_examples_for 'deletes all build_trace_chunk and data in redis' do
      it 'deletes all build_trace_chunk and data in redis', :sidekiq_might_not_need_inline do
        redis_instance.with do |redis|
          expect(redis.scan_each(match: "gitlab:ci:trace:*:chunks:*").to_a.size).to eq(3)
        end

        expect(described_class.count).to eq(3)

        subject

        expect(described_class.count).to eq(0)

        redis_instance.with do |redis|
          expect(redis.scan_each(match: "gitlab:ci:trace:*:chunks:*").to_a.size).to eq(0)
        end
      end
    end

    context 'when traces are archived' do
      let(:subject) do
        project.builds.each do |build|
          build.reset.success!
        end
      end

      it_behaves_like 'deletes all build_trace_chunk and data in redis'
    end

    context 'when project is destroyed' do
      let(:subject) do
        project.destroy!
      end

      it_behaves_like 'deletes all build_trace_chunk and data in redis'
    end
  end

  describe 'comparable build trace chunks' do
    describe '#<=>' do
      context 'when chunks are associated with different builds' do
        let(:first) { create(:ci_build_trace_chunk, build: build, chunk_index: 1) }
        let(:second) { create(:ci_build_trace_chunk, chunk_index: 1) }

        it 'returns nil' do
          expect(first <=> second).to be_nil
        end
      end

      context 'when there are two chunks with different indexes' do
        let(:first) { create(:ci_build_trace_chunk, build: build, chunk_index: 1) }
        let(:second) { create(:ci_build_trace_chunk, build: build, chunk_index: 0) }

        it 'indicates the the first one is greater than then second' do
          expect(first <=> second).to eq 1
        end
      end

      context 'when there are two chunks with the same index within the same build' do
        let(:chunk) { create(:ci_build_trace_chunk) }

        it 'indicates the these are equal' do
          expect(chunk <=> chunk).to be_zero # rubocop:disable Lint/UselessComparison
        end
      end
    end

    describe '#==' do
      context 'when chunks have the same index' do
        let(:chunk) { create(:ci_build_trace_chunk) }

        it 'indicates that the chunks are equal' do
          expect(chunk).to eq chunk
        end
      end

      context 'when chunks have different indexes' do
        let(:first) { create(:ci_build_trace_chunk, build: build, chunk_index: 1) }
        let(:second) { create(:ci_build_trace_chunk, build: build, chunk_index: 0) }

        it 'indicates that the chunks are not equal' do
          expect(first).not_to eq second
        end
      end

      context 'when chunks are associated with different builds' do
        let(:first) { create(:ci_build_trace_chunk, build: build, chunk_index: 1) }
        let(:second) { create(:ci_build_trace_chunk, chunk_index: 1) }

        it 'indicates that the chunks are not equal' do
          expect(first).not_to eq second
        end
      end
    end
  end

  describe '#live?' do
    subject { build_trace_chunk.live? }

    where(:data_store, :value) do
      [
        [:redis, true],
        [:redis_trace_chunks, true],
        [:database, false],
        [:fog, false]
      ]
    end

    with_them do
      it { is_expected.to eq(value) }
    end
  end

  describe '#flushed?' do
    subject { build_trace_chunk.flushed? }

    where(:data_store, :value) do
      [
        [:redis, false],
        [:redis_trace_chunks, false],
        [:database, true],
        [:fog, true]
      ]
    end

    with_them do
      it { is_expected.to eq(value) }
    end
  end
end
