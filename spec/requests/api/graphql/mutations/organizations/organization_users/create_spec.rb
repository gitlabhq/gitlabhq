# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Mutations::Organizations::OrganizationUsers::Create, feature_category: :organization do
  include GraphqlHelpers

  let_it_be(:current_user) { create(:admin) }
  let_it_be(:organization) { create(:organization) }
  let_it_be(:user) { create(:user) }

  let(:user_type) { 'ADMIN' }
  let(:params) do
    {
      organization_id: organization.to_global_id.to_s,
      username: user.username,
      user_type: user_type
    }
  end

  let(:mutation) do
    graphql_mutation(:organization_user_create, params, <<~FIELDS)
      errors
      organizationUser {
        accessLevel { stringValue }
        user { username }
      }
    FIELDS
  end

  subject(:create_organization_user) { post_graphql_mutation(mutation, current_user: current_user) }

  it { expect(described_class).to require_graphql_authorizations(:create_organization_user) }

  it_behaves_like 'authorizing granular token permissions for GraphQL', :create_organization_user do
    let(:user) { current_user }
    let(:boundary_object) { :instance }
    let(:mutation) { graphql_mutation(:organization_user_create, params, 'errors') }
    let(:request) { post_graphql_mutation(mutation, token: { personal_access_token: pat }) }
  end

  def mutation_response
    graphql_mutation_response(:organization_user_create)
  end

  def added_username
    graphql_data_at(:organization_user_create, :organization_user, :user, :username)
  end

  context 'when the user does not have permission' do
    let_it_be(:current_user) { create(:user) }

    it_behaves_like 'a mutation that returns a top-level access error'

    it 'does not add the user to the organization' do
      expect { create_organization_user }.not_to change { organization.organization_users.count }
    end
  end

  context 'when the user has permission' do
    it 'adds the user by username' do
      create_organization_user

      expect(mutation_response['errors']).to be_empty
      expect(added_username).to eq(user.username)
      expect(graphql_data_at(:organization_user_create, :organization_user, :access_level, :string_value))
        .to eq('OWNER')
    end

    context 'when adding by email' do
      let(:params) do
        {
          organization_id: organization.to_global_id.to_s,
          email: user.email,
          user_type: user_type
        }
      end

      it 'adds the user' do
        create_organization_user

        expect(mutation_response['errors']).to be_empty
        expect(added_username).to eq(user.username)
      end
    end

    context 'when the identifier does not match a user' do
      let(:params) do
        {
          organization_id: organization.to_global_id.to_s,
          username: 'nonexistent-username',
          user_type: user_type
        }
      end

      it 'returns a user not found error' do
        create_organization_user

        expect(mutation_response['errors']).to contain_exactly('The user could not be found')
      end
    end

    context 'when the user is already part of the organization' do
      before do
        create(:organization_user, organization: organization, user: user)
      end

      it 'returns an already a member error' do
        create_organization_user

        expect(mutation_response['errors']).to contain_exactly('The user is already a member of the organization')
      end
    end

    context 'when neither username nor email is given' do
      let(:params) do
        {
          organization_id: organization.to_global_id.to_s,
          user_type: user_type
        }
      end

      it 'returns an argument error' do
        create_organization_user

        expect(graphql_errors)
          .to include(a_hash_including('message' => a_string_including('One and only one of [username, email]')))
      end
    end

    context 'when the organization does not exist' do
      let(:params) do
        super().merge(
          organization_id: global_id_of(id: non_existing_record_id, model_name: 'Organizations::Organization').to_s
        )
      end

      it_behaves_like 'a mutation that returns a top-level access error'
    end

    context 'when the request is rate limited' do
      it 'returns an error' do
        expect(Gitlab::ApplicationRateLimiter).to receive(:throttled?)
          .with(:organization_user_create, scope: [current_user]).and_return(true)

        create_organization_user

        expect(graphql_errors).to contain_exactly(
          hash_including(
            'message' => 'This endpoint has been requested too many times. Try again later.'
          )
        )
      end
    end
  end
end
