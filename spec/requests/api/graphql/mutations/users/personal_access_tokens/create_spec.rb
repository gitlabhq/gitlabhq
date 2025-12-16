# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Create personal access token with granular scopes', feature_category: :permissions do
  using RSpec::Parameterized::TableSyntax
  include GraphqlHelpers

  let_it_be(:current_user) { create(:user, :with_namespace) }
  let_it_be(:group) { create(:group, developers: [current_user]) }
  let_it_be(:project) { create(:project, developers: [current_user]) }

  let_it_be(:user_namespace_id) { current_user.namespace.id }
  let_it_be(:project_namespace_id) { project.project_namespace.id }
  let_it_be(:group_id) { group.id }
  let_it_be(:group_global_id) { group.to_global_id.to_s }
  let_it_be(:project_global_id) { project.to_global_id.to_s }

  let(:granular_scope_input) { [{ 'access' => 'USER', 'permissions' => ['read_job'] }] }

  let(:input) do
    {
      'name' => 'My Token',
      'description' => 'Token description',
      'expiresAt' => (Time.zone.today + 30).to_s,
      'granularScopes' => granular_scope_input
    }
  end

  let_it_be(:token) do
    { personal_access_token: create(:personal_access_token, user: current_user, scopes: %w[api]) }
  end

  let(:mutation) { graphql_mutation(:personalAccessTokenCreate, input) }
  let(:mutation_request) { post_graphql_mutation(mutation, current_user:, token:) }

  shared_examples 'creates a personal access token and granular scopes with correct attributes' do
    specify do
      expect { mutation_request }.to change { current_user.personal_access_tokens.count }.by(1)

      expect(graphql_errors).to be_nil

      expect(graphql_data_at(:personalAccessTokenCreate, :token)).to include(
        'name' => input['name'],
        'description' => input['description'],
        'expiresAt' => input['expiresAt'],
        'granular' => true
      )

      created_token = current_user.personal_access_tokens.last
      expect(created_token.granular_scopes.count).to eq(expected_granular_scope_attrs.size)
      expect(created_token.granular_scopes.map(&:attributes)).to include(
        *expected_granular_scope_attrs.map { |attrs| a_hash_including(attrs.stringify_keys) }
      )
    end
  end

  where(:granular_scope_input, :expected_granular_scope_attrs) do
    # user permissions
    [{ access: 'USER', permissions: ['read_job'] }] |
      [{ access: 'user', namespace_id: nil, permissions: ['read_job'] }]
    # instance permissions
    [{ access: 'INSTANCE', permissions: ['read_job'] }] |
      [{ access: 'instance', namespace_id: nil, permissions: ['read_job'] }]
    # permissions for the user's personal projects
    [{ access: 'PERSONAL_PROJECTS', permissions: ['read_job'] }] |
      [{ access: 'personal_projects', namespace_id: ref(:user_namespace_id), permissions: ['read_job'] }]
    # permissions for all memberships of the user
    [{ access: 'ALL_MEMBERSHIPS', permissions: ['read_job'] }] |
      [{ access: 'all_memberships', namespace_id: nil, permissions: ['read_job'] }]
    # permissions for selected memberships of the user
    [{ access: 'SELECTED_MEMBERSHIPS', permissions: ['read_job'],
       resource_ids: [ref(:group_global_id), ref(:project_global_id)] }] |
      [{ access: 'selected_memberships', namespace_id: ref(:group_id), permissions: ['read_job'] },
        { access: 'selected_memberships', namespace_id: ref(:project_namespace_id), permissions: ['read_job'] }]
    # multiple granularScopes input
    [
      { access: 'INSTANCE', permissions: ['retry_job'] },
      { access: 'USER', permissions: ['play_job'] },
      { access: 'SELECTED_MEMBERSHIPS', permissions: ['read_job'],
        resource_ids: [ref(:group_global_id), ref(:project_global_id)] }
    ] |
      [
        { access: 'instance', namespace_id: nil, permissions: ['retry_job'] },
        { access: 'user', namespace_id: nil, permissions: ['play_job'] },
        { access: 'selected_memberships', namespace_id: ref(:group_id), permissions: ['read_job'] },
        { access: 'selected_memberships', namespace_id: ref(:project_namespace_id), permissions: ['read_job'] }
      ]
  end

  with_them do
    it_behaves_like 'creates a personal access token and granular scopes with correct attributes'
  end

  context 'when resource_ids do not match a group or project' do
    let(:non_existing_resource_id) { Gitlab::GlobalId.build(model_name: 'Group', id: non_existing_record_id).to_s }
    let(:granular_scope_input) do
      [{ 'access' => 'SELECTED_MEMBERSHIPS', 'permissions' => ['read_job'],
         'resource_ids' => [non_existing_resource_id] }]
    end

    it 'returns a resource not available error' do
      expect { mutation_request }.not_to change { current_user.personal_access_tokens.count }

      expect_graphql_errors_to_include(
        "The resource that you are attempting to access does not exist " \
          "or you don't have permission to perform this action"
      )
    end
  end

  context 'when granular scopes include groups or projects the user is not a member of' do
    let(:other_group) { create(:group) }
    let(:granular_scope_input) do
      [{ 'access' => 'SELECTED_MEMBERSHIPS', 'permissions' => ['read_job'],
         'resource_ids' => [other_group.to_global_id.to_s] }]
    end

    it 'returns an error' do
      expect { mutation_request }.not_to change { current_user.personal_access_tokens.count }

      expect_graphql_errors_to_include(
        "The resource that you are attempting to access does not exist " \
          "or you don't have permission to perform this action"
      )
    end
  end

  context 'when token creation fails' do
    before do
      allow_next_instance_of(::PersonalAccessTokens::CreateService) do |instance|
        allow(instance).to receive(:execute).and_return(ServiceResponse.error(message: 'Token creation failed'))
      end
    end

    it 'returns errors' do
      mutation_request

      expect(graphql_data_at(:personalAccessTokenCreate, :errors)).to contain_exactly("Token creation failed")
      expect(graphql_data_at(:personalAccessTokenCreate, :token)).to be_nil
    end
  end

  context 'when adding granular scopes to the token fails' do
    before do
      allow_next_instance_of(::Authz::GranularScopeService) do |instance|
        error = ServiceResponse.error(message: 'Adding granular scopes failed')
        allow(instance).to receive(:add_granular_scopes).and_return(error)
      end
    end

    it 'returns errors' do
      mutation_request

      expect(graphql_data_at(:personalAccessTokenCreate, :errors)).to contain_exactly("Adding granular scopes failed")
      expect(graphql_data_at(:personalAccessTokenCreate, :token)).to be_nil
    end
  end

  context 'when the granular_personal_access_tokens feature flag is disabled' do
    before do
      stub_feature_flags(granular_personal_access_tokens: false)
    end

    it 'returns a resource not available error' do
      expect { mutation_request }.not_to change { current_user.personal_access_tokens.count }

      expect_graphql_errors_to_include("`granular_personal_access_tokens` feature flag is disabled.")
    end
  end
end
