# frozen_string_literal: true

require 'spec_helper'

RSpec.describe BulkUpdateIntegrationService, feature_category: :integrations do
  include JiraIntegrationHelpers

  before_all do
    stub_jira_integration_test
  end

  let(:excluded_attributes) do
    %w[
      id project_id group_id inherit_from_id instance template
      created_at updated_at encrypted_properties encrypted_properties_iv
    ]
  end

  let(:batch) do
    Integration.inherited_descendants_from_self_or_ancestors_from(subgroup_integration).where(id: group_integration.id..integration.id)
  end

  let_it_be(:group) { create(:group) }
  let_it_be(:subgroup) { create(:group, parent: group) }
  let_it_be(:group_integration) { create(:jira_integration, :group, group: group, url: 'http://group.jira.com') }
  let_it_be(:excluded_integration) { create(:jira_integration, :group, group: create(:group), url: 'http://another.jira.com', push_events: false) }
  let_it_be(:subgroup_integration) do
    create(:jira_integration, :group,
      group: subgroup,
      inherit_from_id: group_integration.id,
      url: 'http://subgroup.jira.com',
      push_events: true
    )
  end

  let_it_be(:integration) do
    create(:jira_integration,
      project: create(:project, group: subgroup),
      inherit_from_id: subgroup_integration.id,
      url: 'http://project.jira.com',
      push_events: false
    )
  end

  context 'with inherited integration' do
    it 'updates the integration', :aggregate_failures do
      described_class.new(subgroup_integration.reload, batch).execute

      expect(integration.reload.inherit_from_id).to eq(group_integration.id)
      expect(integration.reload.attributes.except(*excluded_attributes))
        .to eq(subgroup_integration.reload.attributes.except(*excluded_attributes))

      expect(excluded_integration.reload.inherit_from_id).not_to eq(group_integration.id)
      expect(excluded_integration.reload.attributes.except(*excluded_attributes))
        .not_to eq(subgroup_integration.attributes.except(*excluded_attributes))
    end

    it 'does not change the created_at timestamp' do
      subgroup_integration.update_column(:created_at, Time.utc(2022, 1, 1))

      expect do
        described_class.new(subgroup_integration, batch).execute
      end.not_to change { integration.reload.created_at }
    end

    it 'sets the updated_at timestamp to the current time', time_travel_to: Time.utc(2022, 1, 1) do
      expect do
        described_class.new(subgroup_integration, batch).execute
      end.to change { integration.reload.updated_at }.to(Time.current)
    end

    context 'with integration with data fields' do
      let(:excluded_attributes) do
        %w[id integration_id created_at updated_at encrypted_properties encrypted_properties_iv]
      end

      it 'updates the data fields from the integration', :aggregate_failures do
        described_class.new(subgroup_integration, batch).execute

        expect(integration.reload.data_fields.attributes.except(*excluded_attributes))
          .to eq(subgroup_integration.reload.data_fields.attributes.except(*excluded_attributes))

        expect(integration.data_fields.attributes.except(*excluded_attributes))
          .not_to eq(excluded_integration.data_fields.attributes.except(*excluded_attributes))
      end

      it 'does not change the created_at timestamp' do
        subgroup_integration.data_fields.update_column(:created_at, Time.utc(2022, 1, 2))

        expect do
          described_class.new(subgroup_integration, batch).execute
        end.not_to change { integration.data_fields.reload.created_at }
      end

      it 'sets the updated_at timestamp to the current time', time_travel_to: Time.utc(2022, 1, 1) do
        expect do
          described_class.new(subgroup_integration, batch).execute
        end.to change { integration.data_fields.reload.updated_at }.to(Time.current)
      end
    end
  end

  it 'works with batch as an ActiveRecord::Relation' do
    expect do
      described_class.new(group_integration, Integration.where(id: integration.id)).execute
    end.to change { integration.reload.url }.to(group_integration.url)
  end

  it 'works with batch as an array of ActiveRecord objects' do
    expect do
      described_class.new(group_integration, [integration]).execute
    end.to change { integration.reload.url }.to(group_integration.url)
  end

  context 'with different foreign key of data_fields' do
    let(:integration) { create(:zentao_integration, project: create(:project, group: group)) }
    let(:group_integration) do
      create(:zentao_integration, :group,
        group: group,
        url: 'https://group.zentao.net',
        api_token: 'GROUP_TOKEN',
        zentao_product_xid: '1'
      )
    end

    it 'works with batch as an array of ActiveRecord objects' do
      expect do
        described_class.new(group_integration, [integration]).execute
      end.to change { integration.reload.url }.to(group_integration.url)
    end
  end
end
