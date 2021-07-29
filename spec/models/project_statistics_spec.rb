# frozen_string_literal: true

require 'spec_helper'

RSpec.describe ProjectStatistics do
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
        build_artifacts_size: 1.exabyte,
        snippets_size: 1.exabyte,
        pipeline_artifacts_size: 512.petabytes - 1,
        uploads_size: 512.petabytes
      )

      statistics.reload

      expect(statistics.commit_count).to eq(8.exabytes - 1)
      expect(statistics.repository_size).to eq(2.exabytes)
      expect(statistics.wiki_size).to eq(1.exabytes)
      expect(statistics.lfs_objects_size).to eq(2.exabytes)
      expect(statistics.build_artifacts_size).to eq(1.exabyte)
      expect(statistics.storage_size).to eq(8.exabytes - 1)
      expect(statistics.snippets_size).to eq(1.exabyte)
      expect(statistics.pipeline_artifacts_size).to eq(512.petabytes - 1)
      expect(statistics.uploads_size).to eq(512.petabytes)
    end
  end

  describe '#total_repository_size' do
    it "sums repository and LFS object size" do
      statistics.repository_size = 2
      statistics.wiki_size = 6
      statistics.lfs_objects_size = 3
      statistics.build_artifacts_size = 4
      statistics.snippets_size = 5
      statistics.uploads_size = 3

      expect(statistics.total_repository_size).to eq 5
    end
  end

  describe '#wiki_size' do
    it 'is initialized with not null value' do
      expect(statistics.attributes['wiki_size']).to be_zero
      expect(statistics.wiki_size).to be_zero
    end

    it 'coerces any nil value to 0' do
      statistics.update!(wiki_size: nil)

      expect(statistics.attributes['wiki_size']).to be_nil
      expect(statistics.wiki_size).to eq 0
    end
  end

  describe '#snippets_size' do
    it 'is initialized with not null value' do
      expect(statistics.attributes['snippets_size']).to be_zero
      expect(statistics.snippets_size).to be_zero
    end

    it 'coerces any nil value to 0' do
      statistics.update!(snippets_size: nil)

      expect(statistics.attributes['snippets_size']).to be_nil
      expect(statistics.snippets_size).to eq 0
    end
  end

  describe '#refresh!' do
    before do
      allow(statistics).to receive(:update_commit_count)
      allow(statistics).to receive(:update_repository_size)
      allow(statistics).to receive(:update_wiki_size)
      allow(statistics).to receive(:update_lfs_objects_size)
      allow(statistics).to receive(:update_snippets_size)
      allow(statistics).to receive(:update_storage_size)
      allow(statistics).to receive(:update_uploads_size)
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
        expect(statistics).to have_received(:update_snippets_size)
        expect(statistics).to have_received(:update_uploads_size)
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
        expect(statistics).not_to have_received(:update_snippets_size)
        expect(statistics).not_to have_received(:update_uploads_size)
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
        expect(statistics).to have_received(:update_snippets_size)
        expect(statistics).to have_received(:update_uploads_size)
        expect(statistics.repository_size).to eq(0)
        expect(statistics.commit_count).to eq(0)
        expect(statistics.wiki_size).to eq(0)
        expect(statistics.snippets_size).to eq(0)
        expect(statistics.uploads_size).to eq(0)
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
        expect(statistics).to have_received(:update_snippets_size)
        expect(statistics).to have_received(:update_uploads_size)
        expect(statistics.repository_size).to eq(0)
        expect(statistics.commit_count).to eq(0)
        expect(statistics.wiki_size).to eq(0)
        expect(statistics.snippets_size).to eq(0)
        expect(statistics.uploads_size).to eq(0)
      end
    end

    context 'when the column is namespace relatable' do
      let(:namespace) { create(:group) }
      let(:project) { create(:project, namespace: namespace) }

      context 'when arguments are passed' do
        it 'schedules the aggregation worker' do
          expect(Namespaces::ScheduleAggregationWorker)
            .to receive(:perform_async)

          statistics.refresh!(only: [:lfs_objects_size])
        end
      end

      context 'when no argument is passed' do
        it 'schedules the aggregation worker' do
          expect(Namespaces::ScheduleAggregationWorker)
            .to receive(:perform_async)

          statistics.refresh!
        end
      end
    end

    context 'when the column is not namespace relatable' do
      it 'does not schedules an aggregation worker' do
        expect(Namespaces::ScheduleAggregationWorker)
          .not_to receive(:perform_async)

        statistics.refresh!(only: [:commit_count])
      end
    end

    context 'when the database is read-only' do
      it 'does nothing' do
        allow(Gitlab::Database.main).to receive(:read_only?) { true }

        expect(statistics).not_to receive(:update_commit_count)
        expect(statistics).not_to receive(:update_repository_size)
        expect(statistics).not_to receive(:update_wiki_size)
        expect(statistics).not_to receive(:update_lfs_objects_size)
        expect(statistics).not_to receive(:update_snippets_size)
        expect(statistics).not_to receive(:update_uploads_size)
        expect(statistics).not_to receive(:save!)
        expect(Namespaces::ScheduleAggregationWorker)
          .not_to receive(:perform_async)

        statistics.refresh!
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

  describe '#update_snippets_size' do
    before do
      create_list(:project_snippet, 2, project: project)
      SnippetStatistics.update_all(repository_size: 10)
    end

    it 'stores the size of snippets' do
      # Snippet not associated with the project
      snippet = create(:project_snippet)
      snippet.statistics.update!(repository_size: 40)

      statistics.update_snippets_size

      expect(statistics.update_snippets_size).to eq 20
    end

    context 'when not all snippets has statistics' do
      it 'stores the size of snippets with statistics' do
        SnippetStatistics.last.delete

        statistics.update_snippets_size

        expect(statistics.update_snippets_size).to eq 10
      end
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

  describe '#update_uploads_size' do
    let!(:upload1) { create(:upload, model: project, size: 1.megabyte) }
    let!(:upload2) { create(:upload, model: project, size: 2.megabytes) }

    it 'stores the size of related uploaded files' do
      expect(statistics.update_uploads_size).to eq(3.megabytes)
    end
  end

  describe '#update_storage_size' do
    it "sums all storage counters" do
      statistics.update!(
        repository_size: 2,
        wiki_size: 4,
        lfs_objects_size: 3,
        snippets_size: 2,
        pipeline_artifacts_size: 3,
        uploads_size: 5
      )

      statistics.reload

      expect(statistics.storage_size).to eq 19
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

    context 'when nullable columns are nil' do
      it 'does not raise any error' do
        expect do
          statistics.update!(
            repository_size: 2,
            wiki_size: nil,
            lfs_objects_size: 3,
            snippets_size: nil
          )
        end.not_to raise_error

        expect(statistics.storage_size).to eq 5
      end
    end
  end

  describe '.increment_statistic' do
    shared_examples 'a statistic that increases storage_size' do
      it 'increases the statistic by that amount' do
        expect { described_class.increment_statistic(project, stat, 13) }
          .to change { statistics.reload.send(stat) || 0 }
          .by(13)
      end

      it 'increases also storage size by that amount' do
        expect { described_class.increment_statistic(project, stat, 20) }
          .to change { statistics.reload.storage_size }
          .by(20)
      end
    end

    shared_examples 'a statistic that increases storage_size asynchronously' do
      it 'stores the increment temporarily in Redis', :clean_gitlab_redis_shared_state do
        described_class.increment_statistic(project, stat, 13)

        Gitlab::Redis::SharedState.with do |redis|
          increment = redis.get(statistics.counter_key(stat))
          expect(increment.to_i).to eq(13)
        end
      end

      it 'schedules a worker to update the statistic and storage_size async' do
        expect(FlushCounterIncrementsWorker)
          .to receive(:perform_in)
          .with(CounterAttribute::WORKER_DELAY, described_class.name, statistics.id, stat)

        expect(FlushCounterIncrementsWorker)
          .to receive(:perform_in)
          .with(CounterAttribute::WORKER_DELAY, described_class.name, statistics.id, :storage_size)

        described_class.increment_statistic(project, stat, 20)
      end
    end

    context 'when adjusting :build_artifacts_size' do
      let(:stat) { :build_artifacts_size }

      it_behaves_like 'a statistic that increases storage_size asynchronously'

      it_behaves_like 'a statistic that increases storage_size' do
        before do
          stub_feature_flags(efficient_counter_attribute: false)
        end
      end
    end

    context 'when adjusting :pipeline_artifacts_size' do
      let(:stat) { :pipeline_artifacts_size }

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
