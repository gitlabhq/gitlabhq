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

  it { is_expected.to allow_value(nil).for(:jira_cloud_app_deployment_gating_environments) }

  it do
    is_expected.to allow_value('production,development,staging,testing')
    .for(:jira_cloud_app_deployment_gating_environments)
  end

  it { is_expected.to allow_value('production,development').for(:jira_cloud_app_deployment_gating_environments) }
  it { is_expected.not_to allow_value('productasd').for(:jira_cloud_app_deployment_gating_environments) }
  it { is_expected.not_to allow_value('productasd=').for(:jira_cloud_app_deployment_gating_environments) }

  describe '#fields' do
    subject(:fields) { integration.fields }

    it 'returns custom fields' do
      expect(fields.pluck(:name)).to eq(%w[jira_cloud_app_service_ids jira_cloud_app_enable_deployment_gating
        jira_cloud_app_deployment_gating_environments])
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

    it 'is valid if jira_cloud_app_service_ids is empty' do
      jira_cloud_app_integration.jira_cloud_app_service_ids = ""

      jira_cloud_app_integration.validate

      expect(jira_cloud_app_integration.errors).to be_empty
    end

    it 'is invalid if jira_cloud_app_service_ids exceed the limit' do
      stub_const("#{described_class}::SERVICE_IDS_LIMIT", 2)

      jira_cloud_app_integration.jira_cloud_app_service_ids = 'b:asfasd=,b:bsfasd=,b:csfasd='

      jira_cloud_app_integration.validate

      expect(jira_cloud_app_integration.errors[:jira_cloud_app_service_ids])
        .to include('cannot have more than 2 service IDs')
    end
  end

  describe 'validation and formatting of deployment_gating_environments' do
    let_it_be(:integration) { create(:jira_cloud_app_integration) }

    it 'deduplicates environment names' do
      integration.jira_cloud_app_enable_deployment_gating = true
      integration.jira_cloud_app_deployment_gating_environments = "development,development, production,development"

      expect(integration.save).to eq(true)
      expect(integration.jira_cloud_app_deployment_gating_environments).to eq('development,production')
    end

    it 'raises an error if enabled is set to true but environment names is empty' do
      integration.jira_cloud_app_enable_deployment_gating = true
      integration.jira_cloud_app_deployment_gating_environments = ""

      integration.validate

      expect(integration.errors).not_to be_empty
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
