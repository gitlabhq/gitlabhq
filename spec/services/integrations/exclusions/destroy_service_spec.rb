# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Integrations::Exclusions::DestroyService, feature_category: :integrations do
  let(:integration_name) { 'beyond_identity' }
  let_it_be(:admin_user) { create(:admin) }
  let_it_be(:user) { create(:user) }
  let(:current_user) { admin_user }
  let_it_be(:project) { create(:project) }
  let(:service) do
    described_class.new(current_user: current_user, integration_name: integration_name, projects: [project])
  end

  describe '#execute', :enable_admin_mode do
    subject(:execute) { service.execute }

    it_behaves_like 'exclusions base service'

    context 'when there are existing custom settings' do
      let!(:exclusion) do
        create(:beyond_identity_integration, active: false, project: project, instance: false, inherit_from_id: nil)
      end

      it 'deletes the exclusions' do
        expect { execute }.to change { Integration.count }.from(1).to(0)
        expect(execute.payload).to contain_exactly(exclusion)
      end

      context 'and the integration is active for the instance' do
        let!(:instance_integration) { create(:beyond_identity_integration) }

        it 'updates the exclusion integration to be active' do
          expect { execute }.to change { exclusion.reload.active }.from(false).to(true)
          expect(exclusion.inherit_from_id).to eq(instance_integration.id)
        end
      end
    end
  end
end
