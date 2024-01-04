# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Ci::AbortPipelinesService, feature_category: :continuous_integration do
  let_it_be(:user) { create(:user) }
  let_it_be(:project) { create(:project, namespace: user.namespace) }

  let_it_be(:cancelable_pipeline, reload: true) { create(:ci_pipeline, :running, project: project, user: user) }
  let_it_be(:manual_pipeline, reload: true) { create(:ci_pipeline, status: :manual, project: project, user: user) }
  let_it_be(:other_users_pipeline, reload: true) { create(:ci_pipeline, :running, project: project, user: create(:user)) } # not this user's pipeline

  let_it_be(:cancelable_build, reload: true) { create(:ci_build, :running, pipeline: cancelable_pipeline) }
  let_it_be(:non_cancelable_build, reload: true) { create(:ci_build, :success, pipeline: cancelable_pipeline) }
  let_it_be(:cancelable_stage, reload: true) { create(:ci_stage, name: 'stageA', status: :running, pipeline: cancelable_pipeline, project: project) }
  let_it_be(:non_cancelable_stage, reload: true) { create(:ci_stage, name: 'stageB', status: :success, pipeline: cancelable_pipeline, project: project) }

  let_it_be(:manual_pipeline_cancelable_build, reload: true) { create(:ci_build, :created, pipeline: manual_pipeline) }
  let_it_be(:manual_pipeline_non_cancelable_build, reload: true) { create(:ci_build, :manual, pipeline: manual_pipeline) }
  let_it_be(:manual_pipeline_cancelable_stage, reload: true) { create(:ci_stage, name: 'stageA', status: :created, pipeline: manual_pipeline, project: project) }
  let_it_be(:manual_pipeline_non_cancelable_stage, reload: true) { create(:ci_stage, name: 'stageB', status: :success, pipeline: manual_pipeline, project: project) }

  describe '#execute' do
    def expect_correct_pipeline_cancellations
      expect(cancelable_pipeline.finished_at).not_to be_nil
      expect(cancelable_pipeline).to be_failed

      expect(manual_pipeline.finished_at).not_to be_nil
      expect(manual_pipeline).to be_failed
    end

    def expect_correct_stage_cancellations
      expect(cancelable_pipeline.stages - [non_cancelable_stage]).to all(be_failed)
      expect(manual_pipeline.stages - [manual_pipeline_non_cancelable_stage]).to all(be_failed)

      expect(non_cancelable_stage).not_to be_failed
      expect(manual_pipeline_non_cancelable_stage).not_to be_failed
    end

    def expect_correct_build_cancellations
      expect(cancelable_build).to be_failed
      expect(cancelable_build.finished_at).not_to be_nil

      expect(manual_pipeline_cancelable_build).to be_failed
      expect(manual_pipeline_cancelable_build.finished_at).not_to be_nil

      expect(non_cancelable_build).not_to be_failed
      expect(manual_pipeline_non_cancelable_build).not_to be_failed
    end

    def expect_correct_cancellations
      expect_correct_pipeline_cancellations
      expect_correct_stage_cancellations
      expect_correct_build_cancellations
    end

    context 'with project pipelines' do
      def abort_project_pipelines
        described_class.new.execute(project.all_pipelines, :project_deleted)
      end

      it 'fails all running pipelines and related jobs' do
        expect(abort_project_pipelines).to be_success

        expect_correct_cancellations

        expect(other_users_pipeline.status).to eq('failed')
        expect(other_users_pipeline.failure_reason).to eq('project_deleted')
        expect(other_users_pipeline.stages.map(&:status)).to all(eq('failed'))
      end

      it 'avoids N+1 queries' do
        control = ActiveRecord::QueryRecorder.new { abort_project_pipelines }

        pipelines = create_list(:ci_pipeline, 5, :running, project: project)
        create_list(:ci_build, 5, :running, pipeline: pipelines.first)

        expect { abort_project_pipelines }.not_to exceed_query_limit(control)
      end

      context 'with live build logs' do
        before do
          create(:ci_build_trace_chunk, build: cancelable_build)
        end

        it 'makes failed builds with stale trace visible' do
          expect(Ci::Build.with_stale_live_trace.count).to eq 0

          travel_to(2.days.ago) do
            abort_project_pipelines
          end

          expect(Ci::Build.with_stale_live_trace.count).to eq 1
        end
      end
    end
  end
end
