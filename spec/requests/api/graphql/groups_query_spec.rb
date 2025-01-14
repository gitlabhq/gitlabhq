# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'searching groups', :with_license, feature_category: :groups_and_projects do
  include GraphqlHelpers
  using RSpec::Parameterized::TableSyntax

  let_it_be(:user) { create(:user) }
  let_it_be(:public_group) { create(:group, :public, name: 'Group A') }
  let_it_be(:private_group) { create(:group, :private, name: 'Group B') }
  let(:current_user) { user }

  let(:fields) do
    <<~FIELDS
      nodes {
        #{all_graphql_fields_for('Group', excluded: %w[runners ciQueueingHistory])}
      }
    FIELDS
  end

  let(:query) do
    <<~QUERY
      query {
        groups {
          #{fields}
        }
      }
    QUERY
  end

  subject { post_graphql(query, current_user: user) }

  describe "Query groups(search)" do
    let(:groups) { graphql_data_at(:groups, :nodes) }
    let(:names) { groups.map { |group| group["name"] } } # rubocop: disable Rails/Pluck

    it_behaves_like 'a working graphql query' do
      before do
        subject
      end
    end

    it 'includes public groups' do
      subject

      expect(names).to eq([public_group.name])
    end

    it 'includes accessible private groups ordered by name' do
      private_group.add_maintainer(user)

      subject

      expect(names).to eq([public_group.name, private_group.name])
    end

    context 'with `search` argument' do
      let_it_be(:other_group) { create(:group, name: 'other-group') }

      let(:query) do
        <<~QUERY
          query {
            groups(search: "oth") {
              #{fields}
            }
          }
        QUERY
      end

      it 'filters groups by name' do
        subject

        expect(names).to contain_exactly(other_group.name)
      end
    end

    context 'with `owned_only` argument' do
      let_it_be(:owned_group) { create(:group, name: 'with owner role', owners: user) }

      let(:query) do
        <<~QUERY
          query {
            groups(ownedOnly: true) {
              #{fields}
            }
          }
        QUERY
      end

      it 'return only owned groups' do
        subject

        expect(names).to contain_exactly(owned_group.name)
      end
    end
  end

  describe 'group sorting' do
    let_it_be(:public_group2) { create(:group, :public, name: 'Group C') }
    let_it_be(:public_group3) { create(:group, :public, name: 'Group D') }
    let_it_be(:all_groups) { [public_group, public_group2, public_group3] }
    let_it_be(:first_param) { 2 }
    let_it_be(:data_path) { [:groups] }

    where(:field, :direction, :sorted_groups) do
      'id'   | 'asc'  | lazy { all_groups.sort_by(&:id) }
      'id'   | 'desc' | lazy { all_groups.sort_by(&:id).reverse }
      'name' | 'asc'  | lazy { all_groups.sort_by(&:name) }
      'name' | 'desc' | lazy { all_groups.sort_by(&:name).reverse }
      'path' | 'asc'  | lazy { all_groups.sort_by(&:path) }
      'path' | 'desc' | lazy { all_groups.sort_by(&:path).reverse }
    end

    with_them do
      it_behaves_like 'sorted paginated query' do
        let(:sort_param) { "#{field}_#{direction}" }
        let(:all_records) { sorted_groups.map { |p| global_id_of(p).to_s } }
      end
    end

    def pagination_query(params)
      graphql_query_for(
        '', {},
        query_nodes(:groups, :id, include_pagination_info: true, args: params)
      )
    end
  end
end
