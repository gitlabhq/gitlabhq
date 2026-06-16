# frozen_string_literal: true

require 'fast_spec_helper'
require 'openssl'

require_relative '../../../../lib/gitlab/ci/trace_context'

RSpec.describe Gitlab::Ci::TraceContext, feature_category: :fleet_visibility do
  describe '.trace_id_for' do
    it 'returns 32 lowercase hex characters' do
      expect(described_class.trace_id_for(42)).to match(/\A[0-9a-f]{32}\z/)
    end

    it 'zero-pads the pipeline ID' do
      expect(described_class.trace_id_for(42)).to eq('0000000000000000000000000000002a')
    end

    it 'handles id=0' do
      expect(described_class.trace_id_for(0)).to eq('0' * 32)
    end

    it 'handles large IDs', :aggregate_failures do
      large_id = 2**63
      result = described_class.trace_id_for(large_id)
      expect(result).to match(/\A[0-9a-f]{32}\z/)
      expect(result).to eq(format('%032x', large_id))
    end

    it 'differs for different pipeline IDs' do
      expect(described_class.trace_id_for(42)).not_to eq(described_class.trace_id_for(43))
    end
  end

  describe '.span_id_for_job' do
    it 'returns 16 lowercase hex characters' do
      expect(described_class.span_id_for_job(100, 200, :running)).to match(/\A[0-9a-f]{16}\z/)
    end

    it 'matches SHA256 derivation formula' do
      expected = OpenSSL::Digest::SHA256.hexdigest('100:200:running')[0, 16]
      expect(described_class.span_id_for_job(100, 200, :running)).to eq(expected)
    end

    it 'defaults kind to :default' do
      expected = OpenSSL::Digest::SHA256.hexdigest('100:200:default')[0, 16]
      expect(described_class.span_id_for_job(100, 200)).to eq(expected)
    end

    it 'is deterministic' do
      a = described_class.span_id_for_job(1, 2, :x)
      b = described_class.span_id_for_job(1, 2, :x)
      expect(a).to eq(b)
    end

    it 'differs across kinds' do
      results = %i[lifecycle pending running].map do |kind|
        described_class.span_id_for_job(100, 200, kind)
      end
      expect(results.uniq.size).to eq(3)
    end

    it 'differs across job IDs' do
      a = described_class.span_id_for_job(100, 200, :default)
      b = described_class.span_id_for_job(100, 201, :default)
      expect(a).not_to eq(b)
    end
  end

  describe '.span_id_for_pipeline' do
    it 'returns 16 lowercase hex characters' do
      expect(described_class.span_id_for_pipeline(1, 2)).to match(/\A[0-9a-f]{16}\z/)
    end

    it 'matches SHA256 derivation formula' do
      expected = OpenSSL::Digest::SHA256.hexdigest('pipeline:1:2')[0, 16]
      expect(described_class.span_id_for_pipeline(1, 2)).to eq(expected)
    end

    it 'differs from span_id_for_job with same inputs' do
      pipeline_span = described_class.span_id_for_pipeline(100, 200)
      job_span = described_class.span_id_for_job(100, 200, :default)
      expect(pipeline_span).not_to eq(job_span)
    end
  end

  describe '.span_id_for_bridge' do
    it 'returns 16 lowercase hex characters' do
      expect(described_class.span_id_for_bridge(42)).to match(/\A[0-9a-f]{16}\z/)
    end

    it 'zero-pads the bridge ID' do
      expect(described_class.span_id_for_bridge(42)).to eq('000000000000002a')
    end

    it 'handles id=0' do
      expect(described_class.span_id_for_bridge(0)).to eq('0' * 16)
    end
  end

  describe '.build_traceparent' do
    it 'returns a valid W3C traceparent string' do
      result = described_class.build_traceparent(42, 100)
      expect(result).to match(/\A00-[0-9a-f]{32}-[0-9a-f]{16}-01\z/)
    end

    it 'uses trace_id_for for the trace-id component' do
      result = described_class.build_traceparent(42, 100)
      trace_id = result.split('-')[1]
      expect(trace_id).to eq(described_class.trace_id_for(42))
    end

    it 'uses span_id_for_job for the parent-id component' do
      result = described_class.build_traceparent(42, 100)
      span_id = result.split('-')[2]
      expect(span_id).to eq(described_class.span_id_for_job(42, 100, :default))
    end

    it 'respects the kind parameter' do
      default = described_class.build_traceparent(42, 100)
      custom = described_class.build_traceparent(42, 100, :running)
      expect(default).not_to eq(custom)
    end

    it 'sets version=00 and flags=01 (sampled)', :aggregate_failures do
      result = described_class.build_traceparent(42, 100)
      parts = result.split('-')
      expect(parts[0]).to eq('00')
      expect(parts[3]).to eq('01')
    end
  end
end
