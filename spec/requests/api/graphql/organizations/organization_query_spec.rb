# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'getting organization information', feature_category: :cell do
  include GraphqlHelpers

  let(:query) { graphql_query_for(:organization, { id: organization.to_global_id }, organization_fields) }
  let(:current_user) { user }
  let(:groups) { graphql_data_at(:organization, :groups, :edges, :node) }
  let(:organization_fields) do
    <<~FIELDS
      id
      path
      groups {
        edges {
          node {
            id
          }
        }
      }
    FIELDS
  end

  let_it_be(:organization_user) { create(:organization_user) }
  let_it_be(:organization) { organization_user.organization }
  let_it_be(:user) { organization_user.user }
  let_it_be(:public_group) { create(:group, name: 'public-group', organization: organization) }
  let_it_be(:other_group) { create(:group, name: 'other-group', organization: organization) }
  let_it_be(:outside_organization_group) { create(:group) }

  let_it_be(:private_group) do
    create(:group, :private, name: 'private-group', organization: organization)
  end

  let_it_be(:no_access_group_in_org) do
    create(:group, :private, name: 'no-access', organization: organization)
  end

  before_all do
    private_group.add_developer(user)
    public_group.add_developer(user)
    other_group.add_developer(user)
    outside_organization_group.add_developer(user)
  end

  subject(:request_organization) { post_graphql(query, current_user: current_user) }

  context 'when the user does not have access to the organization' do
    let(:current_user) { create(:user) }

    it 'returns the organization as all organizations are public' do
      request_organization

      expect(graphql_data['organization']['id']).to eq(organization.to_global_id.to_s)
    end
  end

  context 'when user has access to the organization' do
    it_behaves_like 'a working graphql query' do
      before do
        request_organization
      end
    end

    context 'when resolve_organization_groups feature flag is disabled' do
      before do
        stub_feature_flags(resolve_organization_groups: false)
      end

      it 'returns no groups' do
        request_organization

        expect(graphql_data['organization']).not_to be_nil
        expect(graphql_data['organization']['groups']['edges']).to be_empty
      end
    end

    context 'with `search` argument' do
      let(:search) { 'oth' }
      let(:organization_fields) do
        <<~FIELDS
          id
          path
          groups(search: "#{search}") {
            edges {
              node {
                id
                name
              }
            }
          }
        FIELDS
      end

      it 'filters groups by name' do
        request_organization

        expect(groups).to contain_exactly(a_graphql_entity_for(other_group))
      end
    end

    context 'with `sort` argument' do
      using RSpec::Parameterized::TableSyntax

      let(:authorized_groups) { [public_group, private_group, other_group] }

      where(:field, :direction, :sorted_groups) do
        'id'         | 'asc'  | lazy { authorized_groups.sort_by(&:id) }
        'id'         | 'desc' | lazy { authorized_groups.sort_by(&:id).reverse }
        'name'       | 'asc'  | lazy { authorized_groups.sort_by(&:name) }
        'name'       | 'desc' | lazy { authorized_groups.sort_by(&:name).reverse }
        'path'       | 'asc'  | lazy { authorized_groups.sort_by(&:path) }
        'path'       | 'desc' | lazy { authorized_groups.sort_by(&:path).reverse }
      end

      with_them do
        let(:sort) { "#{field}_#{direction}".upcase }
        let(:organization_fields) do
          <<~FIELDS
            id
            path
            groups(sort: #{sort}) {
              edges {
                node {
                  id
                }
              }
            }
          FIELDS
        end

        it 'sorts the groups' do
          request_organization

          expect(groups.pluck('id')).to eq(sorted_groups.map(&:to_global_id).map(&:to_s))
        end
      end
    end
  end
end
