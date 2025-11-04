# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Query.accessTokenPermissions', feature_category: :permissions do
  include GraphqlHelpers

  let_it_be(:current_user) { create(:user) }

  let(:permission_source_file) { 'config/authz/permissions/member_role/read.yml' }
  let(:permission_definition) do
    {
      name: 'read_member_role',
      description: 'Grants the ability to read member roles',
      feature_category: 'system_access',
      available_for_tokens: true
    }
  end

  let(:mock_permission) { ::Authz::Permission.new(permission_definition, permission_source_file) }

  let(:query) do
    <<~GQL
      query {
        accessTokenPermissions {
          name
          description
          action
          resource
        }
      }
    GQL
  end

  let(:permissions_data) { graphql_data['accessTokenPermissions'] }

  before do
    allow(::Authz::Permission).to receive_messages(all_for_tokens: [mock_permission])
  end

  context 'when user is authenticated' do
    it 'returns expected fields' do
      post_graphql(query, current_user: current_user)

      expect(permissions_data).to eq([{
        'name' => 'read_member_role',
        'description' => 'Grants the ability to read member roles',
        'action' => 'read',
        'resource' => 'member_role'
      }])
    end
  end

  context 'when feature-flag `fine_grained_personal_access_tokens` is disabled' do
    before do
      stub_feature_flags(fine_grained_personal_access_tokens: false)
    end

    it 'returns an error' do
      post_graphql(query, current_user: current_user)

      expect_graphql_errors_to_include("The resource that you are attempting to access does not exist")
    end
  end
end
