# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Ci::JobMessage, feature_category: :continuous_integration do
  describe 'validations' do
    it { is_expected.to validate_presence_of(:project_id) }

    describe 'for content' do
      let_it_be(:job) { create(:ci_build) }

      subject(:job_message) do
        described_class.new(job: job, content: content, project_id: job.project_id)
      end

      context 'when message content is longer than the limit' do
        let(:content) { 'x' * (described_class::MAX_CONTENT_LENGTH + 1) }

        it 'is truncated with ellipsis' do
          job_message.save!

          expect(job_message.content).to end_with('x...')
          expect(job_message.content.length).to eq(described_class::MAX_CONTENT_LENGTH)
        end
      end

      context 'when message is not present' do
        let(:content) { '' }

        it 'returns an error' do
          expect(job_message.save).to be_falsey
          expect(job_message.errors[:content]).to be_present
        end
      end

      context 'when message content is valid' do
        let(:content) { 'valid message content' }

        it 'is saved with default error severity' do
          job_message.save!

          expect(job_message.content).to eq(content)
          expect(job_message.severity).to eq('error')
          expect(job_message).to be_error
        end
      end
    end
  end

  describe 'partitioning' do
    include Ci::PartitioningHelpers

    let(:job) { create(:ci_build) }
    let(:job_message) { create(:ci_job_message, job: job) }

    before do
      stub_current_partition_id(ci_testing_partition_id)
    end

    it 'assigns the same partition id as the one that job has' do
      expect(job_message.partition_id).to eq(ci_testing_partition_id)
    end
  end
end
