require 'spec_helper'

RSpec.describe Geo::WikiSyncService do
  let!(:primary) { create(:geo_node, :primary, host: 'primary-geo-node') }
  let(:lease) { double(try_obtain: true) }

  subject { described_class.new(project) }

  it_behaves_like 'geo base sync execution'

  describe '#execute' do
    let(:project) { create(:project_empty_repo) }
    let(:repository) { project.wiki.repository }
    let(:url_to_repo) { "#{primary.clone_url_prefix}#{project.path_with_namespace}.wiki.git" }

    before do
      allow(Gitlab::ExclusiveLease).to receive(:new)
        .with(subject.lease_key, anything)
        .and_return(lease)

      allow_any_instance_of(Repository).to receive(:fetch_geo_mirror)
        .and_return(true)
    end

    it 'fetches wiki repository' do
      expect(repository).to receive(:fetch_geo_mirror).with(url_to_repo).once

      subject.execute
    end

    it 'releases lease' do
      expect(Gitlab::ExclusiveLease).to receive(:cancel).once.with(
        subject.__send__(:lease_key), anything).and_call_original

      subject.execute
    end

    it 'does not fetch wiki repository if cannot obtain a lease' do
      allow(lease).to receive(:try_obtain) { false }

      expect(repository).not_to receive(:fetch_geo_mirror)

      subject.execute
    end

    it 'rescues exception when Gitlab::Shell::Error is raised' do
      allow(repository).to receive(:fetch_geo_mirror).with(url_to_repo) { raise Gitlab::Shell::Error }

      expect { subject.execute }.not_to raise_error
    end

    it 'rescues exception when Gitlab::Git::Repository::NoRepository is raised' do
      allow(repository).to receive(:fetch_geo_mirror).with(url_to_repo) { raise Gitlab::Git::Repository::NoRepository }

      expect { subject.execute }.not_to raise_error
    end

    context 'tracking database' do
      it 'creates a new registry if does not exists' do
        expect { subject.execute }.to change(Geo::ProjectRegistry, :count).by(1)
      end

      it 'does not create a new registry if one exists' do
        create(:geo_project_registry, project: project)

        expect { subject.execute }.not_to change(Geo::ProjectRegistry, :count)
      end

      context 'when repository sync succeed' do
        let(:registry) { Geo::ProjectRegistry.find_by(project_id: project.id) }

        before do
          subject.execute
        end

        it 'sets last_wiki_synced_at' do
          expect(registry.last_wiki_synced_at).not_to be_nil
        end

        it 'sets last_wiki_successful_sync_at' do
          expect(registry.last_wiki_successful_sync_at).not_to be_nil
        end
      end

      context 'when wiki sync fail' do
        let(:registry) { Geo::ProjectRegistry.find_by(project_id: project.id) }

        before do
          allow(repository).to receive(:fetch_geo_mirror).with(url_to_repo) { raise Gitlab::Shell::Error }

          subject.execute
        end

        it 'sets last_wiki_synced_at' do
          expect(registry.last_wiki_synced_at).not_to be_nil
        end

        it 'resets last_wiki_successful_sync_at' do
          expect(registry.last_wiki_successful_sync_at).to be_nil
        end
      end
    end
  end
end
