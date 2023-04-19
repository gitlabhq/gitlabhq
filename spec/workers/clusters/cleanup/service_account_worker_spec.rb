# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Clusters::Cleanup::ServiceAccountWorker, feature_category: :deployment_management do
  describe '#perform' do
    let!(:cluster) { create(:cluster, :cleanup_removing_service_account) }

    context 'when cluster.cleanup_status is cleanup_removing_service_account' do
      it 'calls Clusters::Cleanup::ServiceAccountService' do
        expect_any_instance_of(Clusters::Cleanup::ServiceAccountService).to receive(:execute).once

        subject.perform(cluster.id)
      end
    end

    context 'when cluster.cleanup_status is not cleanup_removing_service_account' do
      let!(:cluster) { create(:cluster, :with_environments) }

      it 'does not call Clusters::Cleanup::ServiceAccountService' do
        expect(Clusters::Cleanup::ServiceAccountService).not_to receive(:new)

        subject.perform(cluster.id)
      end
    end
  end
end
