# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'PipelineScheduleTakeOwnership', feature_category: :continuous_integration do
  include GraphqlHelpers

  let_it_be(:user) { create(:user) }
  let_it_be(:owner) { create(:user) }
  let_it_be(:project) { create(:project, maintainers: user) }
  let_it_be(:pipeline_schedule) { create(:ci_pipeline_schedule, project: project, owner: owner) }

  let(:mutation) do
    graphql_mutation(
      :pipeline_schedule_take_ownership,
      { id: pipeline_schedule_id },
      <<-QL
        errors
      QL
    )
  end

  let(:pipeline_schedule_id) { pipeline_schedule.to_global_id.to_s }

  it 'returns an error if the user is not allowed to take ownership of the schedule' do
    post_graphql_mutation(mutation, current_user: create(:user))

    expect(graphql_errors).not_to be_empty
  end

  it 'takes ownership of the schedule' do
    post_graphql_mutation(mutation, current_user: user)

    expect(response).to have_gitlab_http_status(:success)
    expect(graphql_errors).to be_nil
  end
end
