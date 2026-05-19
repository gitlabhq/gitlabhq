# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Ci::TrackFirstPipelineSucceededWorker, feature_category: :pipeline_composition do
  let_it_be(:project) { create(:project) }
  let_it_be(:user) { create(:user) }

  subject(:perform) { described_class.new.perform(pipeline.id) }

  describe '#perform' do
    context 'when pipeline succeeded and is the first for the project' do
      let(:pipeline) { create(:ci_pipeline, :success, project: project, user: user) }

      it 'fires internal event with time-to-first-pipeline value and consistent timestamp' do
        freeze_time do
          succeeded_at = Time.current
          expected_ttfp = (succeeded_at - project.created_at).to_i

          expect { perform }
            .to trigger_internal_events('first_pipeline_succeeded')
            .with(project: project, user: user, additional_properties: { value: expected_ttfp })
            .once

          metric = Ci::ProjectMetric.find_by(project_id: project.id)
          expect(metric.first_pipeline_succeeded_at).to eq(succeeded_at)
        end
      end

      it 'creates a ci_project_metrics record' do
        expect { perform }.to change { Ci::ProjectMetric.count }.by(1)
      end
    end

    context 'when project already has a recorded first pipeline success' do
      let(:pipeline) { create(:ci_pipeline, :success, project: project, user: user) }
      let!(:existing_metric) { create(:ci_project_metric, :with_first_pipeline_succeeded, project: project) }

      it 'does not call record_first_pipeline_success!' do
        expect(Ci::ProjectMetric).not_to receive(:record_first_pipeline_success!)

        perform
      end

      it 'does not fire the internal event' do
        expect { perform }.not_to trigger_internal_events('first_pipeline_succeeded')
      end

      it 'does not change the existing timestamp' do
        original_timestamp = existing_metric.first_pipeline_succeeded_at

        perform

        expect(existing_metric.reload.first_pipeline_succeeded_at).to be_within(0.000001.seconds).of(original_timestamp)
      end
    end

    context 'when pipeline has no user' do
      let(:pipeline) { create(:ci_pipeline, :success, project: project, user: nil) }

      it 'fires internal event without error' do
        expect { perform }.not_to raise_error
      end

      it 'creates a ci_project_metrics record' do
        expect { perform }.to change { Ci::ProjectMetric.count }.by(1)
      end
    end

    context 'when pipeline is not successful' do
      let(:pipeline) { create(:ci_pipeline, :failed, project: project, user: user) }

      it 'does not fire internal event' do
        expect { perform }.not_to trigger_internal_events('first_pipeline_succeeded')
      end

      it 'does not create a ci_project_metrics record' do
        expect { perform }.not_to change { Ci::ProjectMetric.count }
      end
    end

    context 'when pipeline does not exist' do
      it 'does not fire internal event' do
        expect { described_class.new.perform(non_existing_record_id) }
          .not_to trigger_internal_events('first_pipeline_succeeded')
      end
    end

    context 'when perform is called twice (idempotency)' do
      let(:pipeline) { create(:ci_pipeline, :success, project: project, user: user) }

      it 'fires the event exactly once' do
        pipeline_id = pipeline.id

        expect { 2.times { described_class.new.perform(pipeline_id) } }
          .to trigger_internal_events('first_pipeline_succeeded')
          .with(project: project, user: user)
          .once
      end

      it 'results in exactly one ci_project_metrics record' do
        2.times { described_class.new.perform(pipeline.id) }

        expect(Ci::ProjectMetric.where(project_id: project.id).count).to eq(1)
      end

      it 'preserves the timestamp from the first call' do
        first_timestamp = nil

        freeze_time do
          described_class.new.perform(pipeline.id)
          first_timestamp = Ci::ProjectMetric.find_by(project_id: project.id).first_pipeline_succeeded_at
        end

        travel_to(1.minute.from_now) do
          described_class.new.perform(pipeline.id)
        end

        expect(Ci::ProjectMetric.find_by(project_id: project.id).first_pipeline_succeeded_at).to eq(first_timestamp)
      end
    end

    context 'with idempotent worker shared example' do
      let(:pipeline) { create(:ci_pipeline, :success, project: project, user: user) }
      let(:job_args) { [pipeline.id] }

      it_behaves_like 'an idempotent worker'
    end
  end
end
