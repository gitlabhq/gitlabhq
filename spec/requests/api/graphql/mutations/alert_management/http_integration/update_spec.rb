# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Updating an existing HTTP Integration', feature_category: :incident_management do
  include GraphqlHelpers

  let_it_be(:current_user) { create(:user) }
  let_it_be(:project) { create(:project, maintainers: current_user) }
  let_it_be(:integration) { create(:alert_management_http_integration, project: project) }

  let(:mutation) do
    variables = {
      id: GitlabSchema.id_from_object(integration).to_s,
      name: 'Modified Name',
      active: false
    }
    graphql_mutation(:http_integration_update, variables) do
      <<~QL
         clientMutationId
         errors
         integration {
           id
           name
           active
           url
         }
      QL
    end
  end

  let(:mutation_response) { graphql_mutation_response(:http_integration_update) }

  it_behaves_like 'updating an existing HTTP integration'
end
