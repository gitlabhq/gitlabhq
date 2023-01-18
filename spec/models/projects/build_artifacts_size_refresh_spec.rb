# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Projects::BuildArtifactsSizeRefresh, type: :model do
  describe 'associations' do
    it { is_expected.to belong_to(:project) }
  end

  it_behaves_like 'having unique enum values'

  describe 'validations' do
    it { is_expected.to validate_presence_of(:project) }
  end

  describe 'scopes' do
    let_it_be(:refresh_1) { create(:project_build_artifacts_size_refresh, :stale) }
    let_it_be(:refresh_2) { create(:project_build_artifacts_size_refresh, :running, updated_at: 1.hour.ago) }
    let_it_be(:refresh_3) { create(:project_build_artifacts_size_refresh, :pending) }
    let_it_be(:refresh_4) { create(:project_build_artifacts_size_refresh, :created) }
    let_it_be(:refresh_5) { create(:project_build_artifacts_size_refresh, :finalizing) }

    describe 'stale' do
      it 'returns records in running state and has not been updated for more than 2 hours' do
        expect(described_class.stale).to eq([refresh_1])
      end
    end

    describe 'remaining' do
      it 'returns stale, created and pending records' do
        expect(described_class.remaining).to match_array([refresh_1, refresh_3, refresh_4])
      end

      it 'does not include finalizing' do
        expect(described_class.processing_queue).not_to include(refresh_5)
      end
    end

    describe 'processing_queue' do
      it 'prioritizes pending -> stale -> created' do
        expect(described_class.processing_queue).to eq([refresh_3, refresh_1, refresh_4])
      end

      it 'does not include finalizing' do
        expect(described_class.processing_queue).not_to include(refresh_5)
      end
    end
  end

  describe 'state machine', :clean_gitlab_redis_shared_state do
    around do |example|
      freeze_time { example.run }
    end

    let(:now) { Time.zone.now }

    describe 'initial state' do
      let(:refresh) { create(:project_build_artifacts_size_refresh) }

      it 'defaults to created' do
        expect(refresh).to be_created
      end
    end

    describe '#process!' do
      context 'when refresh state is created' do
        let_it_be_with_reload(:refresh) do
          create(
            :project_build_artifacts_size_refresh,
            :created
          )
        end

        let!(:last_job_artifact_id_on_refresh_start) { create(:ci_job_artifact, project: refresh.project) }

        let(:statistics) { refresh.project.statistics }

        before do
          statistics.update!(build_artifacts_size: 120)
          statistics.increment_counter(:build_artifacts_size, Gitlab::Counters::Increment.new(amount: 30))
        end

        it 'transitions the state to running' do
          expect { refresh.process! }.to change { refresh.state }.to(described_class::STATES[:running])
        end

        it 'sets the refresh_started_at' do
          expect { refresh.process! }.to change { refresh.refresh_started_at.to_i }.to(now.to_i)
        end

        it 'sets last_job_artifact_id_on_refresh_start' do
          expect { refresh.process! }.to change { refresh.last_job_artifact_id_on_refresh_start.to_i }.to(last_job_artifact_id_on_refresh_start.id)
        end

        it 'bumps the updated_at' do
          expect { refresh.process! }.to change { refresh.updated_at.to_i }.to(now.to_i)
        end

        it 'resets the build artifacts size stats' do
          expect { refresh.process! }.to change { statistics.reload.build_artifacts_size }.from(120).to(0)
        end

        it 'resets the buffered counter value to zero' do
          expect { refresh.process! }.to change { Gitlab::Counters::BufferedCounter.new(statistics, :build_artifacts_size).get }.to(0)
        end
      end

      context 'when refresh state is pending' do
        let!(:refresh) do
          create(
            :project_build_artifacts_size_refresh,
            :pending,
            updated_at: 2.days.ago
          )
        end

        before do
          create(:project_statistics, project: refresh.project)
        end

        it 'transitions the state to running' do
          expect { refresh.process! }.to change { refresh.reload.state }.to(described_class::STATES[:running])
        end

        it 'bumps the updated_at' do
          expect { refresh.process! }.to change { refresh.reload.updated_at.to_i }.to(now.to_i)
        end
      end

      context 'when refresh state is running' do
        let!(:refresh) do
          create(
            :project_build_artifacts_size_refresh,
            :running,
            updated_at: 2.days.ago
          )
        end

        before do
          create(:project_statistics, project: refresh.project)
        end

        it 'keeps the state at running' do
          expect { refresh.process! }.not_to change { refresh.reload.state }
        end

        it 'bumps the updated_at' do
          # If this was a stale job, we want to bump the updated at now so that
          # it won't be picked up by another worker while we're recalculating
          expect { refresh.process! }.to change { refresh.reload.updated_at.to_i }.to(now.to_i)
        end
      end
    end

    describe '#requeue!' do
      let!(:refresh) do
        create(
          :project_build_artifacts_size_refresh,
          :running,
          updated_at: 2.days.ago,
          last_job_artifact_id: 111
        )
      end

      let(:last_job_artifact_id) { 123 }

      it 'transitions refresh state from running to pending' do
        expect { refresh.requeue!(last_job_artifact_id) }.to change { refresh.reload.state }.to(described_class::STATES[:pending])
      end

      it 'bumps updated_at' do
        expect { refresh.requeue!(last_job_artifact_id) }.to change { refresh.reload.updated_at.to_i }.to(now.to_i)
      end

      it 'updates last_job_artifact_id' do
        expect { refresh.requeue!(last_job_artifact_id) }.to change { refresh.reload.last_job_artifact_id.to_i }.to(last_job_artifact_id)
      end
    end

    describe '#schedule_finalize!' do
      let!(:refresh) { create(:project_build_artifacts_size_refresh, :running) }

      it 'transitions refresh state from running to finalizing' do
        expect { refresh.schedule_finalize! }.to change { refresh.reload.state }.to(described_class::STATES[:finalizing])
      end

      it 'schedules Projects::FinalizeProjectStatisticsRefreshWorker' do
        expect(Projects::FinalizeProjectStatisticsRefreshWorker)
          .to receive(:perform_in)
          .with(described_class::FINALIZE_DELAY, refresh.class.to_s, refresh.id)

        refresh.schedule_finalize!
      end
    end
  end

  describe '.process_next_refresh!' do
    let!(:refresh_created) { create(:project_build_artifacts_size_refresh, :created) }
    let!(:refresh_pending) { create(:project_build_artifacts_size_refresh, :pending) }

    subject(:processed_refresh) { described_class.process_next_refresh! }

    it 'picks the first record from the remaining work' do
      expect(processed_refresh).to eq(refresh_pending)
      expect(processed_refresh.reload).to be_running
    end
  end

  describe '.enqueue_refresh' do
    let_it_be(:project_1) { create(:project) }
    let_it_be(:project_2) { create(:project) }

    let(:projects) { [project_1, project_1, project_2] }

    it 'creates refresh records for each given project, skipping duplicates' do
      expect { described_class.enqueue_refresh(projects) }
        .to change { described_class.count }.from(0).to(2)

      expect(described_class.first).to have_attributes(
        project_id: project_1.id,
        last_job_artifact_id: nil,
        refresh_started_at: nil,
        state: described_class::STATES[:created]
      )

      expect(described_class.last).to have_attributes(
        project_id: project_2.id,
        last_job_artifact_id: nil,
        refresh_started_at: nil,
        state: described_class::STATES[:created]
      )
    end
  end

  describe '#finalize!' do
    let!(:refresh) { create(:project_build_artifacts_size_refresh, :finalizing) }

    let(:statistics) { refresh.project.statistics }

    before do
      allow(statistics).to receive(:finalize_refresh)
    end

    it 'stores the refresh amount into the buffered counter' do
      expect(statistics).to receive(:finalize_refresh).with(described_class::COUNTER_ATTRIBUTE_NAME)

      refresh.finalize!
    end

    it 'destroys the refresh record' do
      expect { refresh.finalize! }.to change { described_class.count }.by(-1)
    end
  end

  describe '#next_batch' do
    let!(:project) { create(:project) }
    let!(:artifact_1) { create(:ci_job_artifact, project: project, created_at: 14.days.ago) }
    let!(:artifact_2) { create(:ci_job_artifact, project: project, created_at: 13.days.ago) }
    let!(:artifact_3) { create(:ci_job_artifact, project: project, created_at: 12.days.ago) }

    # This should not be included in the recalculation as it is created later than the refresh start time
    let!(:future_artifact) { create(:ci_job_artifact, project: project, size: 8, created_at: refresh.refresh_started_at + 1.second) }

    let!(:refresh) do
      create(
        :project_build_artifacts_size_refresh,
        :pending,
        project: project,
        updated_at: 2.days.ago,
        refresh_started_at: 10.days.ago,
        last_job_artifact_id: artifact_1.id,
        last_job_artifact_id_on_refresh_start: artifact_3.id
      )
    end

    subject(:batch) { refresh.next_batch(limit: 3) }

    it 'returns the job artifact records that were created not later than the refresh_started_at and IDs greater than the last_job_artifact_id' do
      expect(batch).to eq([artifact_2, artifact_3])
    end

    context 'when created_at is set before artifact id is persisted' do
      it 'returns ordered job artifacts' do
        artifact_3.update!(created_at: artifact_2.created_at)

        expect(batch).to eq([artifact_2, artifact_3])
      end
    end
  end

  describe '#started?' do
    using RSpec::Parameterized::TableSyntax

    let_it_be(:project) { create(:project) }

    subject { refresh.started? }

    where(:refresh_state, :result) do
      :created | false
      :pending | true
      :running | true
    end

    with_them do
      let(:refresh) do
        create(:project_build_artifacts_size_refresh, refresh_state, project: project)
      end

      it { is_expected.to eq(result) }
    end
  end

  describe 'callbacks' do
    context 'when destroyed' do
      it 'enqueues a Namespaces::ScheduleAggregationWorker' do
        refresh = create(:project_build_artifacts_size_refresh)

        expect(Namespaces::ScheduleAggregationWorker).to receive(:perform_async).with(refresh.project.namespace_id)

        refresh.destroy!
      end
    end
  end
end
