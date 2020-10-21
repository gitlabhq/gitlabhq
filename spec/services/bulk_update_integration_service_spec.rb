# frozen_string_literal: true

require 'spec_helper'

RSpec.describe BulkUpdateIntegrationService do
  include JiraServiceHelper

  before do
    stub_jira_service_test
  end

  let(:excluded_attributes) { %w[id project_id group_id inherit_from_id instance template created_at updated_at] }
  let!(:instance_integration) do
    JiraService.create!(
      instance: true,
      active: true,
      push_events: true,
      url: 'http://update-jira.instance.com',
      username: 'user',
      password: 'secret'
    )
  end

  let!(:integration) do
    JiraService.create!(
      project: create(:project),
      inherit_from_id: instance_integration.id,
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
      described_class.new(instance_integration, Service.inherit_from_id(instance_integration.id)).execute

      expect(integration.reload.inherit_from_id).to eq(instance_integration.id)
      expect(integration.attributes.except(*excluded_attributes))
        .to eq(instance_integration.attributes.except(*excluded_attributes))
    end

    context 'with integration with data fields' do
      let(:excluded_attributes) { %w[id service_id created_at updated_at] }

      it 'updates the data fields from the integration' do
        described_class.new(instance_integration, Service.inherit_from_id(instance_integration.id)).execute

        expect(integration.reload.data_fields.attributes.except(*excluded_attributes))
          .to eq(instance_integration.data_fields.attributes.except(*excluded_attributes))
      end
    end
  end
end
