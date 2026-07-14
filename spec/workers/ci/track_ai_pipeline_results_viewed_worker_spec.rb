# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Ci::TrackAiPipelineResultsViewedWorker, feature_category: :pipeline_composition do
  let_it_be(:project) { create(:project) }
  let_it_be(:user) { create(:user) }
  let_it_be(:pipeline) { create(:ci_pipeline, project: project, user: user) }

  let(:config_generated_at) { 1.hour.ago }

  subject(:perform) { described_class.new.perform(pipeline.id, user.id) }

  describe '#perform' do
    context 'when the project is AI-config and the pipeline was created after the config commit' do
      let!(:metric) do
        create(:ci_project_metric, :ai_generated, project: project, ci_config_first_generated_at: config_generated_at)
      end

      it 'records the view and fires the internal event with author_source' do
        freeze_time do
          expect { perform }
            .to trigger_internal_events('view_ai_pipeline_results')
            .with(project: project, user: user, additional_properties: { author_source: 'ci_expert_agent/v1' })
            .once

          expect(metric.reload.first_ai_pipeline_results_viewed_at).to eq(Time.current)
        end
      end

      context 'when the view has already been recorded' do
        let(:recorded_at) { 1.day.ago }

        before do
          metric.update!(first_ai_pipeline_results_viewed_at: recorded_at)
        end

        it 'does not fire the event and preserves the original timestamp (first-wins)' do
          expect { perform }.not_to trigger_internal_events('view_ai_pipeline_results')
          expect(metric.reload.first_ai_pipeline_results_viewed_at).to be_within(1.second).of(recorded_at)
        end
      end

      context 'when the viewer no longer exists' do
        subject(:perform) { described_class.new.perform(pipeline.id, non_existing_record_id) }

        it 'still fires the event without raising' do
          expect { perform }
            .to trigger_internal_events('view_ai_pipeline_results')
            .with(project: project, additional_properties: { author_source: 'ci_expert_agent/v1' })
            .once
        end
      end
    end

    context 'when the pipeline was created exactly at the AI config commit time (>= boundary)' do
      before do
        create(:ci_project_metric, :ai_generated, project: project, ci_config_first_generated_at: pipeline.created_at)
      end

      it 'fires the event' do
        expect { perform }
          .to trigger_internal_events('view_ai_pipeline_results')
          .with(project: project, user: user, additional_properties: { author_source: 'ci_expert_agent/v1' })
          .once
      end
    end

    context 'when the pipeline predates the AI config commit' do
      before do
        create(:ci_project_metric, :ai_generated, project: project, ci_config_first_generated_at: 1.hour.from_now)
      end

      it 'does not fire the event' do
        expect { perform }.not_to trigger_internal_events('view_ai_pipeline_results')
      end
    end

    context 'when the project has no agent on record' do
      before do
        create(:ci_project_metric, project: project, ci_config_first_generated_at: config_generated_at)
      end

      it 'does not fire the event' do
        expect { perform }.not_to trigger_internal_events('view_ai_pipeline_results')
      end
    end

    context 'when the AI config commit time is not recorded (pre-feature cohort)' do
      before do
        create(:ci_project_metric, :ai_generated, project: project, ci_config_first_generated_at: nil)
      end

      it 'does not fire the event' do
        expect { perform }.not_to trigger_internal_events('view_ai_pipeline_results')
      end
    end

    context 'when no metric record exists for the project' do
      it 'does not fire the event' do
        expect { perform }.not_to trigger_internal_events('view_ai_pipeline_results')
      end
    end

    context 'when the pipeline does not exist' do
      it 'does not fire the event' do
        expect { described_class.new.perform(non_existing_record_id, user.id) }
          .not_to trigger_internal_events('view_ai_pipeline_results')
      end
    end

    context 'with idempotent worker shared example' do
      let!(:metric) do
        create(:ci_project_metric, :ai_generated, project: project, ci_config_first_generated_at: config_generated_at)
      end

      let(:job_args) { [pipeline.id, user.id] }

      it 'fires the event exactly once across repeated runs' do
        expect { 2.times { described_class.new.perform(pipeline.id, user.id) } }
          .to trigger_internal_events('view_ai_pipeline_results')
          .with(project: project, user: user, additional_properties: { author_source: 'ci_expert_agent/v1' })
          .once
      end

      it_behaves_like 'an idempotent worker'
    end
  end
end
