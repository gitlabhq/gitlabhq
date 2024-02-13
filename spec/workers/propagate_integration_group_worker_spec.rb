# frozen_string_literal: true

require 'spec_helper'

RSpec.describe PropagateIntegrationGroupWorker, feature_category: :integrations do
  describe '#perform' do
    let_it_be(:group) { create(:group) }
    let_it_be(:another_group) { create(:group) }
    let_it_be(:subgroup1) { create(:group, parent: group) }
    let_it_be(:subgroup2) { create(:group, parent: group) }
    let_it_be(:integration) { create(:redmine_integration, :instance) }

    let(:job_args) { [integration.id, group.id, subgroup2.id] }

    it_behaves_like 'an idempotent worker' do
      it 'calls to Integrations::Propagation::BulkCreateService' do
        expect(Integrations::Propagation::BulkCreateService).to receive(:new)
          .with(integration, match_array([group, another_group, subgroup1, subgroup2]), 'group').twice
          .and_return(double(execute: nil))

        subject
      end

      context 'with a group integration' do
        let_it_be(:integration) { create(:redmine_integration, :group, group: group) }

        it 'calls to Integrations::Propagation::BulkCreateService' do
          expect(Integrations::Propagation::BulkCreateService).to receive(:new)
            .with(integration, match_array([subgroup1, subgroup2]), 'group').twice
            .and_return(double(execute: nil))

          subject
        end
      end
    end

    context 'with an invalid integration id' do
      it 'returns without failure' do
        expect(Integrations::Propagation::BulkCreateService).not_to receive(:new)

        subject.perform(0, 1, 100)
      end
    end
  end
end
