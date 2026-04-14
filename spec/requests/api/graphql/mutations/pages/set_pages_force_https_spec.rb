# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Mutations::Pages::SetPagesForceHttps, feature_category: :pages do
  include GraphqlHelpers

  let_it_be(:project) { create(:project, :public) }
  let_it_be(:developer) { create(:user, developer_of: project) }
  let_it_be(:owner) { create(:user, owner_of: project) }

  let(:project_path) { project.full_path }
  let(:value) { true }
  let(:mutation) do
    <<~GRAPHQL
      mutation SetPagesForceHttps {
        setPagesForceHttps(input: { projectPath: "#{project_path}", value: #{value} }) {
          errors
        }
      }
    GRAPHQL
  end

  describe 'granular token authorization' do
    let(:current_user) { owner }

    it_behaves_like 'authorizing granular token permissions for GraphQL', :update_page do
      let(:user) { current_user }
      let(:boundary_object) { project }
      let(:request) { post_graphql(mutation, token: { personal_access_token: pat }) }
    end
  end
end
