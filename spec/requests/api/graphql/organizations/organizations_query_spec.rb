# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'getting organizations information', feature_category: :organization do
  include GraphqlHelpers

  let(:params) { {} }
  let(:query) { graphql_query_for(:organizations, params, organizations_fields) }
  let(:organizations) { graphql_data_at(:organizations, :nodes) }
  let(:organizations_fields) do
    <<~FIELDS
      nodes {
        id
        path
      }
      count
    FIELDS
  end

  let_it_be(:private_organization) { create(:organization, :private, name: 'Private Organization') }
  let_it_be(:user_organization) { create(:organization, :private, name: 'User Organization') }
  let_it_be(:user) { create(:user, organization: user_organization, organizations: [user_organization]) }

  subject(:request_organization) { post_graphql(query, current_user: current_user) }

  it_behaves_like 'authorizing granular token permissions for GraphQL', :read_organization do
    let(:boundary_object) { :instance }
    let(:request) { post_graphql(query, token: { personal_access_token: pat }) }
  end

  context 'without authenticated user' do
    let(:current_user) { nil }

    it_behaves_like 'a working graphql query' do
      before do
        request_organization
      end
    end

    it 'returns public organizations' do
      request_organization

      expected_ids = [current_organization]
        .map { |o| global_id_of(o).to_s }
      expect(organizations.pluck('id')).to match_array(expected_ids)
    end
  end

  context 'with admin', :enable_admin_mode do
    let(:current_user) { create(:admin) }

    it 'returns all organizations' do
      request_organization

      expected_ids = [private_organization, user_organization, current_organization]
        .map { |o| global_id_of(o).to_s }
      expect(organizations.pluck('id')).to match_array(expected_ids)
    end
  end

  context 'with authenticated user' do
    let(:current_user) { user }

    it_behaves_like 'a working graphql query' do
      before do
        request_organization
      end
    end

    it 'returns organizations user has access to' do
      request_organization

      expected_ids = [user_organization, current_organization]
        .map { |o| global_id_of(o).to_s }
      expect(organizations.pluck('id')).to match_array(expected_ids)
    end

    it_behaves_like 'sorted paginated query' do
      include_context 'no sort argument'

      let(:first_param) { 2 }
      let(:data_path) { [:organizations] }
      let(:all_records) do
        Organizations::OrganizationsFinder.new(user).execute
          .order(id: :desc).map { |o| global_id_of(o).to_s }
      end
    end

    def pagination_query(params)
      graphql_query_for(:organizations, params, "#{page_info} nodes { id }")
    end
  end

  describe 'search' do
    let(:current_user) { user }
    let(:params) { { search: user_organization.name } }

    it 'returns matching organization' do
      request_organization

      expect(organizations).to contain_exactly(a_graphql_entity_for(user_organization))
    end

    context 'when user cannot access the private organization' do
      let(:params) { { search: private_organization.name } }

      it 'returns empty result' do
        request_organization

        expect(organizations).to be_empty
      end
    end
  end
end
