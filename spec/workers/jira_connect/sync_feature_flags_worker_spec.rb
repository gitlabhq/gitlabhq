# frozen_string_literal: true

require 'spec_helper'

RSpec.describe ::JiraConnect::SyncFeatureFlagsWorker, feature_category: :integrations do
  include AfterNextHelpers

  it_behaves_like 'worker with data consistency', described_class, data_consistency: :delayed

  describe '#perform' do
    let_it_be(:feature_flag) { create(:operations_feature_flag) }

    let(:sequence_id) { Random.random_number(1..10_000) }
    let(:feature_flag_id) { feature_flag.id }

    subject { described_class.new.perform(feature_flag_id, sequence_id) }

    context 'when object exists' do
      it 'calls the Jira sync service' do
        expect_next(::JiraConnect::SyncService, feature_flag.project)
          .to receive(:execute).with(feature_flags: contain_exactly(feature_flag), update_sequence_id: sequence_id)

        subject
      end
    end

    context 'when object does not exist' do
      let(:feature_flag_id) { non_existing_record_id }

      it 'does not call the sync service' do
        expect_next(::JiraConnect::SyncService).not_to receive(:execute)

        subject
      end
    end
  end
end
