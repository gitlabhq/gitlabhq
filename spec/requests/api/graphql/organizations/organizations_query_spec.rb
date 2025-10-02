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
  let_it_be(:public_organizations) { create_list(:organization, 3, :public) }
  let_it_be(:organization) { public_organizations.first }
  let_it_be(:user) { create(:admin, organization: organization, organizations: [organization]) }

  subject(:request_organization) { post_graphql(query, current_user: current_user) }

  context 'without authenticated user' do
    let(:current_user) { nil }

    it_behaves_like 'a working graphql query' do
      before do
        request_organization
      end
    end
  end

  context 'with authenticated user' do
    let(:current_user) { user }

    it_behaves_like 'a working graphql query' do
      before do
        request_organization
      end
    end

    it_behaves_like 'sorted paginated query' do
      include_context 'no sort argument'

      let(:first_param) { 2 }
      let(:data_path) { [:organizations] }
      let(:all_records) do
        Organizations::Organization
          .order(id: :desc).map { |o| global_id_of(o).to_s }
      end
    end

    def pagination_query(params)
      graphql_query_for(:organizations, params, "#{page_info} nodes { id }")
    end
  end

  describe 'search' do
    let(:current_user) { user }
    let(:params) { { search: private_organization.name } }

    it 'returns matching organization' do
      request_organization

      expect(organizations).to contain_exactly(a_graphql_entity_for(private_organization))
    end
  end
end
