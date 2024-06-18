# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Mutations::Boards::Create, feature_category: :portfolio_management do
  let_it_be(:parent) { create(:project) }
  let_it_be(:current_user, reload: true) { create(:user) }

  let(:name) { 'board name' }
  let(:mutation) { graphql_mutation(:create_board, params) }

  subject { post_graphql_mutation(mutation, current_user: current_user) }

  def mutation_response
    graphql_mutation_response(:create_board)
  end

  let(:project_path) { parent.full_path }
  let(:params) do
    {
      project_path: project_path,
      name: name
    }
  end

  it_behaves_like 'boards create mutation'
end
