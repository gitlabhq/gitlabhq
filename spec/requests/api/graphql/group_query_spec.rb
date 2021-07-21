# frozen_string_literal: true

require 'spec_helper'

# Based on spec/requests/api/groups_spec.rb
# Should follow closely in order to ensure all situations are covered
RSpec.describe 'getting group information' do
  include GraphqlHelpers
  include UploadHelpers

  let_it_be(:user1)         { create(:user, can_create_group: false) }
  let_it_be(:user2)         { create(:user) }
  let_it_be(:admin)         { create(:admin) }
  let_it_be(:private_group) { create(:group, :private) }
  let_it_be(:public_group)  { create(:group, :public) }

  # similar to the API "GET /groups/:id"
  describe "Query group(fullPath)" do
    def group_query(group)
      fields = all_graphql_fields_for('Group')
      # TODO: Set required timelogs args elsewhere https://gitlab.com/gitlab-org/gitlab/-/issues/325499
      fields.selection['timelogs(startDate: "2021-03-01" endDate: "2021-03-30")'] = fields.selection.delete('timelogs')

      graphql_query_for(
        'group',
        { fullPath: group.full_path },
        fields
      )
    end

    it_behaves_like 'a working graphql query' do
      before do
        post_graphql(group_query(public_group))
      end
    end

    context 'when unauthenticated' do
      it 'returns nil for a private group' do
        post_graphql(group_query(private_group))

        expect(graphql_data['group']).to be_nil
      end

      it 'returns a public group' do
        post_graphql(group_query(public_group))

        expect(graphql_data['group']).not_to be_nil
      end
    end

    context "when authenticated as user" do
      let!(:group1) { create(:group, avatar: File.open(uploaded_image_temp_path)) }
      let!(:group2) { create(:group, :private) }

      before do
        group1.add_owner(user1)
        group2.add_owner(user2)
      end

      it "returns one of user1's groups" do
        project = create(:project, namespace: group2, path: 'Foo')
        issue = create(:issue, project: create(:project, group: group1))
        create(:project_group_link, project: project, group: group1)

        post_graphql(group_query(group1), current_user: user1)

        expect(response).to have_gitlab_http_status(:ok)
        expect(graphql_data['group']['id']).to eq(group1.to_global_id.to_s)
        expect(graphql_data['group']['name']).to eq(group1.name)
        expect(graphql_data['group']['path']).to eq(group1.path)
        expect(graphql_data['group']['description']).to eq(group1.description)
        expect(graphql_data['group']['visibility']).to eq(Gitlab::VisibilityLevel.string_level(group1.visibility_level))
        expect(graphql_data['group']['avatarUrl']).to eq(group1.avatar_url(only_path: false))
        expect(graphql_data['group']['webUrl']).to eq(group1.web_url)
        expect(graphql_data['group']['requestAccessEnabled']).to eq(group1.request_access_enabled)
        expect(graphql_data['group']['fullName']).to eq(group1.full_name)
        expect(graphql_data['group']['fullPath']).to eq(group1.full_path)
        expect(graphql_data['group']['parentId']).to eq(group1.parent_id)
        expect(graphql_data['group']['issues']['nodes'].count).to eq(1)
        expect(graphql_data['group']['issues']['nodes'][0]['iid']).to eq(issue.iid.to_s)
      end

      it "does not return a non existing group" do
        query = graphql_query_for('group', 'fullPath' => '1328')

        post_graphql(query, current_user: user1)

        expect(graphql_data['group']).to be_nil
      end

      it "does not return a group not attached to user1" do
        private_group.add_owner(user2)

        post_graphql(group_query(private_group), current_user: user1)

        expect(graphql_data['group']).to be_nil
      end

      it 'avoids N+1 queries', :assume_throttled do
        pending('See: https://gitlab.com/gitlab-org/gitlab/-/issues/245272')

        queries = [{ query: group_query(group1) },
                   { query: group_query(group2) }]

        expect { post_multiplex(queries, current_user: admin) }
          .to issue_same_number_of_queries_as { post_graphql(group_query(group1), current_user: admin) }
      end

      context "when querying group's descendant groups" do
        let_it_be(:subgroup1) { create(:group, parent: public_group) }
        let_it_be(:subgroup2) { create(:group, parent: subgroup1) }

        let(:descendants) { [subgroup1, subgroup2] }

        it 'returns all descendant groups user has access to' do
          post_graphql(group_query(public_group), current_user: admin)

          names = graphql_data['group']['descendantGroups']['nodes'].map { |n| n['name'] }
          expect(names).to match_array(descendants.map(&:name))
        end
      end
    end

    context "when authenticated as admin" do
      it "returns any existing group" do
        post_graphql(group_query(private_group), current_user: admin)

        expect(graphql_data['group']['name']).to eq(private_group.name)
      end

      it "does not return a non existing group" do
        query = graphql_query_for('group', 'fullPath' => '1328')
        post_graphql(query, current_user: admin)

        expect(graphql_data['group']).to be_nil
      end
    end
  end
end
