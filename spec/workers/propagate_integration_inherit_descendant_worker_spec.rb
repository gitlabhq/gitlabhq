# frozen_string_literal: true

require 'spec_helper'

RSpec.describe PropagateIntegrationInheritDescendantWorker, feature_category: :integrations do
  let_it_be(:group) { create(:group) }
  let_it_be(:subgroup) { create(:group, parent: group) }
  let_it_be(:group_integration) { create(:redmine_integration, :group, group: group) }
  let_it_be(:subgroup_integration) { create(:redmine_integration, :group, group: subgroup, inherit_from_id: group_integration.id) }

  it_behaves_like 'an idempotent worker' do
    let(:job_args) { [group_integration.id, subgroup_integration.id, subgroup_integration.id] }

    it 'calls to Integrations::Propagation::BulkUpdateService' do
      expect(Integrations::Propagation::BulkUpdateService).to receive(:new)
        .with(group_integration, match_array(subgroup_integration)).twice
        .and_return(double(execute: nil))

      perform_idempotent_work
    end
  end

  context 'with an invalid integration id' do
    it 'returns without failure' do
      expect(Integrations::Propagation::BulkUpdateService).not_to receive(:new)
      described_class.new.perform(0, subgroup_integration.id, subgroup_integration.id)
    end
  end
end
