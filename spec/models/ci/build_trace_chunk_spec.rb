require 'spec_helper'

describe Ci::BuildTraceChunk, :clean_gitlab_redis_shared_state do
  include ExclusiveLeaseHelpers

  set(:build) { create(:ci_build, :running) }
  let(:chunk_index) { 0 }
  let(:data_store) { :redis }
  let(:raw_data) { nil }

  let(:build_trace_chunk) do
    described_class.new(build: build, chunk_index: chunk_index, data_store: data_store, raw_data: raw_data)
  end

  before do
    stub_feature_flags(ci_enable_live_trace: true)
    stub_artifacts_object_storage
  end

  context 'FastDestroyAll' do
    let(:parent) { create(:project) }
    let(:pipeline) { create(:ci_pipeline, project: parent) }
    let(:build) { create(:ci_build, :running, :trace_live, pipeline: pipeline, project: parent) }
    let(:subjects) { build.trace_chunks }

    it_behaves_like 'fast destroyable'

    def external_data_counter
      Gitlab::Redis::SharedState.with do |redis|
        redis.scan_each(match: "gitlab:ci:trace:*:chunks:*").to_a.size
      end
    end
  end

  describe 'CHUNK_SIZE' do
    it 'Chunk size can not be changed without special care' do
      expect(described_class::CHUNK_SIZE).to eq(128.kilobytes)
    end
  end

  describe '.all_stores' do
    subject { described_class.all_stores }

    it 'returns a correctly ordered array' do
      is_expected.to eq(%w[redis database fog])
    end

    it 'returns redis store as the the lowest precedence' do
      expect(subject.first).to eq('redis')
    end

    it 'returns fog store as the the highest precedence' do
      expect(subject.last).to eq('fog')
    end
  end

  describe '#data' do
    subject { build_trace_chunk.data }

    context 'when data_store is redis' do
      let(:data_store) { :redis }

      before do
        build_trace_chunk.send(:unsafe_set_data!, 'Sample data in redis')
      end

      it { is_expected.to eq('Sample data in redis') }
    end

    context 'when data_store is database' do
      let(:data_store) { :database }
      let(:raw_data) { 'Sample data in database' }

      it { is_expected.to eq('Sample data in database') }
    end

    context 'when data_store is fog' do
      let(:data_store) { :fog }

      before do
        build_trace_chunk.send(:unsafe_set_data!, 'Sample data in fog')
      end

      it { is_expected.to eq('Sample data in fog') }
    end
  end

  describe '#append' do
    subject { build_trace_chunk.append(new_data, offset) }

    let(:new_data) { 'Sample new data' }
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
          let(:new_data) { '' }

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
      context 'when new data fullfilled chunk size' do
        let(:new_data) { 'a' * described_class::CHUNK_SIZE }

        it 'schedules trace chunk flush worker' do
          expect(Ci::BuildTraceChunkFlushWorker).to receive(:perform_async).once

          subject
        end

        it 'migrates data to object storage' do
          perform_enqueued_jobs do
            subject

            build_trace_chunk.reload
            expect(build_trace_chunk.fog?).to be_truthy
            expect(build_trace_chunk.data).to eq(new_data)
          end
        end
      end
    end

    shared_examples_for 'Scheduling no sidekiq worker' do
      context 'when new data fullfilled chunk size' do
        let(:new_data) { 'a' * described_class::CHUNK_SIZE }

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

    context 'when data_store is redis' do
      let(:data_store) { :redis }

      context 'when there are no data' do
        let(:data) { '' }

        it 'has no data' do
          expect(build_trace_chunk.data).to be_empty
        end

        it_behaves_like 'Appending correctly'
        it_behaves_like 'Scheduling sidekiq worker to flush data to persist store'
      end

      context 'when there are some data' do
        let(:data) { 'Sample data in redis' }

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
        let(:data) { '' }

        it 'has no data' do
          expect(build_trace_chunk.data).to be_empty
        end

        it_behaves_like 'Appending correctly'
        it_behaves_like 'Scheduling no sidekiq worker'
      end

      context 'when there are some data' do
        let(:raw_data) { 'Sample data in database' }
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
        let(:data) { '' }

        it 'has no data' do
          expect(build_trace_chunk.data).to be_empty
        end

        it_behaves_like 'Appending correctly'
        it_behaves_like 'Scheduling no sidekiq worker'
      end

      context 'when there are some data' do
        let(:data) { 'Sample data in fog' }

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

    context 'when data_store is redis' do
      let(:data_store) { :redis }
      let(:data) { 'Sample data in redis' }

      before do
        build_trace_chunk.send(:unsafe_set_data!, data)
      end

      it_behaves_like 'truncates'
    end

    context 'when data_store is database' do
      let(:data_store) { :database }
      let(:raw_data) { 'Sample data in database' }
      let(:data) { raw_data }

      it_behaves_like 'truncates'
    end

    context 'when data_store is fog' do
      let(:data_store) { :fog }
      let(:data) { 'Sample data in fog' }

      before do
        build_trace_chunk.send(:unsafe_set_data!, data)
      end

      it_behaves_like 'truncates'
    end
  end

  describe '#size' do
    subject { build_trace_chunk.size }

    context 'when data_store is redis' do
      let(:data_store) { :redis }

      context 'when data exists' do
        let(:data) { 'Sample data in redis' }

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
        let(:raw_data) { 'Sample data in database' }
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
        let(:data) { 'Sample data in fog' }
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
    subject { build_trace_chunk.persist_data! }

    shared_examples_for 'Atomic operation' do
      context 'when the other process is persisting' do
        let(:lease_key) { "trace_write:#{build_trace_chunk.build.id}:chunks:#{build_trace_chunk.chunk_index}" }

        before do
          stub_exclusive_lease_taken(lease_key)
        end

        it 'raise an error' do
          expect { subject }.to raise_error('Failed to obtain a lock')
        end
      end
    end

    context 'when data_store is redis' do
      let(:data_store) { :redis }

      context 'when data exists' do
        let(:data) { 'Sample data in redis' }

        before do
          build_trace_chunk.send(:unsafe_set_data!, data)
        end

        it 'persists the data' do
          expect(build_trace_chunk.redis?).to be_truthy
          expect(Ci::BuildTraceChunks::Redis.new.data(build_trace_chunk)).to eq(data)
          expect(Ci::BuildTraceChunks::Database.new.data(build_trace_chunk)).to be_nil
          expect { Ci::BuildTraceChunks::Fog.new.data(build_trace_chunk) }.to raise_error(Excon::Error::NotFound)

          subject

          expect(build_trace_chunk.fog?).to be_truthy
          expect(Ci::BuildTraceChunks::Redis.new.data(build_trace_chunk)).to be_nil
          expect(Ci::BuildTraceChunks::Database.new.data(build_trace_chunk)).to be_nil
          expect(Ci::BuildTraceChunks::Fog.new.data(build_trace_chunk)).to eq(data)
        end

        it_behaves_like 'Atomic operation'
      end

      context 'when data does not exist' do
        it 'does not persist' do
          expect { subject }.to raise_error('Can not persist empty data')
        end
      end
    end

    context 'when data_store is database' do
      let(:data_store) { :database }

      context 'when data exists' do
        let(:data) { 'Sample data in database' }

        before do
          build_trace_chunk.send(:unsafe_set_data!, data)
        end

        it 'persists the data' do
          expect(build_trace_chunk.database?).to be_truthy
          expect(Ci::BuildTraceChunks::Redis.new.data(build_trace_chunk)).to be_nil
          expect(Ci::BuildTraceChunks::Database.new.data(build_trace_chunk)).to eq(data)
          expect { Ci::BuildTraceChunks::Fog.new.data(build_trace_chunk) }.to raise_error(Excon::Error::NotFound)

          subject

          expect(build_trace_chunk.fog?).to be_truthy
          expect(Ci::BuildTraceChunks::Redis.new.data(build_trace_chunk)).to be_nil
          expect(Ci::BuildTraceChunks::Database.new.data(build_trace_chunk)).to be_nil
          expect(Ci::BuildTraceChunks::Fog.new.data(build_trace_chunk)).to eq(data)
        end

        it_behaves_like 'Atomic operation'
      end

      context 'when data does not exist' do
        it 'does not persist' do
          expect { subject }.to raise_error('Can not persist empty data')
        end
      end
    end

    context 'when data_store is fog' do
      let(:data_store) { :fog }

      context 'when data exists' do
        let(:data) { 'Sample data in fog' }

        before do
          build_trace_chunk.send(:unsafe_set_data!, data)
        end

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

        it_behaves_like 'Atomic operation'
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
      it do
        Gitlab::Redis::SharedState.with do |redis|
          expect(redis.scan_each(match: "gitlab:ci:trace:*:chunks:*").to_a.size).to eq(3)
        end

        expect(described_class.count).to eq(3)

        subject

        expect(described_class.count).to eq(0)

        Gitlab::Redis::SharedState.with do |redis|
          expect(redis.scan_each(match: "gitlab:ci:trace:*:chunks:*").to_a.size).to eq(0)
        end
      end
    end

    context 'when traces are archived' do
      let(:subject) do
        project.builds.each do |build|
          build.success!
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
end
