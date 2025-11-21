# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Analytics::CustomDashboards::DashboardVersion, feature_category: :custom_dashboards_foundation do
  describe 'associations' do
    it { is_expected.to belong_to(:dashboard).class_name('Analytics::CustomDashboards::Dashboard') }
    it { is_expected.to belong_to(:organization).class_name('Organizations::Organization') }
    it { is_expected.to belong_to(:updated_by).class_name('User').optional }
  end

  describe 'validations' do
    subject(:dashboard_version) { build(:dashboard_version) }

    it { is_expected.to validate_presence_of(:version_number) }
    it { is_expected.to validate_numericality_of(:version_number).only_integer.is_greater_than(0) }
    it { is_expected.to validate_presence_of(:config) }
    it { is_expected.to validate_presence_of(:dashboard) }

    context 'when config is not a Hash' do
      it 'is invalid and adds an error' do
        dashboard_version.config = 'not_json'
        expect(dashboard_version).to be_invalid
        expect(dashboard_version.errors[:config]).to include('must be a JSON object')
      end
    end

    context 'when config does not match schema' do
      it 'is invalid' do
        dashboard_version.config = { 'invalid' => 'schema' }
        expect(dashboard_version).to be_invalid
        expect(dashboard_version.errors[:config]).to be_present
      end
    end

    context 'when config is valid according to schema' do
      it 'is valid' do
        valid_config = {
          version: "2",
          title: "Test Dashboard",
          panels: [
            {
              title: "Test Panel",
              visualization: "number",
              gridAttributes: { width: 4, height: 2 }
            }
          ]
        }

        dashboard_version.config = valid_config
        expect(dashboard_version).to be_valid
      end
    end
  end

  describe 'database integrity' do
    let(:dashboard) { create(:dashboard) }
    let(:valid_config) do
      {
        version: "2",
        title: "Version Config",
        panels: [
          {
            title: "Panel",
            visualization: "number",
            gridAttributes: { width: 4, height: 2 }
          }
        ]
      }
    end

    it 'persists with valid attributes' do
      version = described_class.new(
        dashboard: dashboard,
        organization: dashboard.organization,
        version_number: 1,
        config: valid_config,
        updated_by_id: dashboard.created_by_id
      )

      expect(version).to be_valid
      version.save!
      expect(version.reload.version_number).to eq(1)
      expect(version.reload.config).to eq(valid_config.deep_stringify_keys)
    end
  end
end
