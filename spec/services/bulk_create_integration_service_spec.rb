# frozen_string_literal: true

require 'spec_helper'

RSpec.describe BulkCreateIntegrationService, feature_category: :integrations do
  include JiraIntegrationHelpers

  before_all do
    stub_jira_integration_test
  end

  let_it_be(:excluded_group) { create(:group) }
  let_it_be(:excluded_project) { create(:project, group: excluded_group) }

  let(:instance_integration) { create(:jira_integration, :instance) }
  let(:excluded_attributes) do
    %w[
      id project_id group_id inherit_from_id instance template
      created_at updated_at
      encrypted_properties encrypted_properties_iv
    ]
  end

  shared_examples 'creates integration successfully' do
    def attributes(record)
      record.reload.attributes.except(*excluded_attributes)
    end

    it 'updates the inherited integrations' do
      described_class.new(integration, batch, association).execute

      expect(attributes(created_integration)).to eq attributes(integration)
    end

    context 'integration with data fields' do
      let(:excluded_attributes) { %w[id service_id integration_id created_at updated_at] }

      it 'updates the data fields from inherited integrations' do
        described_class.new(integration, batch, association).execute

        expect(attributes(created_integration.data_fields))
          .to eq attributes(integration.data_fields)
      end

      it 'sets created_at and updated_at timestamps', :freeze_time do
        described_class.new(integration, batch, association).execute

        expect(created_integration.data_fields.reload).to have_attributes(
          created_at: eq(Time.current),
          updated_at: eq(Time.current)
        )
      end
    end

    it 'updates inherit_from_id attributes' do
      described_class.new(integration, batch, association).execute

      expect(created_integration.reload.inherit_from_id).to eq(inherit_from_id)
    end

    it 'sets created_at and updated_at timestamps', :freeze_time do
      described_class.new(integration, batch, association).execute

      expect(created_integration.reload).to have_attributes(
        created_at: eq(Time.current),
        updated_at: eq(Time.current)
      )
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

      it_behaves_like 'creates integration successfully'
    end

    context 'with a group association' do
      let!(:group) { create(:group) }
      let(:created_integration) { Integration.find_by(group: group) }
      let(:batch) { Group.where(id: group.id) }
      let(:association) { 'group' }

      it_behaves_like 'creates integration successfully'
    end
  end

  context 'passing a group integration' do
    let_it_be(:group) { create(:group) }

    context 'with a project association' do
      let!(:project) { create(:project, group: group) }
      let(:integration) { create(:jira_integration, :group, group: group) }
      let(:created_integration) { project.jira_integration }
      let(:batch) { Project.where(id: Project.minimum(:id)..Project.maximum(:id)).without_integration(integration).in_namespace(integration.group.self_and_descendants) }
      let(:association) { 'project' }
      let(:inherit_from_id) { integration.id }

      it_behaves_like 'creates integration successfully'

      context 'with different foreign key of data_fields' do
        let(:integration) { create(:zentao_integration, :group, group: group) }
        let(:created_integration) { project.zentao_integration }

        it_behaves_like 'creates integration successfully'
      end
    end

    context 'with a group association' do
      let!(:subgroup) { create(:group, parent: group) }
      let(:integration) { create(:jira_integration, :group, group: group, inherit_from_id: instance_integration.id) }
      let(:created_integration) { Integration.find_by(group: subgroup) }
      let(:batch) { Group.where(id: subgroup.id) }
      let(:association) { 'group' }
      let(:inherit_from_id) { instance_integration.id }

      it_behaves_like 'creates integration successfully'

      context 'with different foreign key of data_fields' do
        let(:integration) { create(:zentao_integration, :group, group: group, inherit_from_id: instance_integration.id) }

        it_behaves_like 'creates integration successfully'
      end
    end
  end
end
