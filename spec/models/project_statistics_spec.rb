# frozen_string_literal: true

require 'spec_helper'

RSpec.describe ProjectStatistics, feature_category: :source_code_management do
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
        project_ids = stats[0..1].map(&:project_id)
        expected_ids = stats[0..1].map(&:id)

        requested_stats = described_class.for_project_ids(project_ids).pluck(:id)

        expect(requested_stats).to match_array(expected_ids)
      end
    end
  end

  describe 'callbacks' do
    context 'on after_commit' do
      context 'when storage size components are updated' do
        it 'updates the correct storage size for relevant attributes' do
          statistics.update!(repository_size: 10)

          expect(statistics.reload.storage_size).to eq(10)
        end
      end

      context 'when storage size components are not updated' do
        it 'does not affect the storage_size total' do
          statistics.update!(pipeline_artifacts_size: 3, container_registry_size: 50)

          expect(statistics.reload.storage_size).to eq(0)
        end
      end
    end

    describe 'with race conditions' do
      before do
        statistics.update!(storage_size: 14621247)
      end

      it 'handles concurrent updates correctly' do
        # Concurrently update the statistics in two different processes
        t1 = Thread.new do
          stats_1 = ProjectStatistics.find(statistics.id)
          stats_1.snippets_size = 530
          stats_1.save!
        end

        t2 = Thread.new do
          stats_2 = ProjectStatistics.find(statistics.id)
          ProjectStatistics.update_counters(stats_2.id, packages_size: 1000)
          stats_2.refresh_storage_size!
        end

        [t1, t2].each(&:join)

        # Reload the statistics object
        statistics.reload

        # The final storage size should be correctly updated
        expect(statistics.storage_size).to eq(1530) # Final value is correct (snippets_size + packages_size)
      end
    end
  end

  describe 'statistics columns' do
    it "supports bigint values" do
      expect do
        statistics.update!(
          commit_count: 3.gigabytes,
          repository_size: 3.gigabytes,
          wiki_size: 3.gigabytes,
          lfs_objects_size: 3.gigabytes,
          build_artifacts_size: 3.gigabytes,
          snippets_size: 3.gigabytes,
          pipeline_artifacts_size: 3.gigabytes,
          uploads_size: 3.gigabytes,
          container_registry_size: 3.gigabytes
        )
      end.not_to raise_error
    end
  end

  describe 'namespace relatable columns' do
    it 'treats the correct columns as namespace relatable' do
      expect(described_class::NAMESPACE_RELATABLE_COLUMNS).to match_array %i[
        repository_size
        wiki_size
        lfs_objects_size
        uploads_size
        container_registry_size
      ]
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
      statistics.container_registry_size = 8

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
    subject(:refresh_statistics) { statistics.refresh! }

    before do
      allow(statistics).to receive(:update_commit_count)
      allow(statistics).to receive(:update_repository_size)
      allow(statistics).to receive(:update_wiki_size)
      allow(statistics).to receive(:update_lfs_objects_size)
      allow(statistics).to receive(:update_snippets_size)
      allow(statistics).to receive(:update_storage_size)
      allow(statistics).to receive(:update_uploads_size)
      allow(statistics).to receive(:update_container_registry_size)
    end

    context "without arguments" do
      before do
        refresh_statistics
      end

      it "sums all counters" do
        expect(statistics).to have_received(:update_commit_count)
        expect(statistics).to have_received(:update_repository_size)
        expect(statistics).to have_received(:update_wiki_size)
        expect(statistics).to have_received(:update_lfs_objects_size)
        expect(statistics).to have_received(:update_snippets_size)
        expect(statistics).to have_received(:update_uploads_size)
        expect(statistics).to have_received(:update_container_registry_size)
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
        expect(statistics).not_to have_received(:update_container_registry_size)
      end
    end

    context 'without repositories' do
      it 'does not crash' do
        expect(project.repository.exists?).to be_falsey
        expect(project.wiki.repository.exists?).to be_falsey

        refresh_statistics

        expect(statistics).to have_received(:update_commit_count)
        expect(statistics).to have_received(:update_repository_size)
        expect(statistics).to have_received(:update_wiki_size)
        expect(statistics).to have_received(:update_snippets_size)
        expect(statistics).to have_received(:update_uploads_size)
        expect(statistics).to have_received(:update_container_registry_size)
        expect(statistics.repository_size).to eq(0)
        expect(statistics.commit_count).to eq(0)
        expect(statistics.wiki_size).to eq(0)
        expect(statistics.snippets_size).to eq(0)
        expect(statistics.uploads_size).to eq(0)
        expect(statistics.container_registry_size).to eq(0)
      end
    end

    context 'with deleted repositories' do
      let(:project) { create(:project, :repository, :wiki_repo) }

      before do
        project.repository.remove
        project.wiki.repository.remove
      end

      it 'does not crash' do
        refresh_statistics

        expect(statistics).to have_received(:update_commit_count)
        expect(statistics).to have_received(:update_repository_size)
        expect(statistics).to have_received(:update_wiki_size)
        expect(statistics).to have_received(:update_snippets_size)
        expect(statistics).to have_received(:update_uploads_size)
        expect(statistics).to have_received(:update_container_registry_size)
        expect(statistics.repository_size).to eq(0)
        expect(statistics.commit_count).to eq(0)
        expect(statistics.wiki_size).to eq(0)
        expect(statistics.snippets_size).to eq(0)
        expect(statistics.uploads_size).to eq(0)
        expect(statistics.container_registry_size).to eq(0)
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

          refresh_statistics
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
        allow(Gitlab::Database).to receive(:read_only?) { true }

        expect(statistics).not_to receive(:update_commit_count)
        expect(statistics).not_to receive(:update_repository_size)
        expect(statistics).not_to receive(:update_wiki_size)
        expect(statistics).not_to receive(:update_lfs_objects_size)
        expect(statistics).not_to receive(:update_snippets_size)
        expect(statistics).not_to receive(:update_uploads_size)
        expect(statistics).not_to receive(:update_container_registry_size)
        expect(statistics).not_to receive(:save!)
        expect(Namespaces::ScheduleAggregationWorker)
          .not_to receive(:perform_async)

        refresh_statistics
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
      allow(project.repository).to receive(:recent_objects_size).and_return(5)

      statistics.update_repository_size
    end

    it 'stores the size of the repository' do
      expect(statistics.repository_size).to eq 5.megabytes
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
    let!(:lfs_object3) { create(:lfs_object, size: 34.megabytes) }
    let!(:lfs_objects_project1) { create(:lfs_objects_project, project: project, lfs_object: lfs_object1) }
    let!(:lfs_objects_project2) { create(:lfs_objects_project, project: project, lfs_object: lfs_object2) }
    let!(:lfs_objects_project3) { create(:lfs_objects_project, project: project, lfs_object: lfs_object3) }

    before do
      statistics.update_lfs_objects_size
    end

    it "stores the size of related LFS objects" do
      expect(statistics.lfs_objects_size).to eq 91.megabytes
    end
  end

  describe '#update_uploads_size' do
    let!(:upload1) { create(:upload, model: project, size: 1.megabyte) }
    let!(:upload2) { create(:upload, model: project, size: 2.megabytes) }

    it 'stores the size of related uploaded files' do
      expect(statistics.update_uploads_size).to eq(3.megabytes)
    end
  end

  describe '#update_container_registry_size' do
    subject(:update_container_registry_size) { statistics.update_container_registry_size }

    it 'stores the project container registry repositories size' do
      allow(project).to receive(:container_repositories_size).and_return(10)

      update_container_registry_size

      expect(statistics.container_registry_size).to eq(10)
    end

    it 'handles nil values for the repositories size' do
      allow(project).to receive(:container_repositories_size).and_return(nil)

      update_container_registry_size

      expect(statistics.container_registry_size).to eq(0)
    end
  end

  describe '#refresh_storage_size!' do
    subject(:refresh_storage_size) { statistics.refresh_storage_size! }

    it 'recalculates storage size from its components and save it' do
      statistics.update_columns(
        repository_size: 2,
        wiki_size: 4,
        lfs_objects_size: 3,
        snippets_size: 2,
        pipeline_artifacts_size: 3,
        build_artifacts_size: 3,
        packages_size: 6,
        uploads_size: 5,

        storage_size: 0
      )

      expect { refresh_storage_size }.to change { statistics.reload.storage_size }.from(0).to(25)
    end

    context 'when nullable columns are nil' do
      before do
        statistics.update_columns(
          repository_size: 2,
          wiki_size: nil,
          snippets_size: nil,
          storage_size: 0
        )
      end

      it 'does not raise any error' do
        expect { refresh_storage_size }.not_to raise_error
      end

      it 'recalculates storage size from its components' do
        expect { refresh_storage_size }.to change { statistics.reload.storage_size }.from(0).to(2)
      end
    end
  end

  describe '.increment_statistic' do
    shared_examples 'a statistic that increases storage_size synchronously' do
      let(:increment) { Gitlab::Counters::Increment.new(amount: 13) }

      it 'increases the statistic by that amount' do
        expect { described_class.increment_statistic(project, stat, increment) }
          .to change { statistics.reload.send(stat) || 0 }
          .by(increment.amount)
      end

      it 'does not increase the storage size by that amount' do
        expect { described_class.increment_statistic(project, stat, increment) }
          .not_to change { statistics.reload.storage_size }
      end

      it 'schedules a namespace aggregation worker' do
        expect(Namespaces::ScheduleAggregationWorker).to receive(:perform_async)
         .with(statistics.project.namespace.id)

        described_class.increment_statistic(project, stat, increment)
      end

      context 'when the project is pending delete' do
        before do
          project.update_attribute(:pending_delete, true)
        end

        it 'does not change the statistics' do
          expect { described_class.increment_statistic(project, stat, increment) }
            .not_to change { statistics.reload.send(stat) }
        end
      end
    end

    shared_examples 'a statistic that increases storage_size asynchronously' do
      let(:increment) { Gitlab::Counters::Increment.new(amount: 13) }

      it 'stores the increment temporarily in Redis', :clean_gitlab_redis_shared_state do
        described_class.increment_statistic(project, stat, increment)

        Gitlab::Redis::SharedState.with do |redis|
          key = statistics.counter(stat).key
          value = redis.get(key)
          expect(value.to_i).to eq(increment.amount)
        end
      end

      it 'schedules a worker to update the statistic and storage_size async', :sidekiq_inline do
        expect(FlushCounterIncrementsWorker)
          .to receive(:perform_in)
          .with(Gitlab::Counters::BufferedCounter::WORKER_DELAY, described_class.name, statistics.id, stat.to_s)
          .and_call_original

        expect { described_class.increment_statistic(project, stat, increment) }
          .to change { statistics.reload.send(stat) }.by(increment.amount)
          .and change { statistics.reload.send(:storage_size) }.by(increment.amount)
      end

      context 'when the project is pending delete' do
        before do
          project.update_attribute(:pending_delete, true)
        end

        it 'does not change the statistics' do
          expect { described_class.increment_statistic(project, stat, increment) }
            .not_to change { [statistics.reload.send(stat), statistics.reload.send(:storage_size)] }
        end
      end
    end

    context 'when adjusting :build_artifacts_size' do
      let(:stat) { :build_artifacts_size }

      it_behaves_like 'a statistic that increases storage_size asynchronously'
    end

    context 'when adjusting :pipeline_artifacts_size' do
      let(:stat) { :pipeline_artifacts_size }

      it_behaves_like 'a statistic that increases storage_size synchronously'
    end

    context 'when adjusting :packages_size' do
      let(:stat) { :packages_size }

      it_behaves_like 'a statistic that increases storage_size asynchronously'
    end

    context 'when the amount is 0' do
      let(:increment) { Gitlab::Counters::Increment.new(amount: 0) }

      it 'does not execute a query' do
        project
        expect { described_class.increment_statistic(project, :build_artifacts_size, increment) }
          .not_to exceed_query_limit(0)
      end
    end

    context 'when using an invalid column' do
      it 'raises an error' do
        expect { described_class.increment_statistic(project, :id, 13) }
          .to raise_error(ArgumentError, "Cannot increment attribute: id")
      end
    end
  end

  describe '.bulk_increment_statistic' do
    let(:increments) { [10, 3].map { |amount| Gitlab::Counters::Increment.new(amount: amount) } }
    let(:total_amount) { increments.sum(&:amount) }

    shared_examples 'a statistic that increases storage_size synchronously' do
      it 'increases the statistic by that amount' do
        expect { described_class.bulk_increment_statistic(project, stat, increments) }
          .to change { statistics.reload.send(stat) || 0 }
                .by(total_amount)
      end

      it 'does not increase the storage size by that amount' do
        expect { described_class.bulk_increment_statistic(project, stat, increments) }
          .not_to change { statistics.reload.storage_size }
      end

      it 'schedules a namespace aggregation worker' do
        expect(Namespaces::ScheduleAggregationWorker).to receive(:perform_async)
                                                           .with(statistics.project.namespace.id)

        described_class.bulk_increment_statistic(project, stat, increments)
      end

      context 'when the project is pending delete' do
        before do
          project.update_attribute(:pending_delete, true)
        end

        it 'does not change the statistics' do
          expect { described_class.bulk_increment_statistic(project, stat, increments) }
            .not_to change { statistics.reload.send(stat) }
        end
      end
    end

    shared_examples 'a statistic that increases storage_size asynchronously' do
      it 'stores the increment temporarily in Redis', :clean_gitlab_redis_shared_state do
        described_class.bulk_increment_statistic(project, stat, increments)

        Gitlab::Redis::SharedState.with do |redis|
          key = statistics.counter(stat).key
          increment = redis.get(key)
          expect(increment.to_i).to eq(total_amount)
        end
      end

      it 'schedules a worker to update the statistic and storage_size async', :sidekiq_inline do
        expect(FlushCounterIncrementsWorker)
          .to receive(:perform_in)
                .with(Gitlab::Counters::BufferedCounter::WORKER_DELAY, described_class.name, statistics.id, stat.to_s)
                .and_call_original

        expect { described_class.bulk_increment_statistic(project, stat, increments) }
          .to change { statistics.reload.send(stat) }.by(total_amount)
          .and change { statistics.reload.send(:storage_size) }.by(total_amount)
      end

      context 'when the project is pending delete' do
        before do
          project.update_attribute(:pending_delete, true)
        end

        it 'does not change the statistics' do
          expect { described_class.bulk_increment_statistic(project, stat, increments) }
            .not_to change { [statistics.reload.send(stat), statistics.reload.send(:storage_size)] }
        end
      end
    end

    context 'when adjusting :build_artifacts_size' do
      let(:stat) { :build_artifacts_size }

      it_behaves_like 'a statistic that increases storage_size asynchronously'
    end

    context 'when adjusting :pipeline_artifacts_size' do
      let(:stat) { :pipeline_artifacts_size }

      it_behaves_like 'a statistic that increases storage_size synchronously'
    end

    context 'when adjusting :packages_size' do
      let(:stat) { :packages_size }

      it_behaves_like 'a statistic that increases storage_size asynchronously'
    end

    context 'when using an invalid column' do
      it 'raises an error' do
        expect { described_class.bulk_increment_statistic(project, :id, increments) }
          .to raise_error(ArgumentError, "Cannot increment attribute: id")
      end
    end
  end

  describe '#export_size' do
    it 'does not include artifacts & packages size' do
      statistics.update!(
        repository_size: 3.gigabytes,
        wiki_size: 3.gigabytes,
        lfs_objects_size: 3.gigabytes,
        build_artifacts_size: 3.gigabytes,
        packages_size: 3.gigabytes,
        snippets_size: 3.gigabytes,
        uploads_size: 3.gigabytes
      )

      statistics.refresh_storage_size!

      expect(statistics.reload.export_size).to eq(15.gigabytes)
    end
  end
end
