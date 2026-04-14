# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Mutations::Pages::MarkOnboardingComplete, feature_category: :pages do
  include GraphqlHelpers

  let_it_be(:project) { create(:project, :public, :repository) }
  let_it_be(:developer) { create(:user, developer_of: project) }
  let_it_be(:owner) { create(:user, owner_of: project) }

  let(:current_user) { owner }
  let(:mutation) do
    <<~GRAPHQL
      mutation PagesMarkOnboardingComplete {
        pagesMarkOnboardingComplete(input: { projectPath: "#{project_path}" }) {
          onboardingComplete
          errors
        }
      }
    GRAPHQL
  end

  let(:project_path) { project.full_path }

  describe 'granular token authorization' do
    let(:current_user) { owner }

    it_behaves_like 'authorizing granular token permissions for GraphQL', :update_page do
      let(:user) { current_user }
      let(:boundary_object) { project }
      let(:request) { post_graphql(mutation, token: { personal_access_token: pat }) }
    end
  end
end
