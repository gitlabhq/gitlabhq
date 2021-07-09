# frozen_string_literal: true

require 'spec_helper'

RSpec.describe ::JiraConnect::SyncDeploymentsWorker do
  include AfterNextHelpers

  it_behaves_like 'worker with data consistency',
                  described_class,
                  feature_flag: :load_balancing_for_jira_connect_workers,
                  data_consistency: :delayed

  describe '#perform' do
    let_it_be(:deployment) { create(:deployment) }

    let(:sequence_id) { Random.random_number(1..10_000) }
    let(:object_id) { deployment.id }

    subject { described_class.new.perform(object_id, sequence_id) }

    context 'when the object exists' do
      it 'calls the Jira sync service' do
        expect_next(::JiraConnect::SyncService, deployment.project)
          .to receive(:execute).with(deployments: contain_exactly(deployment), update_sequence_id: sequence_id)

        subject
      end
    end

    context 'when the object does not exist' do
      let(:object_id) { non_existing_record_id }

      it 'does not call the sync service' do
        expect_next(::JiraConnect::SyncService).not_to receive(:execute)

        subject
      end
    end
  end
end
