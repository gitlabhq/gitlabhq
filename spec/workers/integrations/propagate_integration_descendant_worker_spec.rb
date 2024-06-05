# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Integrations::PropagateIntegrationDescendantWorker, feature_category: :integrations do
  let_it_be(:group) { create(:group) }
  let_it_be(:subgroup) { create(:group, parent: group) }
  let_it_be(:other_subgroup) { create(:group, parent: group) }

  let!(:group_integration) { create(:beyond_identity_integration, instance: false, group: group) }
  let!(:subgroup_integration) do
    create(:beyond_identity_integration, instance: false, group: subgroup, inherit_from_id: group_integration.id)
  end

  let!(:custom_settings_subgroup_integration) do
    create(:beyond_identity_integration, instance: false, group: other_subgroup, inherit_from_id: nil)
  end

  it_behaves_like 'an idempotent worker' do
    let(:job_args) { [group_integration.id, subgroup_integration.id, custom_settings_subgroup_integration.id] }

    it 'calls to Integrations::Propagation::BulkUpdateService' do
      expect(Integrations::Propagation::BulkUpdateService).to receive(:new)
        .with(group_integration, match_array([subgroup_integration, custom_settings_subgroup_integration])).twice
        .and_return(instance_double(Integrations::Propagation::BulkUpdateService, execute: nil))

      perform_idempotent_work
    end
  end

  context 'with an invalid integration id' do
    it 'returns without failure' do
      expect(Integrations::Propagation::BulkUpdateService).not_to receive(:new)
      expect(described_class.new.perform(0, subgroup_integration.id, subgroup_integration.id)).to be_nil
    end
  end
end
