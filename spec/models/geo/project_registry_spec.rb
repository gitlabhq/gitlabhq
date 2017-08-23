require 'spec_helper'

describe Geo::ProjectRegistry do
  describe 'relationships' do
    it { is_expected.to belong_to(:project) }
  end

  describe 'validations' do
    it { is_expected.to validate_presence_of(:project) }
  end

  describe '.failed' do
    it 'returns projects where last attempt to sync failed' do
      project = create(:project)
      create(:geo_project_registry, :synced, project: project)
      create(:geo_project_registry, :synced, :dirty, project: project)
      repository_sync_failed = create(:geo_project_registry, :repository_sync_failed, project: project)
      wiki_sync_failed = create(:geo_project_registry, :wiki_sync_failed, project: project)

      expect(described_class.failed).to match_array([repository_sync_failed, wiki_sync_failed])
    end
  end

  describe '.synced' do
    it 'returns synced projects' do
      project = create(:project)
      create(:geo_project_registry, :synced, :dirty, project: project)
      create(:geo_project_registry, :sync_failed, project: project)
      synced_project = create(:geo_project_registry, :synced, project: project)

      expect(described_class.synced).to match_array([synced_project])
    end
  end

  describe '#resync_repository?' do
    it 'returns true when resync_repository is true' do
      subject.resync_repository = true

      expect(subject.resync_repository).to be true
    end

    it 'returns true when last_repository_successful_sync_at is nil' do
      subject.last_repository_successful_sync_at = nil

      expect(subject.resync_repository).to be true
    end

    it 'returns false when resync_repository is false and last_repository_successful_sync_at is present' do
      subject.resync_repository = false
      subject.last_repository_successful_sync_at = Time.now

      expect(subject.resync_repository).to be false
    end
  end

  describe '#resync_wiki?' do
    it 'returns true when resync_wiki is true' do
      subject.resync_wiki = true

      expect(subject.resync_wiki).to be true
    end

    it 'returns true when last_wiki_successful_sync_at is nil' do
      subject.last_wiki_successful_sync_at = nil

      expect(subject.resync_wiki).to be true
    end

    it 'returns false when resync_wiki is false and last_wiki_successful_sync_at is present' do
      subject.resync_wiki = false
      subject.last_wiki_successful_sync_at = Time.now

      expect(subject.resync_wiki).to be false
    end
  end

  describe '#repository_synced_since?' do
    it 'returns false when last_repository_synced_at is nil' do
      subject.last_repository_synced_at = nil

      expect(subject.repository_synced_since?(Time.now)).to be_nil
    end

    it 'returns false when last_repository_synced_at before timestamp' do
      subject.last_repository_synced_at = Time.now - 2.hours

      expect(subject.repository_synced_since?(Time.now)).to be false
    end

    it 'returns true when last_repository_synced_at after timestamp' do
      subject.last_repository_synced_at = Time.now + 2.hours

      expect(subject.repository_synced_since?(Time.now)).to be true
    end
  end

  describe '#wiki_synced_since?' do
    it 'returns false when last_wiki_synced_at is nil' do
      subject.last_wiki_synced_at = nil

      expect(subject.wiki_synced_since?(Time.now)).to be_nil
    end

    it 'returns false when last_wiki_synced_at before timestamp' do
      subject.last_wiki_synced_at = Time.now - 2.hours

      expect(subject.wiki_synced_since?(Time.now)).to be false
    end

    it 'returns true when last_wiki_synced_at after timestamp' do
      subject.last_wiki_synced_at = Time.now + 2.hours

      expect(subject.wiki_synced_since?(Time.now)).to be true
    end
  end
end
