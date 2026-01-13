# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Project.customAttributes', feature_category: :groups_and_projects do
  include GraphqlHelpers

  let_it_be(:admin) { create(:admin) }
  let_it_be(:user) { create(:user) }
  let_it_be(:project) { create(:project, :public) }
  let_it_be(:custom_attribute1) do
    create(:project_custom_attribute, project: project, key: 'department', value: 'engineering')
  end

  let_it_be(:custom_attribute2) { create(:project_custom_attribute, project: project, key: 'priority', value: 'high') }

  let(:query) do
    %(
      query {
        project(fullPath: "#{project.full_path}") {
          customAttributes {
            key
            value
          }
        }
      }
    )
  end

  subject(:post_graphql_request) { post_graphql(query, current_user: current_user) }

  context 'when user is not an admin' do
    let(:current_user) { user }

    it 'returns null for custom_attributes' do
      post_graphql_request

      expect(graphql_data_at(:project, :customAttributes)).to be_nil
    end
  end

  context 'when user is an admin', :enable_admin_mode do
    let(:current_user) { admin }

    it 'returns custom attributes' do
      post_graphql_request

      expect(graphql_data_at(:project, :customAttributes)).to contain_exactly(
        { 'key' => 'department', 'value' => 'engineering' },
        { 'key' => 'priority', 'value' => 'high' }
      )
    end

    context 'when project has no custom attributes' do
      let_it_be(:empty_project) { create(:project, :public) }

      let(:query) do
        %(
          query {
            project(fullPath: "#{empty_project.full_path}") {
              customAttributes {
                key
                value
              }
            }
          }
        )
      end

      it 'returns an empty array' do
        post_graphql_request

        expect(graphql_data_at(:project, :customAttributes)).to eq([])
      end
    end
  end
end
