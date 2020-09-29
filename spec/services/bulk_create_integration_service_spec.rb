# frozen_string_literal: true

require 'spec_helper'

RSpec.describe BulkCreateIntegrationService do
  include JiraServiceHelper

  before do
    stub_jira_service_test
  end

  let(:excluded_attributes) { %w[id project_id group_id inherit_from_id instance template created_at updated_at] }
  let!(:instance_integration) { create(:jira_service, :instance) }
  let!(:template_integration) { create(:jira_service, :template) }

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

      expect(created_integration.reload.inherit_from_id).to eq(integration.id)
    end
  end

  shared_examples 'runs project callbacks' do
    it 'updates projects#has_external_issue_tracker for issue tracker services' do
      described_class.new(integration, batch, association).execute

      expect(project.reload.has_external_issue_tracker).to eq(true)
    end

    context 'with an external wiki integration' do
      let(:integration) do
        ExternalWikiService.create!(
          instance: true,
          active: true,
          push_events: false,
          external_wiki_url: 'http://external-wiki-url.com'
        )
      end

      it 'updates projects#has_external_wiki for external wiki services' do
        described_class.new(integration, batch, association).execute

        expect(project.reload.has_external_wiki).to eq(true)
      end
    end
  end

  context 'with an instance-level integration' do
    let(:integration) { instance_integration }

    context 'with a project association' do
      let!(:project) { create(:project) }
      let(:created_integration) { project.jira_service }
      let(:batch) { Project.all }
      let(:association) { 'project' }

      it_behaves_like 'creates integration from batch ids'
      it_behaves_like 'updates inherit_from_id'
      it_behaves_like 'runs project callbacks'
    end

    context 'with a group association' do
      let!(:group) { create(:group) }
      let(:created_integration) { Service.find_by(group: group) }
      let(:batch) { Group.all }
      let(:association) { 'group' }

      it_behaves_like 'creates integration from batch ids'
      it_behaves_like 'updates inherit_from_id'
    end
  end

  context 'with a template integration' do
    let(:integration) { template_integration }

    context 'with a project association' do
      let!(:project) { create(:project) }
      let(:created_integration) { project.jira_service }
      let(:batch) { Project.all }
      let(:association) { 'project' }

      it_behaves_like 'creates integration from batch ids'
      it_behaves_like 'runs project callbacks'
    end
  end
end
