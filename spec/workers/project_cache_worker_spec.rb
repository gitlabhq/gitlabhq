# frozen_string_literal: true

require 'spec_helper'

RSpec.describe ProjectCacheWorker, feature_category: :source_code_management do
  include ExclusiveLeaseHelpers

  let_it_be(:project) { create(:project, :repository) }

  let(:worker) { described_class.new }
  let(:lease_key) { ["project_cache_worker", project.id, *statistics.sort].join(":") }
  let(:lease_timeout) { ProjectCacheWorker::LEASE_TIMEOUT }
  let(:statistics) { [] }

  describe '#perform' do
    context 'with a non-existing project' do
      it 'does nothing' do
        expect(worker).not_to receive(:update_statistics)

        worker.perform(-1)
      end
    end

    context 'with an existing project without a repository' do
      it 'updates statistics but does not refresh the method cashes' do
        allow_any_instance_of(Repository).to receive(:exists?).and_return(false)

        expect(worker).to receive(:update_statistics)
        expect_any_instance_of(Repository).not_to receive(:refresh_method_caches)

        worker.perform(project.id)
      end
    end

    context 'with an existing project' do
      it 'refreshes the method caches' do
        expect_any_instance_of(Repository).to receive(:refresh_method_caches)
          .with(%i[readme])
          .and_call_original

        worker.perform(project.id, %w[readme])
      end

      context 'with statistics disabled' do
        let(:statistics) { [] }

        it 'does not update the project statistics' do
          expect(worker).not_to receive(:update_statistics)

          worker.perform(project.id, [], [], false)
        end
      end

      context 'with statistics' do
        let(:statistics) { %w[repository_size] }

        it 'updates the project statistics' do
          expect(worker).to receive(:update_statistics)
            .with(kind_of(Project), statistics)
            .and_call_original

          worker.perform(project.id, [], statistics)
        end
      end

      context 'with plain readme' do
        it 'refreshes the method caches' do
          allow(Gitlab::MarkupHelper).to receive(:gitlab_markdown?).and_return(false)
          allow(Gitlab::MarkupHelper).to receive(:plain?).and_return(true)

          expect_any_instance_of(Repository).to receive(:refresh_method_caches)
                                                  .with(%i[readme])
                                                  .and_call_original
          worker.perform(project.id, %w[readme])
        end
      end
    end
  end

  describe '#update_statistics' do
    let(:statistics) { %w[repository_size] }

    context 'when a lease could not be obtained' do
      it 'does not update the project statistics' do
        stub_exclusive_lease_taken(lease_key, timeout: lease_timeout)

        expect(Projects::UpdateStatisticsService).not_to receive(:new)

        expect(UpdateProjectStatisticsWorker).not_to receive(:perform_in)

        expect(Namespaces::ScheduleAggregationWorker)
          .not_to receive(:perform_async)
          .with(project.namespace_id)

        worker.update_statistics(project, statistics)
      end
    end

    context 'when a lease could be obtained' do
      it 'updates the project statistics twice', :sidekiq_might_not_need_inline do
        stub_exclusive_lease(lease_key, timeout: lease_timeout)

        expect(Projects::UpdateStatisticsService).to receive(:new)
          .with(project, nil, statistics: statistics)
          .and_call_original
          .twice

        expect(UpdateProjectStatisticsWorker).to receive(:perform_in)
          .with(lease_timeout, lease_key, project.id, statistics)
          .and_call_original

        expect(Namespaces::ScheduleAggregationWorker)
          .to receive(:perform_async)
          .with(project.namespace_id)
          .twice

        worker.update_statistics(project, statistics)
      end
    end
  end

  it_behaves_like 'an idempotent worker' do
    let(:job_args) { [project.id, %w[readme], %w[repository_size]] }

    it 'calls Projects::UpdateStatisticsService service twice', :clean_gitlab_redis_shared_state do
      expect(Projects::UpdateStatisticsService).to receive(:new).once.and_return(double(execute: true))
      expect(UpdateProjectStatisticsWorker).to receive(:perform_in).once

      subject
    end
  end
end
