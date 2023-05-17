# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Ci::AppendBuildTraceService, feature_category: :continuous_integration do
  let_it_be(:project) { create(:project) }
  let_it_be(:pipeline) { create(:ci_pipeline, project: project) }
  let_it_be_with_reload(:build) { create(:ci_build, :running, pipeline: pipeline) }

  before do
    stub_feature_flags(ci_enable_live_trace: true)
  end

  context 'build trace append is successful' do
    it 'returns a correct stream size and status code' do
      stream_size = 192.kilobytes
      body_data = 'x' * stream_size
      content_range = "0-#{stream_size}"

      result = described_class
        .new(build, content_range: content_range)
        .execute(body_data)

      expect(result.status).to eq 202
      expect(result.stream_size).to eq stream_size
      expect(build.trace_chunks.count).to eq 2
    end
  end

  context 'when could not correctly append to a trace' do
    it 'responds with content range violation and data stored' do
      allow(build).to receive_message_chain(:trace, :append) { 16 }

      result = described_class
        .new(build, content_range: '0-128')
        .execute('x' * 128)

      expect(result.status).to eq 416
      expect(result.stream_size).to eq 16
    end

    it 'logs exception if build has live trace' do
      build.trace.append('abcd', 0)

      expect(::Gitlab::ErrorTracking)
        .to receive(:log_exception)
        .with(anything, hash_including(chunk_index: 0, chunk_store: 'redis_trace_chunks'))

      result = described_class
        .new(build, content_range: '0-128')
        .execute('x' * 128)

      expect(result.status).to eq 416
      expect(result.stream_size).to eq 4
    end
  end

  context 'when the trace size is exceeded' do
    before do
      project.actual_limits.update!(ci_jobs_trace_size_limit: 1)
    end

    it 'returns 403 status code' do
      stream_size = 1.25.megabytes
      body_data = 'x' * stream_size
      content_range = "0-#{stream_size}"

      result = described_class
        .new(build, content_range: content_range)
        .execute(body_data)

      expect(result.status).to eq 403
      expect(result.stream_size).to be_nil
      expect(build.trace_chunks.count).to eq 0
      expect(build.reload).to be_failed
      expect(build.failure_reason).to eq 'trace_size_exceeded'
    end
  end

  context 'when debug_trace param is provided' do
    let(:metadata) { Ci::BuildMetadata.find_by(build_id: build) }
    let(:stream_size) { 192.kilobytes }
    let(:body_data) { 'x' * stream_size }
    let(:content_range) { "#{body_start}-#{stream_size}" }

    context 'when sending the first trace' do
      let(:body_start) { 0 }

      it 'updates build metadata debug_trace_enabled' do
        described_class
          .new(build, content_range: content_range, debug_trace: true)
          .execute(body_data)

        expect(metadata.debug_trace_enabled).to be(true)
      end
    end

    context 'when sending the second trace' do
      let(:body_start) { 1 }

      it 'does not update build metadata debug_trace_enabled', :aggregate_failures do
        query_recorder = ActiveRecord::QueryRecorder.new do
          described_class.new(build, content_range: content_range, debug_trace: true).execute(body_data)
        end

        expect(metadata.debug_trace_enabled).to be(false)
        expect(query_recorder.log).not_to include(/p_ci_builds_metadata/)
      end
    end
  end
end
