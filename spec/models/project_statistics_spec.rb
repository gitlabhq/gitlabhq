require 'rails_helper'

describe ProjectStatistics do
  let(:project) { create :project }
  let(:statistics) { project.statistics }

  describe 'constants' do
    describe 'STORAGE_COLUMNS' do
      it 'is an array of symbols' do
        expect(described_class::STORAGE_COLUMNS).to be_kind_of Array
        expect(described_class::STORAGE_COLUMNS.map(&:class).uniq).to eq [Symbol]
      end
    end

    describe 'STATISTICS_COLUMNS' do
      it 'is an array of symbols' do
        expect(described_class::STATISTICS_COLUMNS).to be_kind_of Array
        expect(described_class::STATISTICS_COLUMNS.map(&:class).uniq).to eq [Symbol]
      end

      it 'includes all storage columns' do
        expect(described_class::STATISTICS_COLUMNS & described_class::STORAGE_COLUMNS).to eq described_class::STORAGE_COLUMNS
      end
    end
  end

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
      allow(statistics).to receive(:update_build_artifacts_size)
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
        expect(statistics).to have_received(:update_build_artifacts_size)
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
        expect(statistics).not_to have_received(:update_build_artifacts_size)
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

  describe '#update_build_artifacts_size' do
    let!(:pipeline) { create(:ci_pipeline, project: project) }

    context 'when new job artifacts are calculated' do
      let(:ci_build) { create(:ci_build, pipeline: pipeline) }

      before do
        create(:ci_job_artifact, :archive, project: pipeline.project, job: ci_build)
      end

      it "stores the size of related build artifacts" do
        statistics.update_build_artifacts_size

        expect(statistics.build_artifacts_size).to be(106365)
      end

      it 'calculates related build artifacts by project' do
        expect(Ci::JobArtifact).to receive(:artifacts_size_for).with(project) { 0 }

        statistics.update_build_artifacts_size
      end
    end

    context 'when legacy artifacts are used' do
      let!(:ci_build) { create(:ci_build, pipeline: pipeline, artifacts_size: 10.megabytes) }

      it "stores the size of related build artifacts" do
        statistics.update_build_artifacts_size

        expect(statistics.build_artifacts_size).to eq(10.megabytes)
      end
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
end
