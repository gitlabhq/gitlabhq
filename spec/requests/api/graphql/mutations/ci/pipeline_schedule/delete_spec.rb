# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'PipelineScheduleDelete', feature_category: :continuous_integration do
  include GraphqlHelpers

  let_it_be(:current_user) { create(:user) }
  let_it_be(:project) { create(:project) }
  let_it_be(:pipeline_schedule) { create(:ci_pipeline_schedule, project: project, owner: current_user) }

  let(:mutation) do
    graphql_mutation(
      :pipeline_schedule_delete,
      { id: pipeline_schedule_id },
      <<-QL
        errors
      QL
    )
  end

  let(:pipeline_schedule_id) { pipeline_schedule.to_global_id.to_s }
  let(:mutation_response) { graphql_mutation_response(:pipeline_schedule_delete) }

  context 'when unauthorized' do
    it_behaves_like 'a mutation on an unauthorized resource'
  end

  context 'when authorized' do
    before_all do
      project.add_maintainer(current_user)
    end

    context 'when success' do
      it do
        post_graphql_mutation(mutation, current_user: current_user)

        expect(response).to have_gitlab_http_status(:success)
        expect(mutation_response['errors']).to eq([])
      end
    end

    context 'when failure' do
      context 'when destroy fails' do
        before do
          allow_next_found_instance_of(Ci::PipelineSchedule) do |pipeline_schedule|
            allow(pipeline_schedule).to receive(:destroy).and_return(false)
          end
        end

        it do
          post_graphql_mutation(mutation, current_user: current_user)

          expect(response).to have_gitlab_http_status(:success)

          expect(mutation_response['errors']).to match_array(['Failed to remove the pipeline schedule'])
        end
      end

      context 'when pipeline schedule not found' do
        let(:pipeline_schedule_id) { 'gid://gitlab/Ci::PipelineSchedule/0' }

        it do
          post_graphql_mutation(mutation, current_user: current_user)

          expect(graphql_errors).not_to be_empty
          expect(graphql_errors[0]['message'])
            .to eq("Internal server error: Couldn't find Ci::PipelineSchedule with 'id'=0")
        end
      end
    end
  end
end
