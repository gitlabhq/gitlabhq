# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::Ci::Pipeline::AccessLogger, feature_category: :continuous_integration do
  let_it_be(:project) { build_stubbed(:project) }
  let_it_be(:pipeline) { build_stubbed(:ci_pipeline, project: project, created_at: 1.week.ago) }

  let(:archived) { false }
  let(:logger) do
    described_class.new(pipeline: pipeline, archived: archived)
  end

  describe '#log' do
    context 'when the pipeline is archived' do
      let(:expected_data) do
        {
          'correlation_id' => a_kind_of(String),
          'project_id' => project.id,
          'pipeline_id' => pipeline.id,
          'archived' => true
        }
      end

      let(:archived) { true }

      it 'creates a log entry' do
        expect(Gitlab::AppJsonLogger)
          .to receive(:info)
          .with(a_hash_including(expected_data))
          .and_call_original

        logger.log
      end
    end

    context 'when the pipeline is tentatively archived' do
      let(:expected_data) do
        {
          'correlation_id' => a_kind_of(String),
          'project_id' => project.id,
          'pipeline_id' => pipeline.id,
          'archived' => false
        }
      end

      before do
        stub_const("#{described_class}::PROVISIONAL_ARCHIVE_VALUE", 1.day)
      end

      it 'creates a log entry' do
        expect(Gitlab::AppJsonLogger)
          .to receive(:info)
          .with(a_hash_including(expected_data))
          .and_call_original

        logger.log
      end
    end

    context 'when the pipeline is not archived' do
      it 'does not log' do
        expect(Gitlab::AppJsonLogger).not_to receive(:info)

        logger.log
      end
    end

    context 'when the feature flag is disabled' do
      let(:archived) { true }

      before do
        stub_feature_flags(ci_pipeline_archived_access: false)
      end

      it 'does not log' do
        expect(Gitlab::AppJsonLogger).not_to receive(:info)

        logger.log
      end
    end
  end
end
