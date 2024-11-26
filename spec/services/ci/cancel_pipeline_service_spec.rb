# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Ci::CancelPipelineService, :aggregate_failures, feature_category: :continuous_integration do
  let_it_be(:project) { create(:project) }
  let_it_be(:current_user) { project.owner }
  let_it_be(:pipeline) { create(:ci_pipeline, project: project) }

  let(:service) do
    described_class.new(
      pipeline: pipeline,
      current_user: current_user,
      cascade_to_children: cascade_to_children,
      auto_canceled_by_pipeline: auto_canceled_by_pipeline,
      execute_async: execute_async,
      safe_cancellation: safe_cancellation)
  end

  let(:cascade_to_children) { true }
  let(:auto_canceled_by_pipeline) { nil }
  let(:execute_async) { true }
  let(:safe_cancellation) { false }

  shared_examples 'force_execute' do
    context 'when pipeline is not cancelable' do
      it 'returns an error' do
        expect(response).to be_error
        expect(response.reason).to eq(:pipeline_not_cancelable)
      end
    end

    context 'when pipeline is cancelable' do
      before do
        create(:ci_build, :running, pipeline: pipeline, name: 'build1')
        create(:ci_build, :created, pipeline: pipeline, name: 'build2')
        create(:ci_build, :success, pipeline: pipeline, name: 'build3')
        create(:ci_build, :pending, :interruptible, pipeline: pipeline, name: 'build4')

        create(:ci_bridge, :running, pipeline: pipeline, name: 'bridge1')
        create(:ci_bridge, :running, :interruptible, pipeline: pipeline, name: 'bridge2')
        create(:ci_bridge, :success, :interruptible, pipeline: pipeline, name: 'bridge3')
      end

      it 'logs the event' do
        allow(Gitlab::AppJsonLogger).to receive(:info)

        subject

        expect(Gitlab::AppJsonLogger)
          .to have_received(:info)
          .with(
            a_hash_including(
              class: described_class.to_s,
              event: 'pipeline_cancel_running',
              pipeline_id: pipeline.id,
              auto_canceled_by_pipeline_id: nil,
              cascade_to_children: true,
              execute_async: true
            )
          )
      end

      it 'cancels all cancelable jobs' do
        expect(response).to be_success
        expect(pipeline.all_jobs.pluck(:name, :status)).to match_array([
          %w[build1 canceled],
          %w[build2 canceled],
          %w[build3 success],
          %w[build4 canceled],
          %w[bridge1 canceled],
          %w[bridge2 canceled],
          %w[bridge3 success]
        ])
      end

      context 'when auto_canceled_by_pipeline is provided' do
        let(:auto_canceled_by_pipeline) { create(:ci_pipeline) }

        it 'updates the pipeline and jobs with it' do
          subject

          expect(pipeline.auto_canceled_by_id).to eq(auto_canceled_by_pipeline.id)
          expect(pipeline.auto_canceled_by_partition_id).to eq(auto_canceled_by_pipeline.partition_id)

          expect(pipeline.all_jobs.canceled.pluck(:auto_canceled_by_id).uniq)
            .to eq([auto_canceled_by_pipeline.id])

          expect(pipeline.all_jobs.canceled.pluck(:auto_canceled_by_partition_id).uniq)
            .to eq([auto_canceled_by_pipeline.partition_id])
        end
      end

      context 'when cascade_to_children: false and safe_cancellation: true' do
        # We are testing the `safe_cancellation: true`` case with only `cascade_to_children: false`
        # because `safe_cancellation` is passed as `true` only when `cascade_to_children` is `false`
        # from `CancelRedundantPipelinesService`.

        let(:cascade_to_children) { false }
        let(:safe_cancellation) { true }

        it 'cancels only interruptible jobs' do
          expect(response).to be_success
          expect(pipeline.all_jobs.pluck(:name, :status)).to match_array([
            %w[build1 running],
            %w[build2 created],
            %w[build3 success],
            %w[build4 canceled],
            %w[bridge1 running],
            %w[bridge2 canceled],
            %w[bridge3 success]
          ])
        end
      end

      context 'when pipeline has child pipelines' do
        let(:child_pipeline) { create(:ci_pipeline, child_of: pipeline) }
        let!(:child_job) { create(:ci_build, :running, pipeline: child_pipeline) }
        let(:grandchild_pipeline) { create(:ci_pipeline, child_of: child_pipeline) }
        let!(:grandchild_job) { create(:ci_build, :running, pipeline: grandchild_pipeline) }

        before do
          child_pipeline.source_bridge.update!(name: 'child_pipeline_bridge', status: :running)
          grandchild_pipeline.source_bridge.update!(name: 'grandchild_pipeline_bridge', status: :running)
        end

        context 'when execute_async: false' do
          let(:execute_async) { false }

          it 'cancels the bridge jobs and child jobs' do
            expect(response).to be_success

            expect(pipeline.bridges.pluck(:name, :status)).to match_array([
              %w[bridge1 canceled],
              %w[bridge2 canceled],
              %w[bridge3 success],
              %w[child_pipeline_bridge canceled]
            ])
            expect(child_pipeline.bridges.pluck(:name, :status)).to match_array([
              %w[grandchild_pipeline_bridge canceled]
            ])
            expect(child_job.reload).to be_canceled
            expect(grandchild_job.reload).to be_canceled
          end
        end

        context 'when execute_async: true' do
          it 'schedules the child pipelines for async cancelation' do
            expect(::Ci::CancelPipelineWorker)
              .to receive(:perform_async)
              .with(child_pipeline.id, nil)

            expect(::Ci::CancelPipelineWorker)
              .to receive(:perform_async)
              .with(grandchild_pipeline.id, nil)

            expect(response).to be_success

            expect(pipeline.bridges.pluck(:name, :status)).to match_array([
              %w[bridge1 canceled],
              %w[bridge2 canceled],
              %w[bridge3 success],
              %w[child_pipeline_bridge canceled]
            ])
          end
        end

        context 'when cascade_to_children: false' do
          let(:execute_async) { true }
          let(:cascade_to_children) { false }

          it 'does not cancel child pipelines' do
            expect(::Ci::CancelPipelineWorker)
              .not_to receive(:perform_async)

            expect(response).to be_success

            expect(pipeline.bridges.pluck(:name, :status)).to match_array([
              %w[bridge1 canceled],
              %w[bridge2 canceled],
              %w[bridge3 success],
              %w[child_pipeline_bridge canceled]
            ])
            expect(child_job.reload).to be_running
          end
        end
      end

      context 'when preloading relations' do
        let(:pipeline1) { create(:ci_pipeline, :created) }
        let(:pipeline2) { create(:ci_pipeline, :created) }

        before do
          create(:ci_build, :pending, pipeline: pipeline1)
          create(:generic_commit_status, :pending, pipeline: pipeline1)

          create(:ci_build, :pending, pipeline: pipeline2)
          create(:ci_build, :pending, pipeline: pipeline2)
          create(:generic_commit_status, :pending, pipeline: pipeline2)
          create(:generic_commit_status, :pending, pipeline: pipeline2)
          create(:generic_commit_status, :pending, pipeline: pipeline2)
        end

        it 'preloads relations for each build to avoid N+1 queries' do
          control1 = ActiveRecord::QueryRecorder.new do
            described_class.new(pipeline: pipeline1, current_user: current_user).force_execute
          end

          control2 = ActiveRecord::QueryRecorder.new do
            described_class.new(pipeline: pipeline2, current_user: current_user).force_execute
          end

          extra_update_queries = 4 # transition ... => :canceled, queue pop
          extra_generic_commit_status_validation_queries = 2 # name_uniqueness_across_types

          expect(control2.count)
            .to eq(control1.count + extra_update_queries + extra_generic_commit_status_validation_queries)
        end
      end
    end
  end

  describe '#execute' do
    subject(:response) { service.execute }

    it_behaves_like 'force_execute'

    context 'when user does not have permissions to cancel the pipeline' do
      let(:current_user) { create(:user) }

      it 'returns an error when user does not have permissions to cancel pipeline' do
        expect(response).to be_error
        expect(response.reason).to eq(:insufficient_permissions)
      end
    end
  end

  describe '#force_execute' do
    subject(:response) { service.force_execute }

    it_behaves_like 'force_execute'

    context 'when pipeline is not provided' do
      let(:pipeline) { nil }

      it 'returns an error' do
        expect(response).to be_error
        expect(response.reason).to eq(:no_pipeline)
      end
    end
  end
end
