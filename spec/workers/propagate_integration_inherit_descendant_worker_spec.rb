# frozen_string_literal: true

require 'spec_helper'

RSpec.describe PropagateIntegrationInheritDescendantWorker do
  let_it_be(:group) { create(:group) }
  let_it_be(:subgroup) { create(:group, parent: group) }
  let_it_be(:group_integration) { create(:redmine_integration, group: group, project: nil) }
  let_it_be(:subgroup_integration) { create(:redmine_integration, group: subgroup, project: nil, inherit_from_id: group_integration.id) }

  it_behaves_like 'an idempotent worker' do
    let(:job_args) { [group_integration.id, subgroup_integration.id, subgroup_integration.id] }

    it 'calls to BulkUpdateIntegrationService' do
      expect(BulkUpdateIntegrationService).to receive(:new)
        .with(group_integration, match_array(subgroup_integration)).twice
        .and_return(double(execute: nil))

      subject
    end
  end

  context 'with an invalid integration id' do
    it 'returns without failure' do
      expect(BulkUpdateIntegrationService).not_to receive(:new)

      subject.perform(0, subgroup_integration.id, subgroup_integration.id)
    end
  end
end
