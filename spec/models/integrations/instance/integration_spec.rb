# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Integrations::Instance::Integration, feature_category: :integrations do
  subject(:instance_integration) { build(:instance_integration) }

  describe 'associations' do
    it 'has issue_tracker_data association' do
      is_expected.to have_one(:issue_tracker_data)
        .autosave(true)
        .inverse_of(:instance_integration)
        .with_foreign_key(:instance_integration_id)
        .class_name('Integrations::IssueTrackerData')
    end

    it 'has jira_tracker_data association' do
      is_expected.to have_one(:jira_tracker_data)
        .autosave(true)
        .inverse_of(:instance_integration)
        .with_foreign_key(:instance_integration_id)
        .class_name('Integrations::JiraTrackerData')
    end

    it 'has zentao_tracker_data association' do
      is_expected.to have_one(:zentao_tracker_data)
        .autosave(true)
        .inverse_of(:instance_integration)
        .with_foreign_key(:instance_integration_id)
        .class_name('Integrations::ZentaoTrackerData')
    end
  end

  describe '#instance_level?' do
    it 'returns true' do
      expect(instance_integration.instance_level?).to be(true)
    end
  end

  describe '#group_level?' do
    it 'returns false' do
      expect(instance_integration.group_level?).to be(false)
    end
  end

  describe '#project_level?' do
    it 'returns false' do
      expect(instance_integration.project_level?).to be(false)
    end
  end

  describe '.table_name' do
    it 'returns instance_integrations' do
      expect(described_class.table_name).to eq('instance_integrations')
    end
  end
end
