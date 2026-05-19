# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'RunnerDelete', feature_category: :runner_core do
  include GraphqlHelpers

  context 'with a project runner' do
    let_it_be(:project) { create(:project) }
    let_it_be(:current_user) { create(:user, maintainer_of: project) }
    let_it_be(:runner) { create(:ci_runner, :project, projects: [project]) }

    let(:mutation) do
      graphql_mutation(:runner_delete, { id: runner.to_global_id.to_s }, 'errors')
    end

    it_behaves_like 'authorizing granular token permissions for GraphQL', :delete_runner do
      let(:user) { current_user }
      let(:boundary_object) { project }
      let(:request) { post_graphql_mutation(mutation, token: { personal_access_token: pat }) }
    end
  end

  context 'with a group runner' do
    let_it_be(:group) { create(:group) }
    let_it_be(:current_user) { create(:user, owner_of: group) }
    let_it_be(:runner) { create(:ci_runner, :group, groups: [group]) }

    let(:mutation) do
      graphql_mutation(:runner_delete, { id: runner.to_global_id.to_s }, 'errors')
    end

    it_behaves_like 'authorizing granular token permissions for GraphQL', :delete_runner do
      let(:user) { current_user }
      let(:boundary_object) { group }
      let(:request) { post_graphql_mutation(mutation, token: { personal_access_token: pat }) }
    end
  end

  context 'with an instance runner' do
    let_it_be(:current_user) { create(:admin) }
    let_it_be(:runner) { create(:ci_runner, :instance) }

    let(:mutation) do
      graphql_mutation(:runner_delete, { id: runner.to_global_id.to_s }, 'errors')
    end

    it_behaves_like 'authorizing granular token permissions for GraphQL', :delete_runner do
      let(:user) { current_user }
      let(:boundary_object) { :instance }
      let(:request) { post_graphql_mutation(mutation, token: { personal_access_token: pat }) }
    end
  end
end
