# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Integrations::JiraCloudApp, feature_category: :integrations do
  let_it_be(:project) { create(:project, :repository) }

  subject(:integration) { build(:jira_cloud_app_integration, project: project) }

  it_behaves_like Integrations::HasAvatar

  it { is_expected.to allow_value(nil).for(:jira_cloud_app_service_ids) }
  it { is_expected.to allow_value('b:asfasd=,b:asfasd=').for(:jira_cloud_app_service_ids) }
  it { is_expected.to allow_value('b:asfasd=').for(:jira_cloud_app_service_ids) }
  it { is_expected.not_to allow_value('b: asfasd=').for(:jira_cloud_app_service_ids) }
  it { is_expected.not_to allow_value('b:asfasd=, b:asfasd=').for(:jira_cloud_app_service_ids) }
  it { is_expected.not_to allow_value('b:asfasd= , b:asfasd=').for(:jira_cloud_app_service_ids) }
  it { is_expected.not_to allow_value('b:asfasd= ,b:asfasd=').for(:jira_cloud_app_service_ids) }
  it { is_expected.not_to allow_value('b:asfasd=;b:asfasd= , b:asfasd=').for(:jira_cloud_app_service_ids) }

  describe '#fields' do
    subject(:fields) { integration.fields }

    it 'returns custom fields' do
      expect(fields.pluck(:name)).to eq(%w[jira_cloud_app_service_ids])
    end
  end

  describe '#sections' do
    subject(:sections) { integration.sections.pluck(:type) }

    it 'includes SECTION_TYPE_CONFIGURATION' do
      expect(sections).to include(described_class::SECTION_TYPE_CONFIGURATION)
    end
  end

  describe '#validate_service_ids_limit' do
    let(:jira_cloud_app_integration) { build_stubbed(:jira_cloud_app_integration) }

    it 'does not raise any errors if service_ids empty' do
      jira_cloud_app_integration.jira_cloud_app_service_ids = ""

      jira_cloud_app_integration.validate

      expect(jira_cloud_app_integration.errors).to be_empty
    end

    it 'raise error if limit exceeds' do
      stub_const("#{described_class}::SERVICE_IDS_LIMIT", 2)

      jira_cloud_app_integration.jira_cloud_app_service_ids = 'b:asfasd=,b:bsfasd=,b:csfasd='

      jira_cloud_app_integration.validate
    end
  end

  describe '#editable?' do
    it 'is true when integration is active' do
      expect(integration).to be_editable
    end

    it 'is false when integration is disabled' do
      integration.active = false

      expect(integration).not_to be_editable
    end
  end
end
