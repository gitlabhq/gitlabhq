# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Ci::TrackPipelineTriggerEventsWorker, feature_category: :continuous_integration do
  let_it_be(:project) { create(:project, :repository) }
  let_it_be(:user) { create(:user) }

  let(:pipeline) { create(:ci_pipeline, project: project, user: user) }
  let(:event) { Ci::PipelineCreatedEvent.new(data: { pipeline_id: pipeline.id, partition_id: pipeline.partition_id }) }

  subject(:handle_event) { consume_event(subscriber: described_class, event: event) }

  it_behaves_like 'subscribes to event'

  describe '#handle_event' do
    context 'when pipeline has builds' do
      context 'when pipeline is created by a human user' do
        let!(:build1) { create(:ci_build, pipeline: pipeline, user: user) }
        let!(:build2) { create(:ci_build, pipeline: pipeline, user: user) }

        it 'tracks ci_pipeline_triggered event' do
          expect { handle_event }
            .to trigger_internal_events('ci_pipeline_triggered')
            .with(
              user: user,
              project: project,
              additional_properties: { user_type: 'human' }
            ).once
        end

        it 'tracks ci_build_triggered event for each build' do
          expect { handle_event }
          .to trigger_internal_events('ci_build_triggered')
          .with(
            user: user,
            project: project,
            additional_properties: { user_type: 'human' }
          ).twice
        end
      end

      context 'when pipeline is created by a bot user' do
        let_it_be(:bot_user) { create(:user, :project_bot) }
        let(:pipeline) { create(:ci_pipeline, project: project, user: bot_user) }
        let!(:build1) { create(:ci_build, pipeline: pipeline, user: bot_user) }

        before_all do
          project.add_developer(bot_user)
        end

        it 'tracks ci_pipeline_triggered event with bot user_type' do
          expect { handle_event }
            .to trigger_internal_events('ci_pipeline_triggered')
            .with(
              user: bot_user,
              project: project,
              additional_properties: { user_type: 'bot' }
            ).once
        end

        it 'tracks ci_build_triggered event with bot user_type' do
          expect { handle_event }
          .to trigger_internal_events('ci_build_triggered')
          .with(
            user: bot_user,
            project: project,
            additional_properties: { user_type: 'bot' }
          ).once
        end
      end
    end

    context 'when pipeline has no builds' do
      it 'tracks ci_pipeline_triggered event' do
        expect { handle_event }
          .to trigger_internal_events('ci_pipeline_triggered')
          .with(
            user: user,
            project: project,
            additional_properties: { user_type: 'human' }
          ).once
      end

      it 'does not track any events' do
        expect { handle_event }
          .not_to trigger_internal_events('ci_build_triggered')
      end
    end

    context 'when pipeline does not exist' do
      let(:event) { Ci::PipelineCreatedEvent.new(data: { pipeline_id: non_existing_record_id, partition_id: 100 }) }

      it 'does not track any events' do
        expect { handle_event }
          .not_to trigger_internal_events
      end
    end
  end
end
