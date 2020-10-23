# frozen_string_literal: true

require 'spec_helper'

RSpec.describe BulkCreateIntegrationService do
  include JiraServiceHelper

  before do
    stub_jira_service_test
  end

  let_it_be(:instance_integration) { create(:jira_service, :instance) }
  let_it_be(:template_integration) { create(:jira_service, :template) }
  let(:excluded_attributes) { %w[id project_id group_id inherit_from_id instance template created_at updated_at] }

  shared_examples 'creates integration from batch ids' do
    it 'updates the inherited integrations' do
      described_class.new(integration, batch, association).execute

      expect(created_integration.attributes.except(*excluded_attributes))
        .to eq(integration.attributes.except(*excluded_attributes))
    end

    context 'integration with data fields' do
      let(:excluded_attributes) { %w[id service_id created_at updated_at] }

      it 'updates the data fields from inherited integrations' do
        described_class.new(integration, batch, association).execute

        expect(created_integration.reload.data_fields.attributes.except(*excluded_attributes))
          .to eq(integration.data_fields.attributes.except(*excluded_attributes))
      end
    end
  end

  shared_examples 'updates inherit_from_id' do
    it 'updates inherit_from_id attributes' do
      described_class.new(integration, batch, association).execute

      expect(created_integration.reload.inherit_from_id).to eq(inherit_from_id)
    end
  end

  shared_examples 'updates project callbacks' do
    it 'updates projects#has_external_issue_tracker for issue tracker services' do
      described_class.new(integration, batch, association).execute

      expect(project.reload.has_external_issue_tracker).to eq(true)
    end

    context 'with an external wiki integration' do
      let(:integration) { create(:external_wiki_service, :instance) }

      it 'updates projects#has_external_wiki for external wiki services' do
        described_class.new(integration, batch, association).execute

        expect(project.reload.has_external_wiki).to eq(true)
      end
    end
  end

  shared_examples 'does not update project callbacks' do
    it 'does not update projects#has_external_issue_tracker for issue tracker services' do
      described_class.new(integration, batch, association).execute

      expect(project.reload.has_external_issue_tracker).to eq(false)
    end

    context 'with an inactive external wiki integration' do
      let(:integration) { create(:external_wiki_service, :instance, active: false) }

      it 'does not update projects#has_external_wiki for external wiki services' do
        described_class.new(integration, batch, association).execute

        expect(project.reload.has_external_wiki).to eq(false)
      end
    end
  end

  context 'with an instance-level integration' do
    let(:integration) { instance_integration }
    let(:inherit_from_id) { integration.id }

    context 'with a project association' do
      let!(:project) { create(:project) }
      let(:created_integration) { project.jira_service }
      let(:batch) { Project.without_integration(integration) }
      let(:association) { 'project' }

      it_behaves_like 'creates integration from batch ids'
      it_behaves_like 'updates inherit_from_id'
      it_behaves_like 'updates project callbacks'

      context 'when integration is not active' do
        before do
          integration.update!(active: false)
        end

        it_behaves_like 'does not update project callbacks'
      end
    end

    context 'with a group association' do
      let_it_be(:group) { create(:group) }
      let(:created_integration) { Service.find_by(group: group) }
      let(:batch) { Group.all }
      let(:association) { 'group' }

      it_behaves_like 'creates integration from batch ids'
      it_behaves_like 'updates inherit_from_id'

      context 'with a subgroup association' do
        let_it_be(:group_integration) { create(:jira_service, group: group, project: nil, inherit_from_id: instance_integration.id) }
        let_it_be(:subgroup) { create(:group, parent: group) }
        let(:integration) { group_integration }
        let(:created_integration) { Service.find_by(group: subgroup) }
        let(:batch) { Group.all }
        let(:association) { 'group' }
        let(:inherit_from_id) { instance_integration.id }

        it_behaves_like 'creates integration from batch ids'
        it_behaves_like 'updates inherit_from_id'
      end
    end
  end

  context 'with a template integration' do
    let(:integration) { template_integration }

    context 'with a project association' do
      let!(:project) { create(:project) }
      let(:created_integration) { project.jira_service }
      let(:batch) { Project.all }
      let(:association) { 'project' }
      let(:inherit_from_id) { integration.id }

      it_behaves_like 'creates integration from batch ids'
      it_behaves_like 'updates project callbacks'
    end
  end
end
