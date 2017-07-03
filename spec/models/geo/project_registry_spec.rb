require 'spec_helper'

describe Geo::ProjectRegistry, models: true do
  describe 'relationships' do
    it { is_expected.to belong_to(:project) }
  end

  describe 'validations' do
    it { is_expected.to validate_presence_of(:project) }
  end

  describe '.synced' do
    let(:project) { create(:empty_project) }
    let(:synced_at) { Time.now }

    it 'does not return dirty projects' do
      create(:geo_project_registry, :synced, :dirty, project: project)

      expect(described_class.synced).to be_empty
    end

    it 'does not return projects where last attempt to sync failed' do
      create(:geo_project_registry, :sync_failed, project: project)

      expect(described_class.synced).to be_empty
    end

    it 'returns synced projects' do
      registry = create(:geo_project_registry, :synced, project: project)

      expect(described_class.synced).to match_array([registry])
    end
  end
end
