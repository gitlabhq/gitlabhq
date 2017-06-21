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
      Geo::ProjectRegistry.create(
        project: project,
        last_repository_synced_at: synced_at,
        last_repository_successful_sync_at: synced_at,
        last_wiki_synced_at: synced_at,
        last_wiki_successful_sync_at: synced_at,
        resync_repository: true,
        resync_wiki: true
      )

      expect(described_class.synced).to be_empty
    end

    it 'does not return projects where last attempt to sync failed' do
      Geo::ProjectRegistry.create(
        project: project,
        last_repository_synced_at: synced_at,
        last_repository_successful_sync_at: nil,
        last_wiki_synced_at: synced_at,
        last_wiki_successful_sync_at: nil,
        resync_repository: true,
        resync_wiki: true
      )

      expect(described_class.synced).to be_empty
    end

    it 'returns synced projects' do
      registry = Geo::ProjectRegistry.create(
        project: project,
        last_repository_synced_at: synced_at,
        last_repository_successful_sync_at: synced_at,
        last_wiki_synced_at: synced_at,
        last_wiki_successful_sync_at: synced_at,
        resync_repository: false,
        resync_wiki: false
      )

      expect(described_class.synced).to match_array([registry])
    end
  end
end
