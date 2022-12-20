# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Query.project.job', feature_category: :continuous_integration do
  include GraphqlHelpers

  let_it_be(:project) { create(:project) }
  let_it_be(:user) { create(:user) }

  let(:job) { create(:ci_build, project: project, name: 'GQL test job') }

  let(:query) do
    <<~QUERY
    {
      project(fullPath: "#{project.full_path}") {
        job(id: "#{job.to_global_id}") {
          name
        }
      }
    }
    QUERY
  end

  context 'when the user can read jobs on the project' do
    before do
      project.add_developer(user)
    end

    it 'returns the job that matches the given ID' do
      post_graphql(query, current_user: user)

      expect(graphql_data.dig('project', 'job', 'name')).to eq('GQL test job')
    end

    context 'when no job matches the given ID' do
      let(:job) { create(:ci_build, project: create(:project), name: 'Job from another project') }

      it 'returns null' do
        post_graphql(query, current_user: user)

        expect(graphql_data.dig('project', 'job')).to be_nil
      end
    end
  end

  context 'when the user cannot read jobs on the project' do
    it 'returns null' do
      post_graphql(query, current_user: user)

      expect(graphql_data.dig('project', 'job')).to be_nil
    end
  end
end
