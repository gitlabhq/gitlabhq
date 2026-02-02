# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Query.accessTokenPermissions', feature_category: :permissions do
  include GraphqlHelpers

  let_it_be(:current_user) { create(:user) }

  let(:target_permission) { ::Authz::PermissionGroups::Assignable.get(:update_wiki) }

  let(:resource) do
    resource_definition = {
      name: 'Wiki Resource',
      description: 'Pages that can be created, edited, and managed by team members'
    }
    ::Authz::PermissionGroups::Resource.new(resource_definition, 'source_file')
  end

  let(:category) do
    category_definition = { name: 'Wiki Category' }
    ::Authz::PermissionGroups::Category.new(category_definition, 'source_file')
  end

  let(:query) do
    <<~GQL
      query {
        accessTokenPermissions {
          name
          description
          action
          resource
          resourceName
          resourceDescription
          category
          categoryName
          boundaries
        }
      }
    GQL
  end

  let(:permissions_data) { graphql_data['accessTokenPermissions'] }

  before do
    allow(::Authz::PermissionGroups::Assignable).to receive(:all).and_return(
      target_permission.name => target_permission
    )

    allow(::Authz::PermissionGroups::Resource).to receive(:get)
      .with("#{target_permission.category}/#{target_permission.resource}").and_return(resource)

    allow(::Authz::PermissionGroups::Category).to receive(:get)
      .with(target_permission.category).and_return(category)
  end

  context 'when user is authenticated' do
    it 'returns expected fields' do
      post_graphql(query, current_user: current_user)

      expect(permissions_data).to eq([{
        'name' => 'update_wiki',
        'description' => 'Grants the ability to update wikis',
        'action' => 'update',
        'resource' => 'wiki',
        'resourceName' => 'Wiki Resource',
        'resourceDescription' => resource.definition[:description],
        'category' => 'wiki',
        'categoryName' => 'Wiki Category',
        'boundaries' => %w[GROUP PROJECT]
      }])
    end
  end

  context 'when feature-flag `granular_personal_access_tokens` is disabled' do
    before do
      stub_feature_flags(granular_personal_access_tokens: false)
    end

    it 'returns an error' do
      post_graphql(query, current_user: current_user)

      expect_graphql_errors_to_include("The resource that you are attempting to access does not exist")
    end
  end
end
