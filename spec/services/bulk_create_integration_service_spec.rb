# frozen_string_literal: true

require 'spec_helper'

RSpec.describe BulkCreateIntegrationService do
  include JiraServiceHelper

  before_all do
    stub_jira_integration_test
  end

  let_it_be(:excluded_group) { create(:group) }
  let_it_be(:excluded_project) { create(:project, group: excluded_group) }

  let(:instance_integration) { create(:jira_integration, :instance) }
  let(:template_integration) { create(:jira_integration, :template) }
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
          .to eq(integration.reload.data_fields.attributes.except(*excluded_attributes))
      end
    end
  end

  shared_examples 'updates inherit_from_id' do
    it 'updates inherit_from_id attributes' do
      described_class.new(integration, batch, association).execute

      expect(created_integration.reload.inherit_from_id).to eq(inherit_from_id)
    end
  end

  context 'passing an instance-level integration' do
    let(:integration) { instance_integration }
    let(:inherit_from_id) { integration.id }

    context 'with a project association' do
      let!(:project) { create(:project) }
      let(:created_integration) { project.jira_integration }
      let(:batch) { Project.where(id: project.id) }
      let(:association) { 'project' }

      it_behaves_like 'creates integration from batch ids'
      it_behaves_like 'updates inherit_from_id'
    end

    context 'with a group association' do
      let!(:group) { create(:group) }
      let(:created_integration) { Integration.find_by(group: group) }
      let(:batch) { Group.where(id: group.id) }
      let(:association) { 'group' }

      it_behaves_like 'creates integration from batch ids'
      it_behaves_like 'updates inherit_from_id'
    end
  end

  context 'passing a group integration' do
    let_it_be(:group) { create(:group) }

    context 'with a project association' do
      let!(:project) { create(:project, group: group) }
      let(:integration) { create(:jira_integration, group: group, project: nil) }
      let(:created_integration) { project.jira_integration }
      let(:batch) { Project.where(id: Project.minimum(:id)..Project.maximum(:id)).without_integration(integration).in_namespace(integration.group.self_and_descendants) }
      let(:association) { 'project' }
      let(:inherit_from_id) { integration.id }

      it_behaves_like 'creates integration from batch ids'
      it_behaves_like 'updates inherit_from_id'
    end

    context 'with a group association' do
      let!(:subgroup) { create(:group, parent: group) }
      let(:integration) { create(:jira_integration, group: group, project: nil, inherit_from_id: instance_integration.id) }
      let(:created_integration) { Integration.find_by(group: subgroup) }
      let(:batch) { Group.where(id: subgroup.id) }
      let(:association) { 'group' }
      let(:inherit_from_id) { instance_integration.id }

      it_behaves_like 'creates integration from batch ids'
      it_behaves_like 'updates inherit_from_id'
    end
  end

  context 'passing a template integration' do
    let(:integration) { template_integration }

    context 'with a project association' do
      let!(:project) { create(:project) }
      let(:created_integration) { project.jira_integration }
      let(:batch) { Project.where(id: project.id) }
      let(:association) { 'project' }
      let(:inherit_from_id) { integration.id }

      it_behaves_like 'creates integration from batch ids'
    end
  end
end
