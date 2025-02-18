# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'PipelineSchedulePlay', feature_category: :continuous_integration do
  include GraphqlHelpers

  let_it_be(:current_user) { create(:user) }
  let_it_be(:project) { create(:project) }
  let_it_be(:pipeline_schedule) do
    create(
      :ci_pipeline_schedule,
      :every_minute,
      project: project,
      owner: current_user
    )
  end

  let(:mutation) do
    graphql_mutation(
      :pipeline_schedule_play,
      { id: pipeline_schedule.to_global_id.to_s },
      <<-QL
        pipelineSchedule { id, nextRunAt }
        errors
      QL
    )
  end

  let(:mutation_response) { graphql_mutation_response(:pipeline_schedule_play) }

  context 'when unauthorized' do
    it_behaves_like 'a mutation on an unauthorized resource'
  end

  context 'when authorized', :sidekiq_inline do
    before_all do
      project.add_maintainer(current_user)
      pipeline_schedule.update_columns(next_run_at: 2.hours.ago)
    end

    context 'when mutation succeeds' do
      let(:service_response) { instance_double('ServiceResponse', payload: new_pipeline) }
      let(:new_pipeline) { instance_double('Ci::Pipeline', persisted?: true) }

      it do
        expect(Ci::CreatePipelineService).to receive_message_chain(:new, :execute).and_return(service_response)
        post_graphql_mutation(mutation, current_user: current_user)

        expect(mutation_response['pipelineSchedule']['id']).to include(pipeline_schedule.id.to_s)
        new_next_run_at = DateTime.parse(mutation_response['pipelineSchedule']['nextRunAt'])
        expect(new_next_run_at).not_to eq(pipeline_schedule.next_run_at)
        expect(new_next_run_at).to eq(pipeline_schedule.reset.next_run_at)
        expect(mutation_response['errors']).to eq([])
      end
    end

    context 'when mutation fails' do
      it do
        expect(Ci::PipelineSchedules::PlayService)
          .to receive_message_chain(:new, :execute)
          .with(pipeline_schedule)
          .and_return(nil)

        post_graphql_mutation(mutation, current_user: current_user)

        expect(mutation_response['pipelineSchedule']).to be_nil
        expect(mutation_response['errors']).to match_array(['Unable to schedule a pipeline to run immediately.'])
      end
    end

    context 'when PipelineScheduleService raises AccessDeniedError' do
      before do
        allow(Ci::PipelineSchedules::PlayService).to receive_message_chain(:new,
          :execute).and_raise Gitlab::Access::AccessDeniedError
      end

      it_behaves_like 'a mutation on an unauthorized resource'
    end
  end
end
