# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'RunnerCacheClear', feature_category: :runner do
  include GraphqlHelpers

  let_it_be(:current_user) { create(:user) }
  let_it_be_with_reload(:project) { create(:project, jobs_cache_index: 1) }

  let(:mutation) do
    graphql_mutation(:runner_cache_clear, { project_id: project.to_global_id.to_s }, 'errors')
  end

  let(:mutation_response) { graphql_mutation_response(:runner_cache_clear) }

  context 'when the user has admin pipeline permission on the given project' do
    before_all do
      project.add_maintainer(current_user)
    end

    it 'clears the runner cache' do
      expect do
        post_graphql_mutation(mutation, current_user: current_user)
      end.to change { project.reload.jobs_cache_index }.by(1)

      expect(mutation_response['errors']).to be_empty
    end
  end

  context 'when the user does not have admin pipeline permission' do
    it_behaves_like 'a mutation that returns a top-level access error'

    it 'does not clear the runner cache' do
      expect do
        post_graphql_mutation(mutation, current_user: current_user)
      end.not_to change { project.reload.jobs_cache_index }
    end
  end
end
