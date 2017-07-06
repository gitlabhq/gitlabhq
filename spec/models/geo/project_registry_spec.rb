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
