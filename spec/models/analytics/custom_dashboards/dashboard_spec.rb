# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Analytics::CustomDashboards::Dashboard, feature_category: :custom_dashboards_foundation do
  let(:user) { create(:user) }
  let(:namespace) { create(:namespace) }
  let(:organization) { create(:organization) }

  let(:valid_config) do
    {
      version: "2",
      title: "Test Dashboard",
      description: "Test description",
      panels: [
        {
          title: "Test Panel",
          visualization: "number",
          gridAttributes: { width: 4, height: 2 }
        }
      ]
    }
  end

  describe 'associations' do
    it { is_expected.to belong_to(:namespace).optional }
    it { is_expected.to belong_to(:organization).required }
    it { is_expected.to belong_to(:created_by).class_name('User').required }
    it { is_expected.to belong_to(:updated_by).class_name('User').optional }
    it { is_expected.to have_one(:search_data) }
    it { is_expected.to have_many(:dashboard_versions).class_name('Analytics::CustomDashboards::DashboardVersion') }
  end

  describe 'validations' do
    subject { build(:dashboard, created_by: user, name: 'Dashboard', config: valid_config) }

    it { is_expected.to validate_presence_of(:name) }
    it { is_expected.to validate_length_of(:name).is_at_most(255) }
    it { is_expected.to validate_length_of(:description).is_at_most(2048) }
    it { is_expected.to validate_presence_of(:config) }

    it 'validates config is a JSON object' do
      dashboard = build(:dashboard, created_by: user, config: 'not a hash')
      expect(dashboard).not_to be_valid
      expect(dashboard.errors[:config]).to include('must be a JSON object')
    end
  end

  describe 'callbacks' do
    it 'creates a search data row after create' do
      dashboard = create(:dashboard, created_by: user, config: valid_config)
      dashboard.reload

      search_data = Analytics::CustomDashboards::SearchData.find_by(
        custom_dashboard_id: dashboard.id
      )
      expect(search_data).to be_present
    end

    it 'creates a new version when config changes' do
      dashboard = create(:dashboard, created_by: user, config: valid_config)

      updated_config = {
        version: "2",
        title: "Updated Dashboard",
        description: "Updated description",
        panels: [
          {
            title: "Updated Panel",
            visualization: "chart",
            gridAttributes: { width: 6, height: 3 }
          }
        ]
      }

      expect { dashboard.update!(config: updated_config) }.to change {
        dashboard.dashboard_versions.count
      }.by(1)

      version = dashboard.dashboard_versions.last
      expect(version.version_number).to eq(1)
      expect(version.config).to eq(updated_config.deep_stringify_keys)
    end

    it 'does not create a version if config did not change' do
      dashboard = create(:dashboard, created_by: user, config: valid_config)
      expect { dashboard.update!(name: 'Updated Name') }.not_to change { dashboard.dashboard_versions.count }
    end
  end

  describe '#create_config_version' do
    let(:dashboard) do
      create(:dashboard,
        created_by: user,
        updated_by: user,
        organization: organization,
        config: valid_config
      )
    end

    context 'when no previous version exists' do
      it 'creates version 1' do
        version = dashboard.send(:create_config_version)

        expect(version.version_number).to eq(1)
        expect(version.organization_id).to eq(dashboard.organization_id)
        expect(version.config).to eq(valid_config.deep_stringify_keys)
        expect(version.updated_by_id).to eq(user.id)
      end
    end

    context 'when a previous version exists' do
      before do
        create(:dashboard_version,
          dashboard: dashboard,
          organization_id: dashboard.organization_id,
          version_number: 1,
          config: valid_config
        )
      end

      it 'increments version number' do
        version = dashboard.send(:create_config_version)

        expect(version.version_number).to eq(2)
        expect(version.organization_id).to eq(dashboard.organization_id)
        expect(version.config).to eq(valid_config.deep_stringify_keys)
        expect(version.updated_by_id).to eq(user.id)
      end
    end
  end
end
