# frozen_string_literal: true

require 'spec_helper'

RSpec.describe ::JiraConnect::SyncBuildsWorker, feature_category: :integrations do
  include AfterNextHelpers

  it_behaves_like 'worker with data consistency', described_class, data_consistency: :delayed

  describe '#perform' do
    let_it_be(:pipeline) { create(:ci_pipeline) }

    let(:sequence_id) { Random.random_number(1..10_000) }
    let(:pipeline_id) { pipeline.id }

    subject { described_class.new.perform(pipeline_id, sequence_id) }

    context 'when pipeline exists' do
      it 'calls the Jira sync service' do
        expect_next(::JiraConnect::SyncService, pipeline.project)
          .to receive(:execute).with(pipelines: contain_exactly(pipeline), update_sequence_id: sequence_id)

        subject
      end
    end

    context 'when pipeline does not exist' do
      let(:pipeline_id) { non_existing_record_id }

      it 'does not call the sync service' do
        expect_next(::JiraConnect::SyncService).not_to receive(:execute)

        subject
      end
    end
  end
end
