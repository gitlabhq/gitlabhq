# frozen_string_literal: true

require 'fast_spec_helper'

RSpec.describe Gitlab::Observability::TracingHelpers, feature_category: :observability do
  let(:test_class) do
    Class.new do
      include Gitlab::Utils::StrongMemoize
      include Gitlab::Observability::TracingHelpers

      attr_reader :pipeline_data, :pipeline

      def initialize(pipeline_data)
        @pipeline_data = pipeline_data
        @pipeline = pipeline_data[:object_attributes]
      end
    end
  end

  let(:root_id) { 100 }
  let(:pipeline_id) { 200 }
  let(:pipeline_data) do
    {
      object_attributes: { id: pipeline_id, root_pipeline_id: root_id }
    }
  end

  subject(:instance) { test_class.new(pipeline_data) }

  describe '#pipeline_trace_id' do
    it 'delegates to TraceContext.trace_id_for with root_pipeline_id' do
      expect(instance.send(:pipeline_trace_id)).to eq(
        Gitlab::Ci::TraceContext.trace_id_for(root_id)
      )
    end
  end

  describe '#root_pipeline_id' do
    it 'returns root_pipeline_id from object_attributes' do
      expect(instance.send(:root_pipeline_id)).to eq(root_id)
    end

    context 'when root_pipeline_id is missing' do
      let(:pipeline_data) { { object_attributes: { id: pipeline_id } } }

      it 'falls back to pipeline id' do
        expect(instance.send(:root_pipeline_id)).to eq(pipeline_id)
      end
    end

    context 'when root_pipeline_id is missing but source_pipeline exists' do
      let(:pipeline_data) do
        {
          object_attributes: { id: pipeline_id },
          trace_correlation_enabled: true,
          source_pipeline: { pipeline_id: 99 }
        }
      end

      it 'logs a warning and falls back to pipeline id' do
        expect(Gitlab::AppLogger).to receive(:warn).with(hash_including(
          message: 'root_pipeline_id missing from pipeline webhook payload with source_pipeline present'
        ))
        expect(instance.send(:root_pipeline_id)).to eq(pipeline_id)
      end
    end
  end

  describe '#pipeline_span_id' do
    it 'delegates to TraceContext.span_id_for_pipeline' do
      expect(instance.send(:pipeline_span_id)).to eq(
        Gitlab::Ci::TraceContext.span_id_for_pipeline(root_id, pipeline_id)
      )
    end
  end

  describe '#job_span_id' do
    it 'delegates to TraceContext.span_id_for_job with :export kind' do
      build = { id: 300 }
      expect(instance.send(:job_span_id, build)).to eq(
        Gitlab::Ci::TraceContext.span_id_for_job(root_id, 300, :export)
      )
    end
  end

  describe 'cross-signal consistency' do
    it 'produces the same trace_id regardless of which converter includes it' do
      trace_id = instance.send(:pipeline_trace_id)
      expect(trace_id).to eq(Gitlab::Ci::TraceContext.trace_id_for(root_id))
      expect(trace_id).to match(/\A[0-9a-f]{32}\z/)
    end
  end
end
