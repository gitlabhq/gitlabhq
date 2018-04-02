require 'spec_helper'

describe Gitlab::Ci::Trace::ChunkedFile::ChunkedIO, :clean_gitlab_redis_cache do
  include ChunkedIOHelpers

  let(:chunked_io) { described_class.new(job_id, nil, mode) }
  let(:job) { create(:ci_build) }
  let(:job_id) { job.id }
  let(:mode) { 'rb' }

  describe 'ChunkStore is Redis', :partial_support do
    let(:chunk_store) { Gitlab::Ci::Trace::ChunkedFile::ChunkStore::Redis }

    before do
      allow_any_instance_of(described_class).to receive(:chunk_store).and_return(chunk_store)
      allow_any_instance_of(described_class).to receive(:buffer_size).and_return(128.kilobytes)
    end

    it_behaves_like 'ChunkedIO shared tests'
  end

  describe 'ChunkStore is Database' do
    let(:chunk_store) { Gitlab::Ci::Trace::ChunkedFile::ChunkStore::Database }

    before do
      allow_any_instance_of(described_class).to receive(:chunk_store).and_return(chunk_store)
      allow_any_instance_of(described_class).to receive(:buffer_size).and_return(128.kilobytes)
    end

    it_behaves_like 'ChunkedIO shared tests'
  end
end
