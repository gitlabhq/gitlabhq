# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Stop Environment', feature_category: :environment_management do
  include GraphqlHelpers

  let_it_be(:project) { create(:project, :repository) }
  let_it_be(:user) { create(:user, maintainer_of: project) }
  let_it_be(:environment) { create(:environment, project: project) }

  it_behaves_like 'authorizing granular token permissions for GraphQL', :stop_environment do
    let(:boundary_object) { project }
    let(:mutation) do
      graphql_mutation(:environment_stop, { id: environment.to_global_id.to_s }, 'errors')
    end

    let(:request) { post_graphql_mutation(mutation, token: { personal_access_token: pat }) }
  end
end
