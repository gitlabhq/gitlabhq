# frozen_string_literal: true

require 'rails_helper'

describe ProjectStatistics do
  let(:project) { create :project }
  let(:statistics) { project.statistics }

  describe 'associations' do
    it { is_expected.to belong_to(:project) }
    it { is_expected.to belong_to(:namespace) }
  end

  describe 'scopes' do
    describe '.for_project_ids' do
      it 'returns only requested projects' do
        stats = create_list(:project_statistics, 3)
        project_ids = stats[0..1].map { |s| s.project_id }
        expected_ids = stats[0..1].map { |s| s.id }

        requested_stats = described_class.for_project_ids(project_ids).pluck(:id)

        expect(requested_stats).to eq(expected_ids)
      end
    end
  end

  describe 'statistics columns' do
    it "support values up to 8 exabytes" do
      statistics.update!(
        commit_count: 8.exabytes - 1,
        repository_size: 2.exabytes,
        wiki_size: 1.exabytes,
        lfs_objects_size: 2.exabytes,
        build_artifacts_size: 3.exabytes - 1
      )

      statistics.reload

      expect(statistics.commit_count).to eq(8.exabytes - 1)
      expect(statistics.repository_size).to eq(2.exabytes)
      expect(statistics.wiki_size).to eq(1.exabytes)
      expect(statistics.lfs_objects_size).to eq(2.exabytes)
      expect(statistics.build_artifacts_size).to eq(3.exabytes - 1)
      expect(statistics.storage_size).to eq(8.exabytes - 1)
    end
  end

  describe '#total_repository_size' do
    it "sums repository and LFS object size" do
      statistics.repository_size = 2
      statistics.wiki_size = 6
      statistics.lfs_objects_size = 3
      statistics.build_artifacts_size = 4

      expect(statistics.total_repository_size).to eq 5
    end
  end

  describe '#wiki_size' do
    it "is initialized with not null value" do
      expect(statistics.wiki_size).to eq 0
    end
  end

  describe '#refresh!' do
    before do
      allow(statistics).to receive(:update_commit_count)
      allow(statistics).to receive(:update_repository_size)
      allow(statistics).to receive(:update_wiki_size)
      allow(statistics).to receive(:update_lfs_objects_size)
      allow(statistics).to receive(:update_storage_size)
    end

    context "without arguments" do
      before do
        statistics.refresh!
      end

      it "sums all counters" do
        expect(statistics).to have_received(:update_commit_count)
        expect(statistics).to have_received(:update_repository_size)
        expect(statistics).to have_received(:update_wiki_size)
        expect(statistics).to have_received(:update_lfs_objects_size)
      end
    end

    context "when passing an only: argument" do
      before do
        statistics.refresh! only: [:lfs_objects_size]
      end

      it "only updates the given columns" do
        expect(statistics).to have_received(:update_lfs_objects_size)
        expect(statistics).not_to have_received(:update_commit_count)
        expect(statistics).not_to have_received(:update_repository_size)
        expect(statistics).not_to have_received(:update_wiki_size)
      end
    end

    context 'without repositories' do
      it 'does not crash' do
        expect(project.repository.exists?).to be_falsey
        expect(project.wiki.repository.exists?).to be_falsey

        statistics.refresh!

        expect(statistics).to have_received(:update_commit_count)
        expect(statistics).to have_received(:update_repository_size)
        expect(statistics).to have_received(:update_wiki_size)
        expect(statistics.repository_size).to eq(0)
        expect(statistics.commit_count).to eq(0)
        expect(statistics.wiki_size).to eq(0)
      end
    end

    context 'with deleted repositories' do
      let(:project) { create(:project, :repository, :wiki_repo) }

      before do
        Gitlab::GitalyClient::StorageSettings.allow_disk_access do
          FileUtils.rm_rf(project.repository.path)
          FileUtils.rm_rf(project.wiki.repository.path)
        end
      end

      it 'does not crash' do
        statistics.refresh!

        expect(statistics).to have_received(:update_commit_count)
        expect(statistics).to have_received(:update_repository_size)
        expect(statistics).to have_received(:update_wiki_size)
        expect(statistics.repository_size).to eq(0)
        expect(statistics.commit_count).to eq(0)
        expect(statistics.wiki_size).to eq(0)
      end
    end
  end

  describe '#update_commit_count' do
    before do
      allow(project.repository).to receive(:commit_count).and_return(23)
      statistics.update_commit_count
    end

    it "stores the number of commits in the repository" do
      expect(statistics.commit_count).to eq 23
    end
  end

  describe '#update_repository_size' do
    before do
      allow(project.repository).to receive(:size).and_return(12)
      statistics.update_repository_size
    end

    it "stores the size of the repository" do
      expect(statistics.repository_size).to eq 12.megabytes
    end
  end

  describe '#update_wiki_size' do
    before do
      allow(project.wiki.repository).to receive(:size).and_return(34)
      statistics.update_wiki_size
    end

    it "stores the size of the wiki" do
      expect(statistics.wiki_size).to eq 34.megabytes
    end
  end

  describe '#update_lfs_objects_size' do
    let!(:lfs_object1) { create(:lfs_object, size: 23.megabytes) }
    let!(:lfs_object2) { create(:lfs_object, size: 34.megabytes) }
    let!(:lfs_objects_project1) { create(:lfs_objects_project, project: project, lfs_object: lfs_object1) }
    let!(:lfs_objects_project2) { create(:lfs_objects_project, project: project, lfs_object: lfs_object2) }

    before do
      statistics.update_lfs_objects_size
    end

    it "stores the size of related LFS objects" do
      expect(statistics.lfs_objects_size).to eq 57.megabytes
    end
  end

  describe '#update_storage_size' do
    it "sums all storage counters" do
      statistics.update!(
        repository_size: 2,
        wiki_size: 4,
        lfs_objects_size: 3
      )

      statistics.reload

      expect(statistics.storage_size).to eq 9
    end

    it 'works during wiki_size backfill' do
      statistics.update!(
        repository_size: 2,
        wiki_size: nil,
        lfs_objects_size: 3
      )

      statistics.reload

      expect(statistics.storage_size).to eq 5
    end
  end

  describe '.increment_statistic' do
    shared_examples 'a statistic that increases storage_size' do
      it 'increases the statistic by that amount' do
        expect { described_class.increment_statistic(project.id, stat, 13) }
          .to change { statistics.reload.send(stat) || 0 }
          .by(13)
      end

      it 'increases also storage size by that amount' do
        expect { described_class.increment_statistic(project.id, stat, 20) }
         .to change { statistics.reload.storage_size }
         .by(20)
      end
    end

    context 'when adjusting :build_artifacts_size' do
      let(:stat) { :build_artifacts_size }

      it_behaves_like 'a statistic that increases storage_size'
    end

    context 'when adjusting :packages_size' do
      let(:stat) { :packages_size }

      it_behaves_like 'a statistic that increases storage_size'
    end

    context 'when the amount is 0' do
      it 'does not execute a query' do
        project
        expect { described_class.increment_statistic(project.id, :build_artifacts_size, 0) }
          .not_to exceed_query_limit(0)
      end
    end

    context 'when using an invalid column' do
      it 'raises an error' do
        expect { described_class.increment_statistic(project.id, :id, 13) }
          .to raise_error(ArgumentError, "Cannot increment attribute: id")
      end
    end
  end
end
