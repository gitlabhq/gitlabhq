# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::Ci::Trace::Archive do
  let_it_be(:job) { create(:ci_build, :success, :trace_live) }
  let_it_be(:trace_metadata) { create(:ci_build_trace_metadata, build: job) }
  let_it_be(:src_checksum) do
    job.trace.read { |stream| Digest::MD5.hexdigest(stream.raw) }
  end

  describe '#execute' do
    subject { described_class.new(job, trace_metadata) }

    it 'computes and assigns checksum' do
      Gitlab::Ci::Trace::ChunkedIO.new(job) do |stream|
        expect { subject.execute!(stream) }.to change { Ci::JobArtifact.count }.by(1)
      end

      expect(trace_metadata.checksum).to eq(src_checksum)
      expect(trace_metadata.trace_artifact).to eq(job.job_artifacts_trace)
    end
  end
end
