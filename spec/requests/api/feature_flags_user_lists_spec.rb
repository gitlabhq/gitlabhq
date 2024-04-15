# frozen_string_literal: true

require 'spec_helper'

RSpec.describe API::FeatureFlagsUserLists, feature_category: :feature_flags do
  let_it_be(:project, refind: true) { create(:project) }
  let_it_be(:client, refind: true) { create(:operations_feature_flags_client, project: project) }
  let_it_be(:developer) { create(:user, developer_of: project) }
  let_it_be(:reporter) { create(:user, reporter_of: project) }

  def create_list(name: 'mylist', user_xids: 'user1')
    create(:operations_feature_flag_user_list, project: project, name: name, user_xids: user_xids)
  end

  def disable_repository(project)
    project.project_feature.update!(
      repository_access_level: ::ProjectFeature::DISABLED,
      merge_requests_access_level: ::ProjectFeature::DISABLED,
      builds_access_level: ::ProjectFeature::DISABLED
    )
  end

  describe 'GET /projects/:id/feature_flags_user_lists' do
    it 'forbids the request for a reporter' do
      get api("/projects/#{project.id}/feature_flags_user_lists", reporter)

      expect(response).to have_gitlab_http_status(:forbidden)
    end

    it 'returns forbidden if the feature is unavailable' do
      disable_repository(project)

      get api("/projects/#{project.id}/feature_flags_user_lists", developer)

      expect(response).to have_gitlab_http_status(:forbidden)
    end

    it 'returns all the user lists' do
      create_list(name: 'list_a', user_xids: 'user1')
      create_list(name: 'list_b', user_xids: 'user1,user2,user3')

      get api("/projects/#{project.id}/feature_flags_user_lists", developer)

      expect(response).to have_gitlab_http_status(:ok)
      expect(json_response.map { |list| list['name'] }.sort).to eq(%w[list_a list_b])
    end

    it 'returns all the data for a user list' do
      user_list = create_list(name: 'list_a', user_xids: 'user1')

      get api("/projects/#{project.id}/feature_flags_user_lists", developer)

      expect(response).to have_gitlab_http_status(:ok)
      expect(json_response).to eq([{
        'id' => user_list.id,
        'iid' => user_list.iid,
        'project_id' => project.id,
        'created_at' => user_list.created_at.as_json,
        'updated_at' => user_list.updated_at.as_json,
        'name' => 'list_a',
        'user_xids' => 'user1',
        'path' => project_feature_flags_user_list_path(user_list.project, user_list),
        'edit_path' => edit_project_feature_flags_user_list_path(user_list.project, user_list)
      }])
    end

    it 'paginates user lists' do
      create_list(name: 'list_a', user_xids: 'user1')
      create_list(name: 'list_b', user_xids: 'user1,user2,user3')

      get api("/projects/#{project.id}/feature_flags_user_lists?page=2&per_page=1", developer)

      expect(response).to have_gitlab_http_status(:ok)
      expect(json_response.map { |list| list['name'] }).to eq(['list_b'])
    end

    it 'returns the user lists for only the specified project' do
      create(:operations_feature_flag_user_list, project: project, name: 'list')
      other_project = create(:project)
      create(:operations_feature_flag_user_list, project: other_project, name: 'other_list')

      get api("/projects/#{project.id}/feature_flags_user_lists", developer)

      expect(response).to have_gitlab_http_status(:ok)
      expect(json_response.map { |list| list['name'] }).to eq(['list'])
    end

    it 'returns an empty list' do
      get api("/projects/#{project.id}/feature_flags_user_lists", developer)

      expect(response).to have_gitlab_http_status(:ok)
      expect(json_response).to eq([])
    end

    context 'when filtering' do
      it 'returns lists matching the search term' do
        create_list(name: 'test_list', user_xids: 'user1')
        create_list(name: 'list_b', user_xids: 'user1,user2,user3')

        get api("/projects/#{project.id}/feature_flags_user_lists?search=test", developer)

        expect(response).to have_gitlab_http_status(:ok)
        expect(json_response.map { |list| list['name'] }).to eq(['test_list'])
      end

      it 'returns lists matching multiple search terms' do
        create_list(name: 'test_list', user_xids: 'user1')
        create_list(name: 'list_b', user_xids: 'user1,user2,user3')
        create_list(name: 'test_again', user_xids: 'user1,user2,user3')

        get api("/projects/#{project.id}/feature_flags_user_lists?search=test list", developer)

        expect(response).to have_gitlab_http_status(:ok)
        expect(json_response.map { |list| list['name'] }).to eq(['test_list'])
      end

      it 'returns all lists with no query' do
        create_list(name: 'list_a', user_xids: 'user1')
        create_list(name: 'list_b', user_xids: 'user1,user2,user3')

        get api("/projects/#{project.id}/feature_flags_user_lists?search=", developer)

        expect(response).to have_gitlab_http_status(:ok)
        expect(json_response.map { |list| list['name'] }.sort).to eq(%w[list_a list_b])
      end
    end
  end

  describe 'GET /projects/:id/feature_flags_user_lists/:iid' do
    it 'forbids the request for a reporter' do
      list = create_list

      get api("/projects/#{project.id}/feature_flags_user_lists/#{list.iid}", reporter)

      expect(response).to have_gitlab_http_status(:forbidden)
    end

    it 'returns forbidden if the feature is unavailable' do
      disable_repository(project)
      list = create_list

      get api("/projects/#{project.id}/feature_flags_user_lists/#{list.iid}", developer)

      expect(response).to have_gitlab_http_status(:forbidden)
    end

    it 'returns the user list' do
      list = create_list(name: 'testers', user_xids: 'test1,test2')

      get api("/projects/#{project.id}/feature_flags_user_lists/#{list.iid}", developer)

      expect(response).to have_gitlab_http_status(:ok)
      expect(json_response).to eq({
        'name' => 'testers',
        'user_xids' => 'test1,test2',
        'id' => list.id,
        'iid' => list.iid,
        'project_id' => project.id,
        'created_at' => list.created_at.as_json,
        'updated_at' => list.updated_at.as_json,
        'path' => project_feature_flags_user_list_path(list.project, list),
        'edit_path' => edit_project_feature_flags_user_list_path(list.project, list)
      })
    end

    it 'returns the correct user list identified by the iid' do
      create_list(name: 'list_a', user_xids: 'test1')
      list_b = create_list(name: 'list_b', user_xids: 'test2')

      get api("/projects/#{project.id}/feature_flags_user_lists/#{list_b.iid}", developer)

      expect(response).to have_gitlab_http_status(:ok)
      expect(json_response['name']).to eq('list_b')
    end

    it 'scopes the iid search to the project' do
      other_project = create(:project)
      other_project.add_developer(developer)
      create(:operations_feature_flag_user_list, project: other_project, name: 'other_list')
      list = create(:operations_feature_flag_user_list, project: project, name: 'list')

      get api("/projects/#{project.id}/feature_flags_user_lists/#{list.iid}", developer)

      expect(response).to have_gitlab_http_status(:ok)
      expect(json_response['name']).to eq('list')
    end

    it 'returns not found when the list does not exist' do
      get api("/projects/#{project.id}/feature_flags_user_lists/1", developer)

      expect(response).to have_gitlab_http_status(:not_found)
      expect(json_response).to eq({ 'message' => '404 Not found' })
    end
  end

  describe 'POST /projects/:id/feature_flags_user_lists' do
    it 'forbids the request for a reporter' do
      post api("/projects/#{project.id}/feature_flags_user_lists", reporter), params: {
        name: 'mylist', user_xids: 'user1'
      }

      expect(response).to have_gitlab_http_status(:forbidden)
      expect(project.operations_feature_flags_user_lists.count).to eq(0)
    end

    it 'returns forbidden if the feature is unavailable' do
      disable_repository(project)

      post api("/projects/#{project.id}/feature_flags_user_lists", developer), params: {
        name: 'mylist', user_xids: 'user1'
      }

      expect(response).to have_gitlab_http_status(:forbidden)
      expect(client.reload.last_feature_flag_updated_at).to be_nil
    end

    it 'creates the flag' do
      post api("/projects/#{project.id}/feature_flags_user_lists", developer), params: {
        name: 'mylist', user_xids: 'user1'
      }

      expect(response).to have_gitlab_http_status(:created)
      expect(json_response.slice('name', 'user_xids', 'project_id', 'iid')).to eq({
        'name' => 'mylist',
        'user_xids' => 'user1',
        'project_id' => project.id,
        'iid' => 1
      })
      expect(project.operations_feature_flags_user_lists.count).to eq(1)
      expect(project.operations_feature_flags_user_lists.last.name).to eq('mylist')
      expect(client.reload.last_feature_flag_updated_at).not_to be_nil
    end

    it 'requires name' do
      post api("/projects/#{project.id}/feature_flags_user_lists", developer), params: {
        user_xids: 'user1'
      }

      expect(response).to have_gitlab_http_status(:bad_request)
      expect(json_response).to eq({ 'message' => 'name is missing' })
      expect(project.operations_feature_flags_user_lists.count).to eq(0)
    end

    it 'requires user_xids' do
      post api("/projects/#{project.id}/feature_flags_user_lists", developer), params: {
        name: 'empty_list'
      }

      expect(response).to have_gitlab_http_status(:bad_request)
      expect(json_response).to eq({ 'message' => 'user_xids is missing' })
      expect(project.operations_feature_flags_user_lists.count).to eq(0)
    end

    it 'returns an error when name is already taken' do
      create_list(name: 'myname')
      post api("/projects/#{project.id}/feature_flags_user_lists", developer), params: {
        name: 'myname', user_xids: 'a'
      }

      expect(response).to have_gitlab_http_status(:bad_request)
      expect(json_response).to eq({ 'message' => ['Name has already been taken'] })
      expect(project.operations_feature_flags_user_lists.count).to eq(1)
    end

    it 'does not create a flag for a project of which the developer is not a member' do
      other_project = create(:project)

      post api("/projects/#{other_project.id}/feature_flags_user_lists", developer), params: {
        name: 'mylist', user_xids: 'user1'
      }

      expect(response).to have_gitlab_http_status(:not_found)
      expect(other_project.operations_feature_flags_user_lists.count).to eq(0)
      expect(project.operations_feature_flags_user_lists.count).to eq(0)
    end
  end

  describe 'PUT /projects/:id/feature_flags_user_lists/:iid' do
    it 'forbids the request for a reporter' do
      list = create_list(name: 'original_name')

      put api("/projects/#{project.id}/feature_flags_user_lists/#{list.iid}", reporter), params: {
        name: 'mylist'
      }

      expect(response).to have_gitlab_http_status(:forbidden)
      expect(list.reload.name).to eq('original_name')
    end

    it 'returns forbidden if the feature is unavailable' do
      list = create_list(name: 'original_name')
      disable_repository(project)

      put api("/projects/#{project.id}/feature_flags_user_lists/#{list.iid}", developer), params: {
        name: 'mylist', user_xids: '456,789'
      }

      expect(response).to have_gitlab_http_status(:forbidden)
      expect(client.reload.last_feature_flag_updated_at).to be_nil
    end

    it 'updates the list' do
      list = create_list(name: 'original_name', user_xids: '123')

      put api("/projects/#{project.id}/feature_flags_user_lists/#{list.iid}", developer), params: {
        name: 'mylist', user_xids: '456,789'
      }

      expect(response).to have_gitlab_http_status(:ok)
      expect(json_response.slice('name', 'user_xids')).to eq({
        'name' => 'mylist',
        'user_xids' => '456,789'
      })
      expect(list.reload.name).to eq('mylist')
      expect(client.reload.last_feature_flag_updated_at).not_to be_nil
    end

    it 'preserves attributes not listed in the request' do
      list = create_list(name: 'original_name', user_xids: '123')

      put api("/projects/#{project.id}/feature_flags_user_lists/#{list.iid}", developer), params: {}

      expect(response).to have_gitlab_http_status(:ok)
      expect(json_response.slice('name', 'user_xids')).to eq({
        'name' => 'original_name',
        'user_xids' => '123'
      })
      expect(list.reload.name).to eq('original_name')
      expect(list.reload.user_xids).to eq('123')
    end

    it 'returns an error when the update is invalid' do
      create_list(name: 'taken', user_xids: '123')
      list = create_list(name: 'original_name', user_xids: '123')

      put api("/projects/#{project.id}/feature_flags_user_lists/#{list.iid}", developer), params: {
        name: 'taken'
      }

      expect(response).to have_gitlab_http_status(:bad_request)
      expect(json_response).to eq({ 'message' => ['Name has already been taken'] })
    end

    it 'returns not found when the list does not exist' do
      list = create_list(name: 'original_name', user_xids: '123')

      put api("/projects/#{project.id}/feature_flags_user_lists/#{list.iid + 1}", developer), params: {
        name: 'new_name'
      }

      expect(response).to have_gitlab_http_status(:not_found)
      expect(json_response).to eq({ 'message' => '404 Not found' })
    end
  end

  describe 'DELETE /projects/:id/feature_flags_user_lists/:iid' do
    it 'forbids the request for a reporter' do
      list = create_list

      delete api("/projects/#{project.id}/feature_flags_user_lists/#{list.iid}", reporter)

      expect(response).to have_gitlab_http_status(:forbidden)
      expect(project.operations_feature_flags_user_lists.count).to eq(1)
    end

    it 'returns forbidden if the feature is unavailable' do
      list = create_list
      disable_repository(project)

      delete api("/projects/#{project.id}/feature_flags_user_lists/#{list.iid}", developer)

      expect(response).to have_gitlab_http_status(:forbidden)
    end

    it 'returns not found when the list does not exist' do
      delete api("/projects/#{project.id}/feature_flags_user_lists/1", developer)

      expect(response).to have_gitlab_http_status(:not_found)
      expect(json_response).to eq({ 'message' => '404 Not found' })
      expect(client.reload.last_feature_flag_updated_at).to be_nil
    end

    it 'deletes the list' do
      list = create_list

      delete api("/projects/#{project.id}/feature_flags_user_lists/#{list.iid}", developer)

      expect(response).to have_gitlab_http_status(:no_content)
      expect(response.body).to be_blank
      expect(project.operations_feature_flags_user_lists.count).to eq(0)
      expect(client.reload.last_feature_flag_updated_at).not_to be_nil
    end

    it 'does not delete the list if it is associated with a strategy' do
      list = create_list
      feature_flag = create(:operations_feature_flag, :new_version_flag, project: project)
      create(:operations_strategy, feature_flag: feature_flag, name: 'gitlabUserList', user_list: list)

      delete api("/projects/#{project.id}/feature_flags_user_lists/#{list.iid}", developer)

      expect(response).to have_gitlab_http_status(:conflict)
      expect(json_response).to eq({ 'message' => ['User list is associated with a strategy'] })
      expect(list.reload).to be_persisted
    end
  end
end
