# frozen_string_literal: true

require 'spec_helper'

# Regression test for security issue gitlab-org/gitlab#594294.
#
# GraphQL `CiJob.trace` only enforced `:read_build` (JobInterfaceBaseField). Debug-mode
# traces expose CI/CD variable values in plaintext, so the trace must also require
# `:read_build_trace`, matching the REST endpoint and Ci::BuildPolicy.
RSpec.describe 'Querying a CI job trace', feature_category: :continuous_integration do
  include GraphqlHelpers

  let(:query) do
    <<~GQL
      query($fullPath: ID!) {
        project(fullPath: $fullPath) {
          pipelines { nodes { jobs { nodes { name trace { htmlSummary } } } } }
        }
      }
    GQL
  end

  def trace_for(user, project)
    post_graphql(query, current_user: user, variables: { fullPath: project.full_path })
    graphql_data_at(:project, :pipelines, :nodes, 0, :jobs, :nodes, 0, :trace)
  end

  # Debug mode makes `:read_build_trace` require `:update_build` (Developer+), so users
  # who can only `:read_build` must not see the trace even though they see the job.
  context 'with a debug-mode trace' do
    context 'on a private project' do
      let_it_be(:project) { create(:project, :private, :repository) }
      let_it_be(:reporter) { create(:user, reporter_of: project) }
      let_it_be(:maintainer) { create(:user, maintainer_of: project) }
      let_it_be(:pipeline) { create(:ci_pipeline, project: project) }
      let_it_be(:build) { create(:ci_build, :trace_artifact, pipeline: pipeline) }
      let_it_be(:debug_variable) { create(:ci_job_variable, key: 'CI_DEBUG_TRACE', value: 'true', job: build) }

      it 'is hidden from a Reporter (lacks :read_build_trace)' do
        expect(trace_for(reporter, project)).to be_nil
      end

      it 'is visible to a Maintainer (has :read_build_trace)', :aggregate_failures do
        trace = trace_for(maintainer, project)

        expect(trace).to be_present
        expect(trace['htmlSummary']).to be_present
      end

      it 'is visible to an admin' do
        stub_application_setting(admin_mode: false)

        expect(trace_for(create(:admin), project)).to be_present
      end
    end

    context 'on a public project' do
      let_it_be(:project) { create(:project, :public, :repository) }
      let_it_be(:pipeline) { create(:ci_pipeline, project: project) }
      let_it_be(:build) { create(:ci_build, :trace_artifact, pipeline: pipeline) }
      let_it_be(:debug_variable) { create(:ci_job_variable, key: 'CI_DEBUG_TRACE', value: 'true', job: build) }

      it 'is hidden from an anonymous user' do
        expect(trace_for(nil, project)).to be_nil
      end
    end
  end

  # A non-debug trace stays readable for anyone with `:read_build`; the fix must not
  # over-restrict by hiding ordinary traces.
  context 'with a non-debug trace' do
    let_it_be(:project) { create(:project, :private, :repository) }
    let_it_be(:reporter) { create(:user, reporter_of: project) }
    let_it_be(:pipeline) { create(:ci_pipeline, project: project) }
    let_it_be(:build) { create(:ci_build, :trace_artifact, pipeline: pipeline) }

    it 'stays visible to a Reporter', :aggregate_failures do
      trace = trace_for(reporter, project)

      expect(trace).to be_present
      expect(trace['htmlSummary']).to be_present
    end
  end
end
