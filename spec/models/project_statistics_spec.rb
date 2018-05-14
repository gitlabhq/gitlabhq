require 'rails_helper'

describe ProjectStatistics do
  let(:project) { create :project }
  let(:statistics) { project.statistics }

  describe 'associations' do
    it { is_expected.to belong_to(:project) }
    it { is_expected.to belong_to(:namespace) }
  end

  describe 'statistics columns' do
    it "support values up to 8 exabytes" do
      statistics.update!(
        commit_count: 8.exabytes - 1,
        repository_size: 2.exabytes,
        lfs_objects_size: 2.exabytes,
        build_artifacts_size: 4.exabytes - 1
      )

      statistics.reload

      expect(statistics.commit_count).to eq(8.exabytes - 1)
      expect(statistics.repository_size).to eq(2.exabytes)
      expect(statistics.lfs_objects_size).to eq(2.exabytes)
      expect(statistics.build_artifacts_size).to eq(4.exabytes - 1)
      expect(statistics.storage_size).to eq(8.exabytes - 1)
    end
  end

  describe '#total_repository_size' do
    it "sums repository and LFS object size" do
      statistics.repository_size = 2
      statistics.lfs_objects_size = 3
      statistics.build_artifacts_size = 4

      expect(statistics.total_repository_size).to eq 5
    end
  end

  describe '#refresh!' do
    before do
      allow(statistics).to receive(:update_commit_count)
      allow(statistics).to receive(:update_repository_size)
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
        lfs_objects_size: 3
      )

      statistics.reload

      expect(statistics.storage_size).to eq 5
    end
  end

  describe '.increment_statistic' do
    it 'increases the statistic by that amount' do
      expect { described_class.increment_statistic(project.id, :build_artifacts_size, 13) }
        .to change { statistics.reload.build_artifacts_size }
        .by(13)
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
