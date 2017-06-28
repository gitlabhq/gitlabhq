require 'spec_helper'

describe Geo::RepositorySyncService, services: true do
  let!(:primary) { create(:geo_node, :primary, host: 'primary-geo-node') }
  let(:lease) { double(try_obtain: true) }

  subject { described_class.new(project.id) }

  before do
    allow(Gitlab::ExclusiveLease).to receive(:new)
      .with(subject.__send__(:lease_key), anything)
      .and_return(lease)

    allow_any_instance_of(Repository).to receive(:fetch_geo_mirror)
      .and_return(true)
  end

  describe '#execute' do
    context 'when project has never been synced' do
      let(:project) { create(:project_empty_repo) }

      it 'fetches project repositories' do
        fetch_count = 0

        allow_any_instance_of(Repository).to receive(:fetch_geo_mirror) do
          fetch_count += 1
        end

        subject.execute

        expect(fetch_count).to eq 2
      end

      it 'expires repository caches' do
        expect_any_instance_of(Repository).to receive(:expire_all_method_caches).once
        expect_any_instance_of(Repository).to receive(:expire_branch_cache).once
        expect_any_instance_of(Repository).to receive(:expire_content_cache).once

        subject.execute
      end

      it 'releases lease' do
        expect(Gitlab::ExclusiveLease).to receive(:cancel).once.with(
          subject.__send__(:lease_key), anything).and_call_original

        subject.execute
      end

      it 'does not fetch project repositories if cannot obtain a lease' do
        allow(lease).to receive(:try_obtain) { false }

        expect_any_instance_of(Repository).not_to receive(:fetch_geo_mirror)

        subject.execute
      end

      context 'tracking database' do
        it 'creates a new registry' do
          expect { subject.execute }.to change(Geo::ProjectRegistry, :count).by(1)
        end

        it 'sets last_repository_successful_sync_at when repository sync succeed' do
          subject.execute

          registry = Geo::ProjectRegistry.find_by(project_id: project.id)

          expect(registry.last_repository_successful_sync_at).not_to be_nil
        end

        it 'resets last_repository_successful_sync_at when repository sync fail' do
          allow_any_instance_of(Repository).to receive(:fetch_geo_mirror).with(/#{project.path_with_namespace}\.git/) { raise Gitlab::Shell::Error }

          subject.execute

          registry = Geo::ProjectRegistry.find_by(project_id: project.id)

          expect(registry.last_repository_successful_sync_at).to be_nil
        end

        it 'sets last_wiki_successful_sync_at when wiki sync succeed' do
          subject.execute

          registry = Geo::ProjectRegistry.find_by(project_id: project.id)

          expect(registry.last_wiki_successful_sync_at).not_to be_nil
        end

        it 'resets last_wiki_successful_sync_at when wiki sync fail' do
          allow_any_instance_of(Repository).to receive(:fetch_geo_mirror).with(/#{project.path_with_namespace}\.wiki.git/) { raise Gitlab::Shell::Error }

          subject.execute

          registry = Geo::ProjectRegistry.find_by(project_id: project.id)

          expect(registry.last_wiki_successful_sync_at).to be_nil
        end
      end
    end

    context 'when project has been synced' do
      let(:project) { create(:project) }
      let(:last_repository_synced_at) { 5.days.ago }
      let(:last_wiki_synced_at) { 4.days.ago }

      let!(:registry) do
        create(:geo_project_registry, :synced,
          project: project,
          last_repository_synced_at: last_repository_synced_at,
          last_repository_successful_sync_at: last_repository_synced_at,
          last_wiki_synced_at: last_wiki_synced_at,
          last_wiki_successful_sync_at: last_wiki_synced_at)
      end

      it 'does not fetch project repositories' do
        expect_any_instance_of(Repository).not_to receive(:fetch_geo_mirror)

        subject.execute
      end

      context 'tracking database' do
        it 'does not create a new registry' do
          expect { subject.execute }.not_to change(Geo::ProjectRegistry, :count)
        end

        it 'does not update last_repository_successful_sync_at' do
          subject.execute

          registry.reload

          expect(registry.last_repository_synced_at).to be_within(1.minute).of(last_repository_synced_at)
          expect(registry.last_repository_successful_sync_at).to be_within(1.minute).of(last_repository_synced_at)
        end

        it 'does not update last_wiki_successful_sync_at' do
          subject.execute

          registry.reload

          expect(registry.last_wiki_synced_at).to be_within(1.minute).of(last_wiki_synced_at)
          expect(registry.last_wiki_successful_sync_at).to be_within(1.minute).of(last_wiki_synced_at)
        end
      end
    end

    context 'when last attempt to sync project repositories failed' do
      let(:project) { create(:project) }
      let!(:registry) { create(:geo_project_registry, :sync_failed, project: project) }

      it 'fetches project repositories' do
        fetch_count = 0

        allow_any_instance_of(Repository).to receive(:fetch_geo_mirror) do
          fetch_count += 1
        end

        subject.execute

        expect(fetch_count).to eq 2
      end

      context 'tracking database' do
        it 'sets last_repository_successful_sync_at' do
          subject.execute

          registry.reload

          expect(registry.last_repository_successful_sync_at).not_to be_nil
        end

        it 'sets last_wiki_successful_sync_at' do
          subject.execute

          registry.reload

          expect(registry.last_wiki_successful_sync_at).not_to be_nil
        end
      end
    end

    context 'when project repository is dirty' do
      let(:project) { create(:project) }
      let(:last_wiki_synced_at) { 4.days.ago }

      let!(:registry) do
        create(:geo_project_registry, :synced, :repository_dirty,
          project: project,
          last_wiki_synced_at: last_wiki_synced_at,
          last_wiki_successful_sync_at: last_wiki_synced_at)
      end

      it 'fetches project repository' do
        expect_any_instance_of(Repository).to receive(:fetch_geo_mirror).once

        subject.execute
      end

      context 'exceptions' do
        it 'rescues when Gitlab::Shell::Error is raised' do
          allow_any_instance_of(Repository).to receive(:fetch_geo_mirror).with(/#{project.path_with_namespace}\.git/) { raise Gitlab::Shell::Error }

          expect { subject.execute }.not_to raise_error
        end

        it 'rescues exception and fires after_create hook when Gitlab::Git::Repository::NoRepository is raised' do
          allow_any_instance_of(Repository).to receive(:fetch_geo_mirror).with(/#{project.path_with_namespace}\.git/) { raise Gitlab::Git::Repository::NoRepository }

          expect_any_instance_of(Repository).to receive(:after_create)

          expect { subject.execute }.not_to raise_error
        end
      end

      context 'tracking database' do
        it 'updates last_repository_successful_sync_at' do
          subject.execute

          registry.reload

          expect(registry.last_repository_synced_at).to be_within(1.minute).of(DateTime.now)
          expect(registry.last_repository_successful_sync_at).to be_within(1.minute).of(DateTime.now)
        end

        it 'does not update last_wiki_successful_sync_at' do
          subject.execute

          registry.reload

          expect(registry.last_wiki_synced_at).to be_within(1.minute).of(last_wiki_synced_at)
          expect(registry.last_wiki_successful_sync_at).to be_within(1.minute).of(last_wiki_synced_at)
        end

        it 'resets resync_repository' do
          subject.execute

          registry.reload

          expect(registry.resync_repository).to be false
        end
      end
    end

    context 'when project wiki is dirty' do
      let(:project) { create(:project) }
      let(:last_repository_synced_at) { 5.days.ago }

      let!(:registry) do
        create(:geo_project_registry, :synced, :wiki_dirty,
          project: project,
          last_repository_synced_at: last_repository_synced_at,
          last_repository_successful_sync_at: last_repository_synced_at)
      end

      it 'fetches wiki repository' do
        expect_any_instance_of(Repository).to receive(:fetch_geo_mirror).once

        subject.execute
      end

      context 'exceptions' do
        it 'rescues exception when Gitlab::Shell::Error is raised' do
          allow_any_instance_of(Repository).to receive(:fetch_geo_mirror).with(/#{project.path_with_namespace}\.wiki\.git/) { raise Gitlab::Shell::Error }

          expect { subject.execute }.not_to raise_error
        end

        it 'rescues exception when Gitlab::Git::Repository::NoRepository is raised' do
          allow_any_instance_of(Repository).to receive(:fetch_geo_mirror).with(/#{project.path_with_namespace}\.wiki\.git/) { raise Gitlab::Git::Repository::NoRepository }

          expect { subject.execute }.not_to raise_error
        end
      end

      context 'tracking database' do
        it 'updates last_wiki_successful_sync_at' do
          subject.execute

          registry.reload

          expect(registry.last_wiki_synced_at).to be_within(1.minute).of(DateTime.now)
          expect(registry.last_wiki_successful_sync_at).to be_within(1.minute).of(DateTime.now)
        end

        it 'does not update last_repository_successful_sync_at' do
          subject.execute

          registry.reload

          expect(registry.last_repository_synced_at).to be_within(1.minute).of(last_repository_synced_at)
          expect(registry.last_repository_successful_sync_at).to be_within(1.minute).of(last_repository_synced_at)
        end

        it 'resets resync_wiki' do
          subject.execute

          registry.reload

          expect(registry.resync_wiki).to be false
        end
      end
    end
  end
end
