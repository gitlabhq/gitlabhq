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
    context 'when repository is empty' do
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
        it 'tracks repository sync' do
          expect { subject.execute }.to change(Geo::ProjectRegistry, :count).by(1)
        end

        it 'stores last_repository_successful_sync_at when succeed' do
          subject.execute

          registry = Geo::ProjectRegistry.find_by(project_id: project.id)

          expect(registry.last_repository_successful_sync_at).not_to be_nil
        end

        it 'reset last_repository_successful_sync_at when fail' do
          allow_any_instance_of(Repository).to receive(:fetch_geo_mirror) { raise Gitlab::Shell::Error }

          subject.execute

          registry = Geo::ProjectRegistry.find_by(project_id: project.id)

          expect(registry.last_repository_successful_sync_at).to be_nil
        end
      end
    end

    context 'when repository exists and is not empty' do
      let(:project) { create(:project) }

      it 'fetches project repositories' do
        fetch_count = 0

        allow_any_instance_of(Repository).to receive(:fetch_geo_mirror) do
          fetch_count += 1
        end

        subject.execute

        expect(fetch_count).to eq 2
      end

      context 'tracking database' do
        it 'tracks repository sync' do
          expect { subject.execute }.to change(Geo::ProjectRegistry, :count).by(1)
        end

        it 'stores last_repository_successful_sync_at when succeed' do
          subject.execute

          registry = Geo::ProjectRegistry.find_by(project_id: project.id)

          expect(registry.last_repository_successful_sync_at).not_to be_nil
        end

        it 'reset last_repository_successful_sync_at when fail' do
          allow_any_instance_of(Repository).to receive(:fetch_geo_mirror) { raise Gitlab::Shell::Error }

          subject.execute

          registry = Geo::ProjectRegistry.find_by(project_id: project.id)

          expect(registry.last_repository_successful_sync_at).to be_nil
        end
      end
    end

    context 'when repository was synced successfully' do
      let(:project) { create(:project) }
      let(:last_repository_synced_at) { 5.days.ago }

      let!(:registry) do
        Geo::ProjectRegistry.create(
          project: project,
          last_repository_synced_at: last_repository_synced_at,
          last_repository_successful_sync_at: last_repository_synced_at
        )
      end

      it 'fetches project repositories' do
        fetch_count = 0

        allow_any_instance_of(Repository).to receive(:fetch_geo_mirror) do
          fetch_count += 1
        end

        subject.execute

        expect(fetch_count).to eq 2
      end

      context 'tracking database' do
        it 'does not create a new registry' do
          expect { subject.execute }.not_to change(Geo::ProjectRegistry, :count)
        end

        it 'updates registry when succeed' do
          subject.execute

          registry.reload

          expect(registry.last_repository_synced_at).to be_within(1.minute).of(Time.now)
          expect(registry.last_repository_successful_sync_at).to be_within(1.minute).of(Time.now)
        end

        it 'does not update registry last_repository_successful_sync_at when fail' do
          allow_any_instance_of(Repository).to receive(:fetch_geo_mirror) { raise Gitlab::Shell::Error }

          subject.execute

          registry.reload

          expect(registry.last_repository_synced_at).to be_within(1.minute).of(Time.now)
          expect(registry.last_repository_successful_sync_at).to be_within(1.minute).of(last_repository_synced_at)
        end
      end
    end

    context 'when last attempt to sync the repository failed' do
      let(:project) { create(:project) }

      let!(:registry) do
        Geo::ProjectRegistry.create(
          project: project,
          last_repository_synced_at: DateTime.now,
          last_repository_successful_sync_at: nil
        )
      end

      it 'fetches project repositories' do
        fetch_count = 0

        allow_any_instance_of(Repository).to receive(:fetch_geo_mirror) do
          fetch_count += 1
        end

        subject.execute

        expect(fetch_count).to eq 2
      end

      context 'tracking database' do
        it 'does not create a new registry' do
          expect { subject.execute }.not_to change(Geo::ProjectRegistry, :count)
        end

        it 'updates last_repository_successful_sync_at' do
          subject.execute

          expect(registry.reload.last_repository_successful_sync_at).not_to be_nil
        end
      end
    end

    context 'when Gitlab::Shell::Error is raised' do
      let(:project) { create(:project_empty_repo) }

      it 'rescues exception' do
        allow(subject).to receive(:fetch_project_repository).and_raise(Gitlab::Shell::Error)

        expect { subject.execute }.not_to raise_error
      end
    end

    context 'when Gitlab::Git::Repository::NoRepository is raised' do
      let(:project) { create(:project_empty_repo) }

      it 'rescues exception and fires after_create hook' do
        allow(subject).to receive(:fetch_project_repository).and_raise(Gitlab::Git::Repository::NoRepository)
        expect_any_instance_of(Repository).to receive(:after_create)

        expect { subject.execute }.not_to raise_error
      end
    end
  end
end
