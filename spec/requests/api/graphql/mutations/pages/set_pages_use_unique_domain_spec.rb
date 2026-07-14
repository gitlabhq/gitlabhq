# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Mutations::Pages::SetPagesUseUniqueDomain, feature_category: :pages do
  include GraphqlHelpers

  let_it_be(:project) { create(:project, :public) }
  let_it_be(:developer) { create(:user, developer_of: project) }
  let_it_be(:owner) { create(:user, owner_of: project) }

  let(:project_path) { project.full_path }
  let(:value) { true }
  let(:mutation) do
    <<~GRAPHQL
      mutation SetPagesUseUniqueDomain {
        setPagesUseUniqueDomain(input: { projectPath: "#{project_path}", value: #{value} }) {
          errors
        }
      }
    GRAPHQL
  end

  describe 'granular token authorization' do
    let(:current_user) { owner }

    before do
      stub_pages_setting(enabled: true)
      project.reload.project_setting.update!(
        pages_unique_domain_enabled: false, pages_unique_domain: 'test-domain'
      )
    end

    it_behaves_like 'authorizing granular token permissions for GraphQL', :update_page do
      let(:user) { current_user }
      let(:boundary_object) { project }
      let(:request) { post_graphql(mutation, token: { personal_access_token: pat }) }
    end
  end
end
