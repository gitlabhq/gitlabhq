# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Creating a new HTTP Integration', feature_category: :incident_management do
  include GraphqlHelpers

  let_it_be(:current_user) { create(:user) }
  let_it_be(:project) { create(:project, maintainers: current_user) }

  let(:variables) do
    {
      project_path: project.full_path,
      active: false,
      name: 'New HTTP Integration'
    }
  end

  let(:mutation) do
    graphql_mutation(:http_integration_create, variables) do
      <<~QL
         clientMutationId
         errors
         integration {
           id
           type
           name
           active
           token
           url
           apiUrl
         }
      QL
    end
  end

  let(:mutation_response) { graphql_mutation_response(:http_integration_create) }

  it_behaves_like 'creating a new HTTP integration'

  context 'with type argument' do
    let(:variables) do
      {
        project_path: project.full_path,
        active: false,
        name: 'New HTTP Integration',
        type: 'PROMETHEUS'
      }
    end

    it_behaves_like 'creating a new HTTP integration', 'PROMETHEUS'
  end

  context 'with invalid type argument' do
    let(:variables) do
      {
        project_path: project.full_path,
        active: false,
        name: 'New HTTP Integration',
        type: 'UNKNOWN'
      }
    end

    it_behaves_like 'an invalid argument to the mutation', argument_name: :type
  end

  [:project_path, :active, :name].each do |argument|
    context "without required argument #{argument}" do
      before do
        variables.delete(argument)
      end

      it_behaves_like 'an invalid argument to the mutation', argument_name: argument
    end
  end
end
