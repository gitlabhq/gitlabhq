# frozen_string_literal: true

require 'spec_helper'

RSpec.describe BulkUpdateIntegrationService do
  include JiraServiceHelper

  before_all do
    stub_jira_integration_test
  end

  let(:excluded_attributes) { %w[id project_id group_id inherit_from_id instance template created_at updated_at] }
  let(:batch) do
    Integration.inherited_descendants_from_self_or_ancestors_from(subgroup_integration).where(id: group_integration.id..integration.id)
  end

  let_it_be(:group) { create(:group) }
  let_it_be(:subgroup) { create(:group, parent: group) }
  let_it_be(:group_integration) do
    Integrations::Jira.create!(
      group: group,
      url: 'http://group.jira.com'
    )
  end

  let_it_be(:subgroup_integration) do
    Integrations::Jira.create!(
      inherit_from_id: group_integration.id,
      group: subgroup,
      url: 'http://subgroup.jira.com',
      push_events: true
    )
  end

  let_it_be(:excluded_integration) do
    Integrations::Jira.create!(
      group: create(:group),
      url: 'http://another.jira.com',
      push_events: false
    )
  end

  let_it_be(:integration) do
    Integrations::Jira.create!(
      project: create(:project, group: subgroup),
      inherit_from_id: subgroup_integration.id,
      url: 'http://project.jira.com',
      push_events: false
    )
  end

  context 'with inherited integration' do
    it 'updates the integration', :aggregate_failures do
      described_class.new(subgroup_integration, batch).execute

      expect(integration.reload.inherit_from_id).to eq(group_integration.id)
      expect(integration.reload.attributes.except(*excluded_attributes))
        .to eq(subgroup_integration.attributes.except(*excluded_attributes))

      expect(excluded_integration.reload.inherit_from_id).not_to eq(group_integration.id)
      expect(excluded_integration.reload.attributes.except(*excluded_attributes))
        .not_to eq(subgroup_integration.attributes.except(*excluded_attributes))
    end

    context 'with integration with data fields' do
      let(:excluded_attributes) { %w[id service_id created_at updated_at] }

      it 'updates the data fields from the integration', :aggregate_failures do
        described_class.new(subgroup_integration, batch).execute

        expect(integration.reload.data_fields.attributes.except(*excluded_attributes))
          .to eq(subgroup_integration.reload.data_fields.attributes.except(*excluded_attributes))

        expect(integration.data_fields.attributes.except(*excluded_attributes))
          .not_to eq(excluded_integration.data_fields.attributes.except(*excluded_attributes))
      end
    end
  end
end
