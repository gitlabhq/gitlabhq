require 'spec_helper'

describe Geo::RepositoryBackfillService, services: true do
  let!(:primary) { create(:geo_node, :primary, host: 'primary-geo-node') }

  subject { described_class.new(project.id) }

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
        allow_any_instance_of(Repository).to receive(:fetch_geo_mirror) { true }

        expect_any_instance_of(Repository).to receive(:expire_all_method_caches).once
        expect_any_instance_of(Repository).to receive(:expire_branch_cache).once
        expect_any_instance_of(Repository).to receive(:expire_content_cache).once

        subject.execute
      end

      it 'releases lease' do
        expect(Gitlab::ExclusiveLease).to receive(:cancel).once.and_call_original

        subject.execute
      end

      context 'tracking database' do
        it 'tracks repository sync' do
          expect { subject.execute }.to change(Geo::ProjectRegistry, :count).by(1)
        end

        it 'stores last_repository_successful_sync_at when succeed' do
          allow_any_instance_of(Repository).to receive(:fetch_geo_mirror) { true }

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

      it 'does not fetch the project repositories' do
        expect_any_instance_of(Repository).not_to receive(:fetch_geo_mirror)

        subject.execute
      end

      context 'tracking database' do
        it 'tracks missing repository sync' do
          expect { subject.execute }.to change(Geo::ProjectRegistry, :count).by(1)
        end
      end
    end

    context 'when repository was backfilled successfully' do
      let(:project) { create(:project) }
      let(:last_repository_successful_sync_at) { 5.days.ago }

      let!(:registry) do
        Geo::ProjectRegistry.create(
          project: project,
          last_repository_synced_at: 5.days.ago,
          last_repository_successful_sync_at: last_repository_successful_sync_at
        )
      end

      it 'does not fetch the project repositories' do
        expect_any_instance_of(Repository).not_to receive(:fetch_geo_mirror)

        subject.execute
      end

      context 'tracking database' do
        it 'does not create a new registry' do
          expect { subject.execute }.not_to change(Geo::ProjectRegistry, :count)
        end

        it 'does not update last_repository_successful_sync_at' do
          subject.execute

          expect(registry.reload.last_repository_successful_sync_at).to be_within(1.second).of(last_repository_successful_sync_at)
        end
      end
    end

    context 'when last attempt to backfill the repository failed' do
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
        before do
          allow_any_instance_of(Repository).to receive(:fetch_geo_mirror) { true }
        end

        it 'does not create a new registry' do
          expect { subject.execute }.not_to change(Geo::ProjectRegistry, :count)
        end

        it 'updates last_repository_successful_sync_at' do
          subject.execute

          expect(registry.reload.last_repository_successful_sync_at).not_to be_nil
        end
      end
    end
  end
end
