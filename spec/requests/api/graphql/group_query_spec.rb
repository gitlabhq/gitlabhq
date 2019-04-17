require 'spec_helper'

# Based on spec/requests/api/groups_spec.rb
# Should follow closely in order to ensure all situations are covered
describe 'getting group information' do
  include GraphqlHelpers
  include UploadHelpers

  let(:user1)     { create(:user, can_create_group: false) }
  let(:user2)     { create(:user) }
  let(:admin)     { create(:admin) }
  let!(:group1)   { create(:group, avatar: File.open(uploaded_image_temp_path)) }
  let!(:group2)   { create(:group, :private) }
  # let!(:project1) { create(:project, namespace: group1) }
  # let!(:project2) { create(:project, namespace: group2) }
  # let!(:project3) { create(:project, namespace: group1, path: 'test', visibility_level: Gitlab::VisibilityLevel::PRIVATE) }

  before do
    group1.add_owner(user1)
    group2.add_owner(user2)
  end

  # similar to the API "GET /groups/:id"
  describe "Query group(fullPath)" do
    # Given a group, create one project for each visibility level
    #
    # group      - Group to add projects to
    # share_with - If provided, each project will be shared with this Group
    #
    # Returns a Hash of visibility_level => Project pairs
    def add_projects_to_group(group, share_with: nil)
      projects = {
          public:   create(:project, :public,   namespace: group),
          internal: create(:project, :internal, namespace: group),
          private:  create(:project, :private,  namespace: group)
      }

      if share_with
        create(:project_group_link, project: projects[:public],   group: share_with)
        create(:project_group_link, project: projects[:internal], group: share_with)
        create(:project_group_link, project: projects[:private],  group: share_with)
      end

      projects
    end

    def response_project_ids(json_response, key)
      json_response[key].map do |project|
        project['id'].to_i
      end
    end

    def group_query(group)
      graphql_query_for('group', 'fullPath' => group.full_path)
    end

    it_behaves_like 'a working graphql query' do
      before do
        post_graphql(group_query(group1))
      end
    end

    context 'when unauthenticated' do
      it 'returns nil for a private group' do
        post_graphql(group_query(group2))

        expect(graphql_data['group']).to be_nil
      end

      it 'returns a public group' do
        post_graphql(group_query(group1))

        expect(graphql_data['group']).not_to be_nil
      end

      # it 'returns only public projects in the group' do
      #   public_group = create(:group, :public)
      #   projects = add_projects_to_group(public_group)
      #
      #   get api("/groups/#{public_group.id}")
      #
      #   expect(response_project_ids(json_response, 'projects'))
      #       .to contain_exactly(projects[:public].id)
      # end

      # it 'returns only public projects shared with the group' do
      #   public_group = create(:group, :public)
      #   projects = add_projects_to_group(public_group, share_with: group1)
      #
      #   get api("/groups/#{group1.id}")
      #
      #   expect(response_project_ids(json_response, 'shared_projects'))
      #       .to contain_exactly(projects[:public].id)
      # end
    end

    context "when authenticated as user" do
      it "returns one of user1's groups" do
        project = create(:project, namespace: group2, path: 'Foo')
        create(:project_group_link, project: project, group: group1)

        post_graphql(group_query(group1), current_user: user1)

        expect(response).to have_gitlab_http_status(200)
        expect(graphql_data['group']['id']).to eq(group1.id.to_s)
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
        # expect(graphql_data['group']['projects']).to be_an Array
        # expect(graphql_data['group']['projects'].length).to eq(2)
        # expect(graphql_data['group']['sharedProjects']).to be_an Array
        # expect(graphql_data['group']['sharedProjects'].length).to eq(1)
        # expect(graphql_data['group']['sharedProjects'][0]['id']).to eq(project.id)
      end

      # it "returns one of user1's groups without projects when with_projects option is set to false" do
      #   project = create(:project, namespace: group2, path: 'Foo')
      #   create(:project_group_link, project: project, group: group1)
      #
      #   get api("/groups/#{group1.id}", user1), params: { with_projects: false }
      #
      #   expect(response).to have_gitlab_http_status(200)
      #   expect(json_response['projects']).to be_nil
      #   expect(json_response['shared_projects']).to be_nil
      # end

      it "does not return a non existing group" do
        query = graphql_query_for('group', 'fullPath' => '1328')
        post_graphql(query, current_user: user1)

        expect(graphql_data['group']).to be_nil
      end

      it "does not return a group not attached to user1" do
        post_graphql(group_query(group2), current_user: user1)

        expect(graphql_data['group']).to be_nil
      end

      # it 'returns only public and internal projects in the group' do
      #   public_group = create(:group, :public)
      #   projects = add_projects_to_group(public_group)
      #
      #   get api("/groups/#{public_group.id}", user2)
      #
      #   expect(response_project_ids(json_response, 'projects'))
      #       .to contain_exactly(projects[:public].id, projects[:internal].id)
      # end

      # it 'returns only public and internal projects shared with the group' do
      #   public_group = create(:group, :public)
      #   projects = add_projects_to_group(public_group, share_with: group1)
      #
      #   get api("/groups/#{group1.id}", user2)
      #
      #   expect(response_project_ids(json_response, 'shared_projects'))
      #       .to contain_exactly(projects[:public].id, projects[:internal].id)
      # end

      it 'avoids N+1 queries' do
        post_graphql(group_query(group1), current_user: admin)

        control_count = ActiveRecord::QueryRecorder.new do
          post_graphql(group_query(group1), current_user: admin)
        end.count

        create(:project, namespace: group1)

        expect do
          post_graphql(group_query(group1), current_user: admin)
        end.not_to exceed_query_limit(control_count)
      end
    end

    context "when authenticated as admin" do
      it "returns any existing group" do
        post_graphql(group_query(group2), current_user: admin)

        expect(graphql_data['group']['name']).to eq(group2.name)
      end

      it "does not return a non existing group" do
        query = graphql_query_for('group', 'fullPath' => '1328')
        post_graphql(query, current_user: admin)

        expect(graphql_data['group']).to be_nil
      end
    end
  end
end
