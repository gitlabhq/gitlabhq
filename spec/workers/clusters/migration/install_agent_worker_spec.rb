# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Clusters::Migration::InstallAgentWorker, feature_category: :deployment_management do
  let(:migration) { create(:cluster_agent_migration) }

  it_behaves_like 'an idempotent worker' do
    let(:job_args) { migration.id }
  end

  describe '#perform' do
    let(:migration_id) { migration.id }

    subject(:perform) { described_class.new.perform(migration_id) }

    it 'calls the agent installation service' do
      expect_next_instance_of(Clusters::Migration::InstallAgentService, migration) do |service|
        expect(service).to receive(:execute).once
      end

      perform
    end

    context 'when the migration record no longer exists' do
      let(:migration_id) { non_existing_record_id }

      it 'completes without raising an error' do
        expect { perform }.not_to raise_error
      end
    end
  end
end
