# frozen_string_literal: true

require 'spec_helper'

RSpec.describe BulkUpdateIntegrationService do
  include JiraServiceHelper

  before_all do
    stub_jira_service_test
  end

  let(:excluded_attributes) { %w[id project_id group_id inherit_from_id instance template created_at updated_at] }

  let_it_be(:group) { create(:group) }
  let_it_be(:group_integration) do
    JiraService.create!(
      group: group,
      active: true,
      push_events: true,
      url: 'http://update-jira.instance.com',
      username: 'user',
      password: 'secret'
    )
  end

  let_it_be(:subgroup_integration) do
    JiraService.create!(
      inherit_from_id: group_integration.id,
      group: create(:group, parent: group),
      active: true,
      push_events: true,
      url: 'http://update-jira.instance.com',
      username: 'user',
      password: 'secret'
    )
  end

  let_it_be(:integration) do
    JiraService.create!(
      project: create(:project),
      instance: false,
      active: true,
      push_events: false,
      url: 'http://jira.instance.com',
      username: 'user',
      password: 'secret'
    )
  end

  context 'with inherited integration' do
    it 'updates the integration' do
      described_class.new(subgroup_integration, Service.where.not(project: nil)).execute

      expect(integration.reload.inherit_from_id).to eq(group_integration.id)
      expect(integration.attributes.except(*excluded_attributes))
        .to eq(subgroup_integration.attributes.except(*excluded_attributes))
    end

    context 'with integration with data fields' do
      let(:excluded_attributes) { %w[id service_id created_at updated_at] }

      it 'updates the data fields from the integration' do
        described_class.new(subgroup_integration, Service.where.not(project: nil)).execute

        expect(integration.reload.data_fields.attributes.except(*excluded_attributes))
          .to eq(subgroup_integration.data_fields.attributes.except(*excluded_attributes))
      end
    end
  end
end
