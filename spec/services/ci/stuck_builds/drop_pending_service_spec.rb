# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Ci::StuckBuilds::DropPendingService, feature_category: :continuous_integration do
  let_it_be(:runner) { create(:ci_runner) }
  let_it_be(:pipeline) { create(:ci_empty_pipeline) }
  let_it_be_with_reload(:job) { create(:ci_build, pipeline: pipeline) }

  let(:created_at) {}
  let(:updated_at) {}

  subject(:service) { described_class.new }

  before do
    job_attributes = { status: status }
    job_attributes[:created_at] = created_at if created_at
    job_attributes[:updated_at] = updated_at if updated_at
    job_attributes.compact!

    job.update!(job_attributes)

    Ci::Build.pending.each do |job|
      job.create_queuing_entry!
      job.reload.queuing_entry.update!(created_at: job.created_at)
    end
  end

  shared_examples 'when job is pending' do
    let(:status) { 'pending' }

    context 'when job is not stuck' do
      before do
        allow_next_found_instance_of(Ci::Build) do |build|
          allow(build).to receive(:stuck?).and_return(false)
        end
      end

      context 'when job was updated_at more than 1 day ago' do
        let(:updated_at) { 1.5.days.ago }

        context 'when created_at is the same as updated_at' do
          let(:created_at) { 1.5.days.ago }

          it_behaves_like 'job is dropped with failure reason', 'stuck_or_timeout_failure'
          it_behaves_like 'when invalid dooms the job bypassing validations'
        end

        context 'when created_at is before updated_at' do
          let(:created_at) { 3.days.ago }

          it_behaves_like 'job is dropped with failure reason', 'stuck_or_timeout_failure'
          it_behaves_like 'when invalid dooms the job bypassing validations'
        end
      end

      context 'when job was updated less than 1 day ago' do
        let(:updated_at) { 6.hours.ago }

        context 'when created_at is the same as updated_at' do
          let(:created_at) { 1.5.days.ago }

          it_behaves_like 'job is unchanged'
        end

        context 'when created_at is before updated_at' do
          let(:created_at) { 3.days.ago }

          it_behaves_like 'job is unchanged'
        end
      end

      context 'when job was updated more than 1 hour ago' do
        let(:updated_at) { 2.hours.ago }

        context 'when created_at is the same as updated_at' do
          let(:created_at) { 2.hours.ago }

          it_behaves_like 'job is unchanged'
        end

        context 'when created_at is before updated_at' do
          let(:created_at) { 3.days.ago }

          it_behaves_like 'job is unchanged'
        end
      end
    end

    context 'when job is stuck' do
      before do
        allow_next_found_instance_of(Ci::Build) do |build|
          allow(build).to receive(:stuck?).and_return(true)
        end
      end

      context 'when job was updated_at more than 1 hour ago' do
        let(:updated_at) { 1.5.hours.ago }

        context 'when created_at is the same as updated_at' do
          let(:created_at) { 1.5.hours.ago }

          it_behaves_like 'job is dropped with failure reason', 'stuck_or_timeout_failure'
          it_behaves_like 'when invalid dooms the job bypassing validations'
        end

        context 'when created_at is before updated_at' do
          let(:created_at) { 3.days.ago }

          it_behaves_like 'job is dropped with failure reason', 'stuck_or_timeout_failure'
          it_behaves_like 'when invalid dooms the job bypassing validations'
        end
      end

      context 'when job was updated in less than 1 hour ago' do
        let(:updated_at) { 30.minutes.ago }

        context 'when created_at is the same as updated_at' do
          let(:created_at) { 30.minutes.ago }

          it_behaves_like 'job is unchanged'
        end

        context 'when created_at is before updated_at' do
          let(:created_at) { 2.days.ago }

          it_behaves_like 'job is unchanged'
        end
      end
    end
  end

  it_behaves_like 'when job is pending'

  context 'when FF `drop_stuck_builds_from_ci_pending_builds_queue` is disabled' do
    before do
      stub_feature_flags(drop_stuck_builds_from_ci_pending_builds_queue: false)
    end

    it_behaves_like 'when job is pending'
  end

  # Move this context into 'when job is pending' when FF `drop_stuck_builds_from_ci_pending_builds_queue` is removed
  context 'when a non-stuck job appears before a stuck job' do
    # `job` (non-stuck) has oldest created_at, so it appears first
    let(:status) { 'pending' }
    let(:created_at) { 5.hours.ago }
    let(:updated_at) { 5.hours.ago }

    let_it_be_with_reload(:stuck_job) do
      create(:ci_build, :pending, pipeline: pipeline, created_at: 4.hours.ago, updated_at: 4.hours.ago)
    end

    let_it_be_with_reload(:stuck_job_p101) do
      pipeline = create(:ci_pipeline, partition_id: 101)
      create(:ci_build, :pending, pipeline: pipeline, created_at: 3.hours.ago, updated_at: 3.hours.ago)
    end

    let_it_be_with_reload(:stuck_job_p102) do
      pipeline = create(:ci_pipeline, partition_id: 102)
      create(:ci_build, :pending, pipeline: pipeline, created_at: 2.hours.ago, updated_at: 2.hours.ago)
    end

    before do
      allow_next_found_instance_of(Ci::Build) do |build|
        allow(build).to receive(:stuck?) { build.id != job.id }
      end
    end

    shared_examples 'processes stuck jobs' do
      it 'drops all stuck jobs' do
        service.execute

        expect(job.reload).to be_pending

        [stuck_job, stuck_job_p101, stuck_job_p102].each do |build|
          expect(build.reload).to be_failed
          expect(build.failure_reason).to eq('stuck_or_timeout_failure')
        end
      end

      context 'when FF `drop_stuck_builds_from_ci_pending_builds_queue` is disabled' do
        before do
          stub_feature_flags(drop_stuck_builds_from_ci_pending_builds_queue: false)
        end

        it 'does not drop stuck jobs (bug)' do
          service.execute

          [job, stuck_job, stuck_job_p101, stuck_job_p102].each do |build|
            expect(build.reload).to be_pending
          end
        end
      end
    end

    it_behaves_like 'processes stuck jobs'

    context 'when there are more pending jobs than BATCH_SIZE' do
      before do
        stub_const("Ci::StuckBuilds::DropHelpers::BATCH_SIZE", 2)
      end

      it_behaves_like 'processes stuck jobs'
    end
  end

  context 'when job is running' do
    let(:status) { 'running' }

    context 'when job was updated_at more than an hour ago' do
      let(:updated_at) { 2.hours.ago }

      it_behaves_like 'job is unchanged'
    end

    context 'when job was updated in less than 1 hour ago' do
      let(:updated_at) { 30.minutes.ago }

      it_behaves_like 'job is unchanged'
    end
  end

  %w[success skipped failed canceled].each do |status|
    context "when job is #{status}" do
      let(:status) { status }
      let(:updated_at) { 2.days.ago }

      context 'when created_at is the same as updated_at' do
        let(:created_at) { 2.days.ago }

        it_behaves_like 'job is unchanged'
      end

      context 'when created_at is before updated_at' do
        let(:created_at) { 3.days.ago }

        it_behaves_like 'job is unchanged'
      end
    end
  end

  context 'for deleted project' do
    let(:status) { 'running' }
    let(:updated_at) { 2.days.ago }

    before do
      job.project.update!(pending_delete: true)
    end

    it_behaves_like 'job is unchanged'
  end
end
