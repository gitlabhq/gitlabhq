# frozen_string_literal: true

require 'spec_helper'

RSpec.describe PropagateIntegrationInheritWorker, feature_category: :integrations do
  describe '#perform' do
    let_it_be(:integration) { create(:redmine_integration, :instance) }
    let_it_be(:integration1) { create(:redmine_integration, inherit_from_id: integration.id) }
    let_it_be(:integration2) { create(:bugzilla_integration, inherit_from_id: integration.id) }
    let_it_be(:integration3) { create(:redmine_integration) }

    it_behaves_like 'an idempotent worker' do
      let(:job_args) { [integration.id, integration1.id, integration3.id] }

      it 'calls to Integrations::Propagation::BulkUpdateService' do
        expect(Integrations::Propagation::BulkUpdateService).to receive(:new)
          .with(integration, match_array(integration1)).twice
          .and_return(double(execute: nil))

        subject
      end
    end

    context 'with an integration inheriting from an instance integration in another organization' do
      let_it_be(:other_organization) { create(:organization) }
      let_it_be(:other_instance_integration) do
        create(:redmine_integration, :instance, organization: other_organization)
      end

      let_it_be(:other_inherited_integration) do
        create(:redmine_integration, project: create(:project, organization: other_organization),
          inherit_from_id: other_instance_integration.id)
      end

      it 'does not pass it to Integrations::Propagation::BulkUpdateService' do
        expect(Integrations::Propagation::BulkUpdateService).to receive(:new)
          .with(integration, match_array(integration1))
          .and_return(instance_double(Integrations::Propagation::BulkUpdateService, execute: nil))

        described_class.new.perform(integration.id, integration1.id, other_inherited_integration.id)
      end
    end

    context 'with an invalid integration id' do
      it 'returns without failure' do
        expect(Integrations::Propagation::BulkUpdateService).not_to receive(:new)

        subject.perform(0, integration1.id, integration3.id)
      end
    end
  end
end
