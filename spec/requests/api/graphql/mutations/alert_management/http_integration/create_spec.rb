# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Creating a new HTTP Integration' do
  include GraphqlHelpers

  let_it_be(:current_user) { create(:user) }
  let_it_be(:project) { create(:project) }

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

  before do
    project.add_maintainer(current_user)
  end

  it_behaves_like 'creating a new HTTP integration'

  [:project_path, :active, :name].each do |argument|
    context "without required argument #{argument}" do
      before do
        variables.delete(argument)
      end

      it_behaves_like 'an invalid argument to the mutation', argument_name: argument
    end
  end
end
