# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Ci::PipelineMessage, feature_category: :continuous_integration do
  describe 'validations' do
    it { is_expected.to validate_presence_of(:project_id) }

    describe 'for content' do
      subject { described_class.new(pipeline: pipeline, content: content, project_id: pipeline.project_id) }

      let_it_be(:pipeline) { create(:ci_pipeline) }

      context 'when message content is longer than the limit' do
        let(:content) { 'x' * (described_class::MAX_CONTENT_LENGTH + 1) }

        it 'is truncated with ellipsis' do
          subject.save!

          expect(subject.content).to end_with('x...')
          expect(subject.content.length).to eq(described_class::MAX_CONTENT_LENGTH)
        end
      end

      context 'when message is not present' do
        let(:content) { '' }

        it 'returns an error' do
          expect(subject.save).to be_falsey
          expect(subject.errors[:content]).to be_present
        end
      end

      context 'when message content is valid' do
        let(:content) { 'valid message content' }

        it 'is saved with default error severity' do
          subject.save!

          expect(subject.content).to eq(content)
          expect(subject.severity).to eq('error')
          expect(subject).to be_error
        end

        it 'is persist the defined severity' do
          subject.severity = :warning

          subject.save!

          expect(subject.content).to eq(content)
          expect(subject.severity).to eq('warning')
          expect(subject).to be_warning
        end
      end
    end
  end

  describe 'partitioning' do
    include Ci::PartitioningHelpers

    let(:pipeline) { create(:ci_pipeline) }
    let(:pipeline_message) { create(:ci_pipeline_message, pipeline: pipeline) }

    before do
      stub_current_partition_id(ci_testing_partition_id)
    end

    it 'assigns the same partition id as the one that pipeline has' do
      expect(pipeline_message.partition_id).to eq(ci_testing_partition_id)
    end
  end
end
