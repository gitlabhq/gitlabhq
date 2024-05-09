# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Integrations::Exclusions::CreateService, feature_category: :integrations do
  let(:integration_name) { 'beyond_identity' }
  let_it_be(:admin_user) { create(:admin) }
  let_it_be(:user) { create(:user) }
  let(:current_user) { admin_user }
  let_it_be(:project) { create(:project) }
  let(:projects) { [project] }
  let(:service) do
    described_class.new(current_user: current_user, integration_name: integration_name, projects: projects)
  end

  describe '#execute', :enable_admin_mode do
    subject(:execute) { service.execute }

    it_behaves_like 'exclusions base service'

    context 'when there are existing custom settings' do
      let!(:existing_integration) do
        create(:beyond_identity_integration)
      end

      let!(:existing_integration2) do
        create(
          :beyond_identity_integration,
          active: true,
          project: project,
          instance: false,
          inherit_from_id: existing_integration.id
        )
      end

      it 'updates those custom settings' do
        execute
        existing_integration2.reload
        expect(existing_integration2.active).to be_falsey
        expect(existing_integration2.inherit_from_id).to be_nil
      end
    end

    it 'creates custom settings' do
      expect { execute }.to change { Integration.count }.from(0).to(1)
      created_integrations = execute.payload
      expect(created_integrations.first.active).to be_falsey
      expect(created_integrations.first.inherit_from_id).to be_nil
    end

    context 'when there are no projects passed' do
      let(:projects) { [] }

      it 'returns success response' do
        expect(execute).to be_success
        expect(execute.payload).to eq([])
      end
    end
  end
end
