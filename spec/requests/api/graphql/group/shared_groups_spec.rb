# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Query.group.sharedGroups', feature_category: :groups_and_projects do
  include GraphqlHelpers

  let_it_be(:user) { create(:user) }
  let_it_be(:user_2) { create(:user) }
  let_it_be(:group) { create(:group, :public, owners: user, name: "group") }
  let_it_be(:shared_group) { create(:group, :private, name: "shared group 1 foo") }
  let_it_be(:shared_group_2) { create(:group, :private, name: "shared group 2 bar") }
  let_it_be(:shared_group_3) { create(:group, :private, name: "shared group 3 bar") }
  let_it_be(:group_group_link) { create(:group_group_link, shared_group: shared_group, shared_with_group: group) }
  let_it_be(:group_group_link_2) { create(:group_group_link, shared_group: shared_group_2, shared_with_group: group) }
  let_it_be(:group_group_link_3) { create(:group_group_link, shared_group: shared_group_3, shared_with_group: group) }

  let(:current_user) { user }
  let(:shared_groups_args) { {} }
  let(:fields) do
    <<~QUERY
    nodes {
      #{all_graphql_fields_for('Group')}
    }
    QUERY
  end

  let(:query) do
    graphql_query_for(
      'group',
      { 'fullPath' => group.full_path },
      query_graphql_field('sharedGroups', shared_groups_args, fields)
    )
  end

  subject(:result) do
    post_graphql(query, current_user: current_user)

    graphql_data_at('group', 'shared_groups', 'nodes')
  end

  it 'returns shared groups' do
    expect(result).to contain_exactly(
      a_graphql_entity_for(shared_group),
      a_graphql_entity_for(shared_group_2),
      a_graphql_entity_for(shared_group_3)
    )
  end

  context 'when searching' do
    let(:shared_groups_args) { { search: 'foo' } }

    it 'only returns shared groups that match the search term' do
      expect(result).to contain_exactly(a_graphql_entity_for(shared_group))
    end
  end

  context 'when sorting' do
    using RSpec::Parameterized::TableSyntax

    where(:sort, :expected_groups) do
      :NAME_ASC | [ref(:shared_group), ref(:shared_group_2), ref(:shared_group_3)]
      :NAME_DESC | [ref(:shared_group_3), ref(:shared_group_2), ref(:shared_group)]
      :PATH_ASC | [ref(:shared_group), ref(:shared_group_2), ref(:shared_group_3)]
      :PATH_DESC | [ref(:shared_group_3), ref(:shared_group_2), ref(:shared_group)]
      :ID_ASC | [ref(:shared_group), ref(:shared_group_2), ref(:shared_group_3)]
      :ID_DESC | [ref(:shared_group_3), ref(:shared_group_2), ref(:shared_group)]
      :CREATED_AT_ASC | [ref(:shared_group), ref(:shared_group_2), ref(:shared_group_3)]
      :CREATED_AT_DESC | [ref(:shared_group_3), ref(:shared_group_2), ref(:shared_group)]
      :UPDATED_AT_ASC | [ref(:shared_group), ref(:shared_group_2), ref(:shared_group_3)]
      :UPDATED_AT_DESC | [ref(:shared_group_3), ref(:shared_group_2), ref(:shared_group)]
    end

    with_them do
      it "orders correctly" do
        query_with_sort = graphql_query_for(
          'group',
          { 'fullPath' => group.full_path },
          query_graphql_field('sharedGroups', { sort: sort }, fields)
        )
        post_graphql(query_with_sort, current_user: current_user)

        expect(
          graphql_data_at('group', 'shared_groups', 'nodes', 'id')
        ).to eq(expected_groups.map { |group| group.to_global_id.to_s })
      end
    end

    context 'when sorting by similarity' do
      context 'when searching' do
        let(:shared_groups_args) { { search: 'shared group 3 bar', sort: :SIMILARITY } }

        it 'sorts by similarity score' do
          post_graphql(query, current_user: current_user)

          expect(graphql_data_at('group', 'shared_groups', 'nodes', 'id')).to eq([
            shared_group_3.to_global_id.to_s,
            shared_group_2.to_global_id.to_s
          ])
        end
      end

      context 'when not searching' do
        let(:shared_groups_args) { { sort: :SIMILARITY } }

        it 'sorts by name_asc' do
          post_graphql(query, current_user: current_user)

          expect(graphql_data_at('group', 'shared_groups', 'nodes', 'id')).to eq([
            shared_group_3.to_global_id.to_s,
            shared_group_2.to_global_id.to_s,
            shared_group.to_global_id.to_s
          ])
        end
      end
    end
  end

  context 'when the user does not have permission to read the group' do
    let(:current_user) { user_2 }

    it 'returns no groups' do
      expect(result).to be_empty
    end
  end
end
