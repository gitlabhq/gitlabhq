# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'PipelineCancel' do
  include GraphqlHelpers

  let_it_be(:user) { create(:user) }
  let_it_be(:project) { create(:project) }
  let_it_be(:pipeline) { create(:ci_pipeline, :running, project: project, user: user) }

  let(:mutation) { graphql_mutation(:pipeline_cancel, {}, 'errors') }

  let(:mutation_response) { graphql_mutation_response(:pipeline_cancel) }

  before_all do
    project.add_maintainer(user)
  end

  it 'reports the service-level error' do
    service = double(execute: ServiceResponse.error(message: 'Error canceling pipeline'))
    allow(::Ci::CancelUserPipelinesService).to receive(:new).and_return(service)

    post_graphql_mutation(mutation, current_user: create(:user))

    expect(mutation_response).to include('errors' => ['Error canceling pipeline'])
  end

  it 'does not change any pipelines not owned by the current user' do
    build = create(:ci_build, :running, pipeline: pipeline)

    post_graphql_mutation(mutation, current_user: create(:user))

    expect(build).not_to be_canceled
  end

  it "cancels all of the current user's cancelable pipelines" do
    build = create(:ci_build, :running, pipeline: pipeline)

    post_graphql_mutation(mutation, current_user: user)

    expect(response).to have_gitlab_http_status(:success)
    expect(build.reload).to be_canceled
  end
end
