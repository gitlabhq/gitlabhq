# frozen_string_literal: true
require 'spec_helper'

RSpec.describe API::FeatureFlags, feature_category: :feature_flags do
  include FeatureFlagHelpers

  let_it_be(:project) { create(:project) }
  let_it_be(:developer) { create(:user, developer_of: project) }
  let_it_be(:reporter) { create(:user, reporter_of: project) }
  let_it_be(:non_project_member) { create(:user) }

  let(:user) { developer }

  shared_examples_for 'check user permission' do
    context 'when user is reporter' do
      let(:user) { reporter }

      it 'forbids the request' do
        subject

        expect(response).to have_gitlab_http_status(:forbidden)
      end
    end
  end

  shared_examples_for 'not found' do
    it 'returns Not Found' do
      subject

      expect(response).to have_gitlab_http_status(:not_found)
    end
  end

  describe 'GET /projects/:id/feature_flags' do
    subject { get api("/projects/#{project.id}/feature_flags", user) }

    context 'when there are two feature flags' do
      let!(:feature_flag_1) do
        create(:operations_feature_flag, project: project)
      end

      let!(:feature_flag_2) do
        create(:operations_feature_flag, project: project)
      end

      it 'returns feature flags ordered by name' do
        subject

        expect(response).to have_gitlab_http_status(:ok)
        expect(response).to match_response_schema('public_api/v4/feature_flags')
        expect(json_response.count).to eq(2)
        expect(json_response.first['name']).to eq(feature_flag_1.name)
        expect(json_response.second['name']).to eq(feature_flag_2.name)
      end

      it 'returns the legacy flag version' do
        subject

        expect(response).to have_gitlab_http_status(:ok)
        expect(response).to match_response_schema('public_api/v4/feature_flags')
        expect(json_response.map { |f| f['version'] }).to eq(%w[new_version_flag new_version_flag])
      end

      it 'does not have N+1 problem' do
        control = ActiveRecord::QueryRecorder.new { subject }

        create_list(:operations_feature_flag, 3, project: project)

        expect { get api("/projects/#{project.id}/feature_flags", user) }
          .not_to exceed_query_limit(control)
      end

      it_behaves_like 'check user permission'
    end

    context 'with version 2 feature flags' do
      let!(:feature_flag) do
        create(:operations_feature_flag, :new_version_flag, project: project, name: 'feature1')
      end

      let!(:strategy) do
        create(:operations_strategy, feature_flag: feature_flag, name: 'default', parameters: {})
      end

      let!(:scope) do
        create(:operations_scope, strategy: strategy, environment_scope: 'production')
      end

      it 'returns the feature flags' do
        subject

        expect(response).to have_gitlab_http_status(:ok)
        expect(response).to match_response_schema('public_api/v4/feature_flags')
        expect(json_response).to eq([{
          'name' => 'feature1',
          'description' => nil,
          'active' => true,
          'version' => 'new_version_flag',
          'updated_at' => feature_flag.updated_at.as_json,
          'created_at' => feature_flag.created_at.as_json,
          'scopes' => [],
          'strategies' => [{
            'id' => strategy.id,
            'name' => 'default',
            'parameters' => {},
            'scopes' => [{
              'id' => scope.id,
              'environment_scope' => 'production'
            }],
            'user_list' => nil
          }]
        }])
      end
    end

    context 'with user_list strategy feature flags' do
      let!(:feature_flag) do
        create(:operations_feature_flag, :new_version_flag, project: project, name: 'feature1')
      end

      let!(:user_list) do
        create(:operations_feature_flag_user_list, project: project)
      end

      let!(:strategy) do
        create(:operations_strategy, :gitlab_userlist, user_list: user_list, feature_flag: feature_flag, name: 'gitlabUserList', parameters: {})
      end

      let!(:scope) do
        create(:operations_scope, strategy: strategy, environment_scope: 'production')
      end

      it 'returns the feature flags', :aggregate_failures do
        subject

        expect(response).to have_gitlab_http_status(:ok)
        expect(response).to match_response_schema('public_api/v4/feature_flags')
        expect(json_response).to eq([{
          'name' => 'feature1',
          'description' => nil,
          'active' => true,
          'version' => 'new_version_flag',
          'updated_at' => feature_flag.updated_at.as_json,
          'created_at' => feature_flag.created_at.as_json,
          'scopes' => [],
          'strategies' => [{
            'id' => strategy.id,
            'name' => 'gitlabUserList',
            'parameters' => {},
            'scopes' => [{
              'id' => scope.id,
              'environment_scope' => 'production'
            }],
            'user_list' => {
              'id' => user_list.id,
              'iid' => user_list.iid,
              'name' => user_list.name,
              'user_xids' => user_list.user_xids
            }
          }]
        }])
      end
    end
  end

  describe 'GET /projects/:id/feature_flags/:name' do
    subject { get api("/projects/#{project.id}/feature_flags/#{feature_flag.name}", user) }

    context 'when there is a feature flag' do
      let!(:feature_flag) { create_flag(project, 'awesome-feature') }

      it 'returns a feature flag entry' do
        subject

        expect(response).to have_gitlab_http_status(:ok)
        expect(response).to match_response_schema('public_api/v4/feature_flag')
        expect(json_response['name']).to eq(feature_flag.name)
        expect(json_response['description']).to eq(feature_flag.description)
        expect(json_response['version']).to eq('new_version_flag')
      end

      it_behaves_like 'check user permission'
    end

    context 'with a version 2 feature_flag' do
      it 'returns the feature flag' do
        feature_flag = create(:operations_feature_flag, :new_version_flag, project: project, name: 'feature1')
        strategy = create(:operations_strategy, feature_flag: feature_flag, name: 'default', parameters: {})
        scope = create(:operations_scope, strategy: strategy, environment_scope: 'production')

        get api("/projects/#{project.id}/feature_flags/feature1", user)

        expect(response).to have_gitlab_http_status(:ok)
        expect(response).to match_response_schema('public_api/v4/feature_flag')
        expect(json_response).to eq({
          'name' => 'feature1',
          'description' => nil,
          'active' => true,
          'version' => 'new_version_flag',
          'updated_at' => feature_flag.updated_at.as_json,
          'created_at' => feature_flag.created_at.as_json,
          'scopes' => [],
          'strategies' => [{
            'id' => strategy.id,
            'name' => 'default',
            'parameters' => {},
            'scopes' => [{
              'id' => scope.id,
              'environment_scope' => 'production'
            }],
            'user_list' => nil
          }]
        })
      end
    end

    context 'with user_list strategy feature flag' do
      let!(:feature_flag) do
        create(:operations_feature_flag, :new_version_flag, project: project, name: 'feature1')
      end

      let(:user_list) do
        create(:operations_feature_flag_user_list, project: project)
      end

      let!(:strategy) do
        create(:operations_strategy, :gitlab_userlist, user_list: user_list, feature_flag: feature_flag, name: 'gitlabUserList', parameters: {})
      end

      let!(:scope) do
        create(:operations_scope, strategy: strategy, environment_scope: 'production')
      end

      it 'returns the feature flag', :aggregate_failures do
        subject

        expect(response).to have_gitlab_http_status(:ok)
        expect(response).to match_response_schema('public_api/v4/feature_flag')
        expect(json_response).to eq({
          'name' => 'feature1',
          'description' => nil,
          'active' => true,
          'version' => 'new_version_flag',
          'updated_at' => feature_flag.updated_at.as_json,
          'created_at' => feature_flag.created_at.as_json,
          'scopes' => [],
          'strategies' => [{
            'id' => strategy.id,
            'name' => 'gitlabUserList',
            'parameters' => {},
            'scopes' => [{
              'id' => scope.id,
              'environment_scope' => 'production'
            }],
            'user_list' => {
              'id' => user_list.id,
              'iid' => user_list.iid,
              'name' => user_list.name,
              'user_xids' => user_list.user_xids
            }
          }]
        })
      end
    end
  end

  describe 'POST /projects/:id/feature_flags' do
    subject do
      post api("/projects/#{project.id}/feature_flags", user), params: params
    end

    let(:params) do
      {
        name: 'awesome-feature'
      }
    end

    it 'creates a new feature flag' do
      subject

      expect(response).to have_gitlab_http_status(:created)
      expect(response).to match_response_schema('public_api/v4/feature_flag')

      feature_flag = project.operations_feature_flags.last
      expect(feature_flag.name).to eq(params[:name])
      expect(feature_flag.description).to eq(params[:description])
    end

    it 'defaults to a version 2 (new) feature flag' do
      subject

      expect(response).to have_gitlab_http_status(:created)
      expect(response).to match_response_schema('public_api/v4/feature_flag')

      feature_flag = project.operations_feature_flags.last
      expect(feature_flag.version).to eq('new_version_flag')
    end

    it_behaves_like 'check user permission'

    it 'returns version' do
      subject

      expect(response).to have_gitlab_http_status(:created)
      expect(response).to match_response_schema('public_api/v4/feature_flag')
      expect(json_response['version']).to eq('new_version_flag')
    end

    context 'when there is a feature flag with the same name already' do
      before do
        create_flag(project, 'awesome-feature')
      end

      it 'fails to create a new feature flag' do
        subject

        expect(response).to have_gitlab_http_status(:bad_request)
      end
    end

    context 'when creating a version 2 feature flag' do
      let(:user_list) do
        create(:operations_feature_flag_user_list, project: project)
      end

      it 'creates a new feature flag' do
        params = {
          name: 'new-feature',
          version: 'new_version_flag'
        }

        post api("/projects/#{project.id}/feature_flags", user), params: params

        expect(response).to have_gitlab_http_status(:created)
        expect(response).to match_response_schema('public_api/v4/feature_flag')
        expect(json_response).to match(hash_including({
          'name' => 'new-feature',
          'description' => nil,
          'active' => true,
          'version' => 'new_version_flag',
          'scopes' => [],
          'strategies' => []
        }))

        feature_flag = project.operations_feature_flags.last
        expect(feature_flag.name).to eq(params[:name])
        expect(feature_flag.version).to eq('new_version_flag')
      end

      it 'creates a new feature flag that is inactive' do
        params = {
          name: 'new-feature',
          version: 'new_version_flag',
          active: false
        }

        post api("/projects/#{project.id}/feature_flags", user), params: params

        expect(response).to have_gitlab_http_status(:created)
        expect(response).to match_response_schema('public_api/v4/feature_flag')
        expect(json_response['active']).to eq(false)

        feature_flag = project.operations_feature_flags.last
        expect(feature_flag.active).to eq(false)
      end

      it 'creates a new feature flag with strategies' do
        params = {
          name: 'new-feature',
          version: 'new_version_flag',
          strategies: [{
            name: 'userWithId',
            parameters: { userIds: 'user1' }
          }]
        }

        post api("/projects/#{project.id}/feature_flags", user), params: params

        expect(response).to have_gitlab_http_status(:created)
        expect(response).to match_response_schema('public_api/v4/feature_flag')

        feature_flag = project.operations_feature_flags.last
        expect(feature_flag.name).to eq(params[:name])
        expect(feature_flag.version).to eq('new_version_flag')
        expect(feature_flag.strategies.map { |s| s.slice(:name, :parameters).deep_symbolize_keys }).to eq([{
          name: 'userWithId',
          parameters: { userIds: 'user1' }
        }])
      end

      it 'creates a new feature flag with gradual rollout strategy with scopes' do
        params = {
          name: 'new-feature',
          version: 'new_version_flag',
          strategies: [{
            name: 'gradualRolloutUserId',
            parameters: { groupId: 'default', percentage: '50' },
            scopes: [{
              environment_scope: 'staging'
            }]
          }]
        }

        post api("/projects/#{project.id}/feature_flags", user), params: params

        expect(response).to have_gitlab_http_status(:created)
        expect(response).to match_response_schema('public_api/v4/feature_flag')

        feature_flag = project.operations_feature_flags.last
        expect(feature_flag.name).to eq(params[:name])
        expect(feature_flag.version).to eq('new_version_flag')
        expect(feature_flag.strategies.map { |s| s.slice(:name, :parameters).deep_symbolize_keys }).to eq([{
          name: 'gradualRolloutUserId',
          parameters: { groupId: 'default', percentage: '50' }
        }])
        expect(feature_flag.strategies.first.scopes.map { |s| s.slice(:environment_scope).deep_symbolize_keys }).to eq([{
          environment_scope: 'staging'
        }])
      end

      it 'creates a new feature flag with flexible rollout strategy with scopes' do
        params = {
          name: 'new-feature',
          version: 'new_version_flag',
          strategies: [{
            name: 'flexibleRollout',
            parameters: { groupId: 'default', rollout: '50', stickiness: 'default' },
            scopes: [{
              environment_scope: 'staging'
            }]
          }]
        }

        post api("/projects/#{project.id}/feature_flags", user), params: params

        expect(response).to have_gitlab_http_status(:created)
        expect(response).to match_response_schema('public_api/v4/feature_flag')

        feature_flag = project.operations_feature_flags.last
        expect(feature_flag.name).to eq(params[:name])
        expect(feature_flag.version).to eq('new_version_flag')
        expect(feature_flag.strategies.map { |s| s.slice(:name, :parameters).deep_symbolize_keys }).to eq([{
          name: 'flexibleRollout',
          parameters: { groupId: 'default', rollout: '50', stickiness: 'default' }
        }])
        expect(feature_flag.strategies.first.scopes.map { |s| s.slice(:environment_scope).deep_symbolize_keys }).to eq([{
          environment_scope: 'staging'
        }])
      end

      it 'creates a new feature flag with user list strategy', :aggregate_failures do
        params = {
          name: 'new-feature',
          version: 'new_version_flag',
          strategies: [{
            name: 'gitlabUserList',
            parameters: {},
            user_list_id: user_list.id
          }]
        }

        post api("/projects/#{project.id}/feature_flags", user), params: params

        expect(response).to have_gitlab_http_status(:created)
        expect(response).to match_response_schema('public_api/v4/feature_flag')

        feature_flag = project.operations_feature_flags.last
        expect(feature_flag.name).to eq(params[:name])
        expect(feature_flag.version).to eq('new_version_flag')
        expect(feature_flag.strategies.map { |s| s.slice(:name, :parameters).deep_symbolize_keys }).to eq([{
          name: 'gitlabUserList',
          parameters: {}
        }])
        expect(feature_flag.strategies.first.user_list).to eq(user_list)
      end
    end

    context 'when given invalid parameters' do
      it 'responds with a 400 when given an invalid version' do
        params = { name: 'new-feature', version: 'bad_value' }

        post api("/projects/#{project.id}/feature_flags", user), params: params

        expect(response).to have_gitlab_http_status(:bad_request)
        expect(json_response).to eq({ 'message' => 'Version is invalid' })
      end
    end
  end

  describe 'PUT /projects/:id/feature_flags/:name' do
    context 'with a version 2 feature flag' do
      let!(:feature_flag) do
        create(:operations_feature_flag, :new_version_flag,
          project: project, active: true, name: 'feature1', description: 'old description')
      end

      let(:user_list) do
        create(:operations_feature_flag_user_list, project: project)
      end

      it 'returns a 404 if the feature flag does not exist' do
        params = { description: 'new description' }

        put api("/projects/#{project.id}/feature_flags/other_flag_name", user), params: params

        expect(response).to have_gitlab_http_status(:not_found)
        expect(feature_flag.reload.description).to eq('old description')
      end

      it 'forbids a request for a reporter' do
        params = { description: 'new description' }

        put api("/projects/#{project.id}/feature_flags/feature1", reporter), params: params

        expect(response).to have_gitlab_http_status(:forbidden)
        expect(feature_flag.reload.description).to eq('old description')
      end

      it 'returns an error for an invalid update of gradual rollout' do
        strategy = create(:operations_strategy, feature_flag: feature_flag, name: 'default', parameters: {})
        params = {
          strategies: [{
            id: strategy.id,
            name: 'gradualRolloutUserId',
            parameters: { bad: 'params' }
          }]
        }

        put api("/projects/#{project.id}/feature_flags/feature1", user), params: params

        expect(response).to have_gitlab_http_status(:bad_request)
        expect(json_response['message']).not_to be_nil
        result = feature_flag.reload.strategies.map { |s| s.slice(:id, :name, :parameters).deep_symbolize_keys }
        expect(result).to eq([{
          id: strategy.id,
          name: 'default',
          parameters: {}
        }])
      end

      it 'returns an error for an invalid update of flexible rollout' do
        strategy = create(:operations_strategy, feature_flag: feature_flag, name: 'default', parameters: {})
        params = {
          strategies: [{
            id: strategy.id,
            name: 'flexibleRollout',
            parameters: { bad: 'params' }
          }]
        }

        put api("/projects/#{project.id}/feature_flags/feature1", user), params: params

        expect(response).to have_gitlab_http_status(:bad_request)
        expect(json_response['message']).not_to be_nil
        result = feature_flag.reload.strategies.map { |s| s.slice(:id, :name, :parameters).deep_symbolize_keys }
        expect(result).to eq([{
          id: strategy.id,
          name: 'default',
          parameters: {}
        }])
      end

      it 'updates the feature flag' do
        params = { description: 'new description' }

        put api("/projects/#{project.id}/feature_flags/feature1", user), params: params

        expect(response).to have_gitlab_http_status(:ok)
        expect(response).to match_response_schema('public_api/v4/feature_flag')
        expect(feature_flag.reload.description).to eq('new description')
      end

      it 'updates the flag active value' do
        params = { active: false }

        put api("/projects/#{project.id}/feature_flags/feature1", user), params: params

        expect(response).to have_gitlab_http_status(:ok)
        expect(response).to match_response_schema('public_api/v4/feature_flag')
        expect(json_response['active']).to eq(false)
        expect(feature_flag.reload.active).to eq(false)
      end

      it 'updates the feature flag name' do
        params = { name: 'new-name' }

        put api("/projects/#{project.id}/feature_flags/feature1", user), params: params

        expect(response).to have_gitlab_http_status(:ok)
        expect(response).to match_response_schema('public_api/v4/feature_flag')
        expect(json_response['name']).to eq('new-name')
        expect(feature_flag.reload.name).to eq('new-name')
      end

      it 'ignores a provided version parameter' do
        params = { description: 'other description', version: 'bad_value' }

        put api("/projects/#{project.id}/feature_flags/feature1", user), params: params

        expect(response).to have_gitlab_http_status(:ok)
        expect(response).to match_response_schema('public_api/v4/feature_flag')
        expect(feature_flag.reload.description).to eq('other description')
      end

      it 'returns the feature flag json' do
        params = { description: 'new description' }

        put api("/projects/#{project.id}/feature_flags/feature1", user), params: params

        expect(response).to have_gitlab_http_status(:ok)
        expect(response).to match_response_schema('public_api/v4/feature_flag')
        feature_flag.reload
        expect(json_response).to eq({
          'name' => 'feature1',
          'description' => 'new description',
          'active' => true,
          'created_at' => feature_flag.created_at.as_json,
          'updated_at' => feature_flag.updated_at.as_json,
          'scopes' => [],
          'strategies' => [],
          'version' => 'new_version_flag'
        })
      end

      it 'updates an existing feature flag strategy to be gradual rollout strategy' do
        strategy = create(:operations_strategy, feature_flag: feature_flag, name: 'default', parameters: {})
        params = {
          strategies: [{
            id: strategy.id,
            name: 'gradualRolloutUserId',
            parameters: { groupId: 'default', percentage: '10' }
          }]
        }

        put api("/projects/#{project.id}/feature_flags/feature1", user), params: params

        expect(response).to have_gitlab_http_status(:ok)
        expect(response).to match_response_schema('public_api/v4/feature_flag')
        result = feature_flag.reload.strategies.map { |s| s.slice(:id, :name, :parameters).deep_symbolize_keys }
        expect(result).to eq([{
          id: strategy.id,
          name: 'gradualRolloutUserId',
          parameters: { groupId: 'default', percentage: '10' }
        }])
      end

      it 'updates an existing feature flag strategy to be flexible rollout strategy' do
        strategy = create(:operations_strategy, feature_flag: feature_flag, name: 'default', parameters: {})
        params = {
          strategies: [{
            id: strategy.id,
            name: 'flexibleRollout',
            parameters: { groupId: 'default', rollout: '10', stickiness: 'default' }
          }]
        }

        put api("/projects/#{project.id}/feature_flags/feature1", user), params: params

        expect(response).to have_gitlab_http_status(:ok)
        expect(response).to match_response_schema('public_api/v4/feature_flag')
        result = feature_flag.reload.strategies.map { |s| s.slice(:id, :name, :parameters).deep_symbolize_keys }
        expect(result).to eq([{
          id: strategy.id,
          name: 'flexibleRollout',
          parameters: { groupId: 'default', rollout: '10', stickiness: 'default' }
        }])
      end

      it 'updates an existing feature flag strategy to be gitlab user list strategy', :aggregate_failures do
        strategy = create(:operations_strategy, feature_flag: feature_flag, name: 'default', parameters: {})
        params = {
          strategies: [{
            id: strategy.id,
            name: 'gitlabUserList',
            user_list_id: user_list.id,
            parameters: {}
          }]
        }

        put api("/projects/#{project.id}/feature_flags/feature1", user), params: params

        expect(response).to have_gitlab_http_status(:ok)
        expect(response).to match_response_schema('public_api/v4/feature_flag')
        result = feature_flag.reload.strategies.map { |s| s.slice(:id, :name, :parameters).deep_symbolize_keys }
        expect(result).to eq([{
          id: strategy.id,
          name: 'gitlabUserList',
          parameters: {}
        }])
        expect(feature_flag.strategies.first.user_list).to eq(user_list)
      end

      it 'adds a new gradual rollout strategy to a feature flag' do
        strategy = create(:operations_strategy, feature_flag: feature_flag, name: 'default', parameters: {})
        params = {
          strategies: [{
            name: 'gradualRolloutUserId',
            parameters: { groupId: 'default', percentage: '10' }
          }]
        }

        put api("/projects/#{project.id}/feature_flags/feature1", user), params: params

        expect(response).to have_gitlab_http_status(:ok)
        expect(response).to match_response_schema('public_api/v4/feature_flag')
        result = feature_flag.reload.strategies
          .map { |s| s.slice(:id, :name, :parameters).deep_symbolize_keys }
          .sort_by { |s| s[:name] }
        expect(result.first[:id]).to eq(strategy.id)
        expect(result.map { |s| s.slice(:name, :parameters) }).to eq([{
          name: 'default',
          parameters: {}
        }, {
          name: 'gradualRolloutUserId',
          parameters: { groupId: 'default', percentage: '10' }
        }])
      end

      it 'adds a new gradual flexible strategy to a feature flag' do
        strategy = create(:operations_strategy, feature_flag: feature_flag, name: 'default', parameters: {})
        params = {
          strategies: [{
            name: 'flexibleRollout',
            parameters: { groupId: 'default', rollout: '10', stickiness: 'default' }
          }]
        }

        put api("/projects/#{project.id}/feature_flags/feature1", user), params: params

        expect(response).to have_gitlab_http_status(:ok)
        expect(response).to match_response_schema('public_api/v4/feature_flag')
        result = feature_flag.reload.strategies
          .map { |s| s.slice(:id, :name, :parameters).deep_symbolize_keys }
          .sort_by { |s| s[:name] }
        expect(result.first[:id]).to eq(strategy.id)
        expect(result.map { |s| s.slice(:name, :parameters) }).to eq([{
          name: 'default',
          parameters: {}
        }, {
          name: 'flexibleRollout',
          parameters: { groupId: 'default', rollout: '10', stickiness: 'default' }
        }])
      end

      it 'deletes a feature flag strategy' do
        strategy_a = create(:operations_strategy, feature_flag: feature_flag, name: 'default', parameters: {})
        strategy_b = create(:operations_strategy,
          feature_flag: feature_flag, name: 'userWithId', parameters: { userIds: 'userA,userB' })
        params = {
          strategies: [{
            id: strategy_a.id,
            name: 'default',
            parameters: {},
            _destroy: true
          }, {
            id: strategy_b.id,
            name: 'userWithId',
            parameters: { userIds: 'userB' }
          }]
        }

        put api("/projects/#{project.id}/feature_flags/feature1", user), params: params

        expect(response).to have_gitlab_http_status(:ok)
        expect(response).to match_response_schema('public_api/v4/feature_flag')
        result = feature_flag.reload.strategies
          .map { |s| s.slice(:id, :name, :parameters).deep_symbolize_keys }
          .sort_by { |s| s[:name] }
        expect(result).to eq([{
          id: strategy_b.id,
          name: 'userWithId',
          parameters: { userIds: 'userB' }
        }])
      end

      it 'updates an existing feature flag scope' do
        strategy = create(:operations_strategy, feature_flag: feature_flag, name: 'default', parameters: {})
        scope = create(:operations_scope, strategy: strategy, environment_scope: '*')
        params = {
          strategies: [{
            id: strategy.id,
            scopes: [{
              id: scope.id,
              environment_scope: 'production'
            }]
          }]
        }

        put api("/projects/#{project.id}/feature_flags/feature1", user), params: params

        expect(response).to have_gitlab_http_status(:ok)
        expect(response).to match_response_schema('public_api/v4/feature_flag')
        result = feature_flag.reload.strategies.first.scopes.map { |s| s.slice(:id, :environment_scope).deep_symbolize_keys }
        expect(result).to eq([{
          id: scope.id,
          environment_scope: 'production'
        }])
      end

      it 'deletes an existing feature flag scope' do
        strategy = create(:operations_strategy, feature_flag: feature_flag, name: 'default', parameters: {})
        scope = create(:operations_scope, strategy: strategy, environment_scope: '*')
        params = {
          strategies: [{
            id: strategy.id,
            scopes: [{
              id: scope.id,
              _destroy: true
            }]
          }]
        }

        put api("/projects/#{project.id}/feature_flags/feature1", user), params: params

        expect(response).to have_gitlab_http_status(:ok)
        expect(response).to match_response_schema('public_api/v4/feature_flag')
        expect(feature_flag.reload.strategies.first.scopes.count).to eq(0)
      end
    end
  end

  describe 'DELETE /projects/:id/feature_flags/:name' do
    subject do
      delete api("/projects/#{project.id}/feature_flags/#{feature_flag.name}", user),
        params: params
    end

    let!(:feature_flag) { create(:operations_feature_flag, project: project) }
    let(:params) { {} }

    it 'destroys the feature flag' do
      expect { subject }.to change { Operations::FeatureFlag.count }.by(-1)

      expect(response).to have_gitlab_http_status(:ok)
    end

    it 'returns version' do
      subject

      expect(response).to have_gitlab_http_status(:ok)
      expect(json_response['version']).to eq('new_version_flag')
    end

    context 'with a version 2 feature flag' do
      let!(:feature_flag) { create(:operations_feature_flag, :new_version_flag, project: project) }

      it 'destroys the flag' do
        expect { subject }.to change { Operations::FeatureFlag.count }.by(-1)

        expect(response).to have_gitlab_http_status(:ok)
      end
    end
  end
end
