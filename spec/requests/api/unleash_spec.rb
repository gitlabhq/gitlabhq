# frozen_string_literal: true

require 'spec_helper'

RSpec.describe API::Unleash do
  include FeatureFlagHelpers

  let_it_be(:project, refind: true) { create(:project) }
  let(:project_id) { project.id }
  let(:params) { }
  let(:headers) { }

  shared_examples 'authenticated request' do
    context 'when using instance id' do
      let(:client) { create(:operations_feature_flags_client, project: project) }
      let(:params) { { instance_id: client.token } }

      it 'responds with OK' do
        subject

        expect(response).to have_gitlab_http_status(:ok)
      end

      context 'when repository is disabled' do
        before do
          project.project_feature.update!(
            repository_access_level: ::ProjectFeature::DISABLED,
            merge_requests_access_level: ::ProjectFeature::DISABLED,
            builds_access_level: ::ProjectFeature::DISABLED
          )
        end

        it 'responds with forbidden' do
          subject

          expect(response).to have_gitlab_http_status(:ok)
        end
      end

      context 'when repository is private' do
        before do
          project.project_feature.update!(
            repository_access_level: ::ProjectFeature::PRIVATE,
            merge_requests_access_level: ::ProjectFeature::DISABLED,
            builds_access_level: ::ProjectFeature::DISABLED
          )
        end

        it 'responds with OK' do
          subject

          expect(response).to have_gitlab_http_status(:ok)
        end
      end
    end

    context 'when using header' do
      let(:client) { create(:operations_feature_flags_client, project: project) }
      let(:headers) { { "UNLEASH-INSTANCEID" => client.token }}

      it 'responds with OK' do
        subject

        expect(response).to have_gitlab_http_status(:ok)
      end
    end

    context 'when using bogus instance id' do
      let(:params) { { instance_id: 'token' } }

      it 'responds with unauthorized' do
        subject

        expect(response).to have_gitlab_http_status(:unauthorized)
      end
    end

    context 'when using not existing project' do
      let(:project_id) { -5000 }
      let(:params) { { instance_id: 'token' } }

      it 'responds with unauthorized' do
        subject

        expect(response).to have_gitlab_http_status(:unauthorized)
      end
    end
  end

  shared_examples_for 'support multiple environments' do
    let!(:client) { create(:operations_feature_flags_client, project: project) }
    let!(:base_headers) { { "UNLEASH-INSTANCEID" => client.token } }
    let!(:headers) { base_headers.merge({ "UNLEASH-APPNAME" => "test" }) }

    let!(:feature_flag_1) do
      create(:operations_feature_flag, name: "feature_flag_1", project: project, active: true)
    end

    let!(:feature_flag_2) do
      create(:operations_feature_flag, name: "feature_flag_2", project: project, active: false)
    end

    before do
      create_scope(feature_flag_1, 'production', false)
      create_scope(feature_flag_2, 'review/*', true)
    end

    it 'does not have N+1 problem' do
      control_count = ActiveRecord::QueryRecorder.new { get api(features_url), headers: headers }.count

      create(:operations_feature_flag, name: "feature_flag_3", project: project, active: true)

      expect { get api(features_url), headers: headers }.not_to exceed_query_limit(control_count)
    end

    context 'when app name is staging' do
      let(:headers) { base_headers.merge({ "UNLEASH-APPNAME" => "staging" }) }

      it 'returns correct active values' do
        subject

        feature_flag_1 = json_response['features'].find { |f| f['name'] == 'feature_flag_1' }
        feature_flag_2 = json_response['features'].find { |f| f['name'] == 'feature_flag_2' }

        expect(feature_flag_1['enabled']).to eq(true)
        expect(feature_flag_2['enabled']).to eq(false)
      end
    end

    context 'when app name is production' do
      let(:headers) { base_headers.merge({ "UNLEASH-APPNAME" => "production" }) }

      it 'returns correct active values' do
        subject

        feature_flag_1 = json_response['features'].find { |f| f['name'] == 'feature_flag_1' }
        feature_flag_2 = json_response['features'].find { |f| f['name'] == 'feature_flag_2' }

        expect(feature_flag_1['enabled']).to eq(false)
        expect(feature_flag_2['enabled']).to eq(false)
      end
    end

    context 'when app name is review/patch-1' do
      let(:headers) { base_headers.merge({ "UNLEASH-APPNAME" => "review/patch-1" }) }

      it 'returns correct active values' do
        subject

        feature_flag_1 = json_response['features'].find { |f| f['name'] == 'feature_flag_1' }
        feature_flag_2 = json_response['features'].find { |f| f['name'] == 'feature_flag_2' }

        expect(feature_flag_1['enabled']).to eq(true)
        expect(feature_flag_2['enabled']).to eq(false)
      end
    end

    context 'when app name is empty' do
      let(:headers) { base_headers }

      it 'returns empty list' do
        subject

        expect(json_response['features'].count).to eq(0)
      end
    end
  end

  %w(/feature_flags/unleash/:project_id/features /feature_flags/unleash/:project_id/client/features).each do |features_endpoint|
    describe "GET #{features_endpoint}" do
      let(:features_url) { features_endpoint.sub(':project_id', project_id.to_s) }
      let(:client) { create(:operations_feature_flags_client, project: project) }

      subject { get api(features_url), params: params, headers: headers }

      it_behaves_like 'authenticated request'

      context 'with version 1 (legacy) feature flags' do
        let(:feature_flag) { create(:operations_feature_flag, project: project, name: 'feature1', active: true, version: 1) }

        it_behaves_like 'support multiple environments'

        context 'with a list of feature flags' do
          let(:headers) { { "UNLEASH-INSTANCEID" => client.token, "UNLEASH-APPNAME" => "production" } }
          let!(:enabled_feature_flag) { create(:operations_feature_flag, project: project, name: 'feature1', active: true, version: 1) }
          let!(:disabled_feature_flag) { create(:operations_feature_flag, project: project, name: 'feature2', active: false, version: 1) }

          it 'responds with a list of features' do
            subject

            expect(response).to have_gitlab_http_status(:ok)
            expect(json_response['version']).to eq(1)
            expect(json_response['features']).not_to be_empty
            expect(json_response['features'].map { |f| f['name'] }.sort).to eq(%w[feature1 feature2])
            expect(json_response['features'].sort_by {|f| f['name'] }.map { |f| f['enabled'] }).to eq([true, false])
          end

          it 'matches json schema' do
            subject

            expect(response).to have_gitlab_http_status(:ok)
            expect(response).to match_response_schema('unleash/unleash')
          end
        end

        it 'returns a feature flag strategy' do
          create(:operations_feature_flag_scope,
                 feature_flag: feature_flag,
                 environment_scope: 'sandbox',
                 active: true,
                 strategies: [{ name: "gradualRolloutUserId",
                                parameters: { groupId: "default", percentage: "50" } }])
          headers = { "UNLEASH-INSTANCEID" => client.token, "UNLEASH-APPNAME" => "sandbox" }

          get api(features_url), headers: headers

          expect(response).to have_gitlab_http_status(:ok)
          expect(json_response['features'].first['enabled']).to eq(true)
          strategies = json_response['features'].first['strategies']
          expect(strategies).to eq([{
            "name" => "gradualRolloutUserId",
            "parameters" => {
              "percentage" => "50",
              "groupId" => "default"
            }
          }])
        end

        it 'returns a default strategy for a scope' do
          create(:operations_feature_flag_scope, feature_flag: feature_flag, environment_scope: 'sandbox', active: true)
          headers = { "UNLEASH-INSTANCEID" => client.token, "UNLEASH-APPNAME" => "sandbox" }

          get api(features_url), headers: headers

          expect(response).to have_gitlab_http_status(:ok)
          expect(json_response['features'].first['enabled']).to eq(true)
          strategies = json_response['features'].first['strategies']
          expect(strategies).to eq([{ "name" => "default", "parameters" => {} }])
        end

        it 'returns multiple strategies for a feature flag' do
          create(:operations_feature_flag_scope,
                 feature_flag: feature_flag,
                 environment_scope: 'staging',
                 active: true,
                 strategies: [{ name: "userWithId", parameters: { userIds: "max,fred" } },
                              { name: "gradualRolloutUserId",
                                parameters: { groupId: "default", percentage: "50" } }])
          headers = { "UNLEASH-INSTANCEID" => client.token, "UNLEASH-APPNAME" => "staging" }

          get api(features_url), headers: headers

          expect(response).to have_gitlab_http_status(:ok)
          expect(json_response['features'].first['enabled']).to eq(true)
          strategies = json_response['features'].first['strategies'].sort_by { |s| s['name'] }
          expect(strategies).to eq([{
            "name" => "gradualRolloutUserId",
            "parameters" => {
              "percentage" => "50",
              "groupId" => "default"
            }
          }, {
            "name" => "userWithId",
            "parameters" => {
              "userIds" => "max,fred"
            }
          }])
        end

        it 'returns a disabled feature when the flag is disabled' do
          flag = create(:operations_feature_flag, project: project, name: 'test_feature', active: false, version: 1)
          create(:operations_feature_flag_scope, feature_flag: flag, environment_scope: 'production', active: true)
          headers = { "UNLEASH-INSTANCEID" => client.token, "UNLEASH-APPNAME" => "production" }

          get api(features_url), headers: headers

          expect(response).to have_gitlab_http_status(:ok)
          expect(json_response['features'].first['enabled']).to eq(false)
        end

        context "with an inactive scope" do
          let!(:scope) { create(:operations_feature_flag_scope, feature_flag: feature_flag, environment_scope: 'production', active: false, strategies: [{ name: "default", parameters: {} }]) }
          let(:headers) { { "UNLEASH-INSTANCEID" => client.token, "UNLEASH-APPNAME" => "production" } }

          it 'returns a disabled feature' do
            get api(features_url), headers: headers

            expect(response).to have_gitlab_http_status(:ok)
            feature_json = json_response['features'].first
            expect(feature_json['enabled']).to eq(false)
            expect(feature_json['strategies']).to eq([{ 'name' => 'default', 'parameters' => {} }])
          end
        end
      end

      context 'with version 2 feature flags' do
        it 'does not return a flag without any strategies' do
          create(:operations_feature_flag, project: project,
                 name: 'feature1', active: true, version: 2)

          get api(features_url), headers: { 'UNLEASH-INSTANCEID' => client.token, 'UNLEASH-APPNAME' => 'production' }

          expect(response).to have_gitlab_http_status(:ok)
          expect(json_response['features']).to be_empty
        end

        it 'returns a flag with a default strategy' do
          feature_flag = create(:operations_feature_flag, project: project,
                                name: 'feature1', active: true, version: 2)
          strategy = create(:operations_strategy, feature_flag: feature_flag,
                            name: 'default', parameters: {})
          create(:operations_scope, strategy: strategy, environment_scope: 'production')

          get api(features_url), headers: { 'UNLEASH-INSTANCEID' => client.token, 'UNLEASH-APPNAME' => 'production' }

          expect(response).to have_gitlab_http_status(:ok)
          expect(json_response['features']).to eq([{
            'name' => 'feature1',
            'enabled' => true,
            'strategies' => [{
              'name' => 'default',
              'parameters' => {}
            }]
          }])
        end

        it 'returns a flag with a userWithId strategy' do
          feature_flag = create(:operations_feature_flag, project: project,
                                name: 'feature1', active: true, version: 2)
          strategy = create(:operations_strategy, feature_flag: feature_flag,
                            name: 'userWithId', parameters: { userIds: 'user123,user456' })
          create(:operations_scope, strategy: strategy, environment_scope: 'production')

          get api(features_url), headers: { 'UNLEASH-INSTANCEID' => client.token, 'UNLEASH-APPNAME' => 'production' }

          expect(response).to have_gitlab_http_status(:ok)
          expect(json_response['features']).to eq([{
            'name' => 'feature1',
            'enabled' => true,
            'strategies' => [{
              'name' => 'userWithId',
              'parameters' => { 'userIds' => 'user123,user456' }
            }]
          }])
        end

        it 'returns a flag with multiple strategies' do
          feature_flag = create(:operations_feature_flag, project: project,
                                name: 'feature1', active: true, version: 2)
          strategy_a = create(:operations_strategy, feature_flag: feature_flag,
                              name: 'userWithId', parameters: { userIds: 'user_a,user_b' })
          strategy_b = create(:operations_strategy, feature_flag: feature_flag,
                              name: 'gradualRolloutUserId', parameters: { groupId: 'default', percentage: '45' })
          create(:operations_scope, strategy: strategy_a, environment_scope: 'production')
          create(:operations_scope, strategy: strategy_b, environment_scope: 'production')

          get api(features_url), headers: { 'UNLEASH-INSTANCEID' => client.token, 'UNLEASH-APPNAME' => 'production' }

          expect(response).to have_gitlab_http_status(:ok)
          expect(json_response['features'].map { |f| f['name'] }.sort).to eq(['feature1'])
          features_json = json_response['features'].map do |feature|
            feature.merge(feature.slice('strategies').transform_values { |v| v.sort_by { |s| s['name'] } })
          end
          expect(features_json).to eq([{
            'name' => 'feature1',
            'enabled' => true,
            'strategies' => [{
              'name' => 'gradualRolloutUserId',
              'parameters' => { 'groupId' => 'default', 'percentage' => '45' }
            }, {
              'name' => 'userWithId',
              'parameters' => { 'userIds' => 'user_a,user_b' }
            }]
          }])
        end

        it 'returns only flags matching the environment scope' do
          feature_flag_a = create(:operations_feature_flag, project: project,
                                  name: 'feature1', active: true, version: 2)
          strategy_a = create(:operations_strategy, feature_flag: feature_flag_a)
          create(:operations_scope, strategy: strategy_a, environment_scope: 'production')
          feature_flag_b = create(:operations_feature_flag, project: project,
                                  name: 'feature2', active: true, version: 2)
          strategy_b = create(:operations_strategy, feature_flag: feature_flag_b)
          create(:operations_scope, strategy: strategy_b, environment_scope: 'staging')

          get api(features_url), headers: { 'UNLEASH-INSTANCEID' => client.token, 'UNLEASH-APPNAME' => 'staging' }

          expect(response).to have_gitlab_http_status(:ok)
          expect(json_response['features'].map { |f| f['name'] }.sort).to eq(['feature2'])
          expect(json_response['features']).to eq([{
            'name' => 'feature2',
            'enabled' => true,
            'strategies' => [{
              'name' => 'default',
              'parameters' => {}
            }]
          }])
        end

        it 'returns only strategies matching the environment scope' do
          feature_flag = create(:operations_feature_flag, project: project,
                                name: 'feature1', active: true, version: 2)
          strategy_a = create(:operations_strategy, feature_flag: feature_flag,
                              name: 'userWithId', parameters: { userIds: 'user2,user8,user4' })
          create(:operations_scope, strategy: strategy_a, environment_scope: 'production')
          strategy_b = create(:operations_strategy, feature_flag: feature_flag,
                              name: 'default', parameters: {})
          create(:operations_scope, strategy: strategy_b, environment_scope: 'staging')

          get api(features_url), headers: { 'UNLEASH-INSTANCEID' => client.token, 'UNLEASH-APPNAME' => 'production' }

          expect(response).to have_gitlab_http_status(:ok)
          expect(json_response['features']).to eq([{
            'name' => 'feature1',
            'enabled' => true,
            'strategies' => [{
              'name' => 'userWithId',
              'parameters' => { 'userIds' => 'user2,user8,user4' }
            }]
          }])
        end

        it 'returns only flags for the given project' do
          project_b = create(:project)
          feature_flag_a = create(:operations_feature_flag, project: project, name: 'feature_a', active: true, version: 2)
          strategy_a = create(:operations_strategy, feature_flag: feature_flag_a)
          create(:operations_scope, strategy: strategy_a, environment_scope: 'sandbox')
          feature_flag_b = create(:operations_feature_flag, project: project_b, name: 'feature_b', active: true, version: 2)
          strategy_b = create(:operations_strategy, feature_flag: feature_flag_b)
          create(:operations_scope, strategy: strategy_b, environment_scope: 'sandbox')

          get api(features_url), headers: { 'UNLEASH-INSTANCEID' => client.token, 'UNLEASH-APPNAME' => 'sandbox' }

          expect(response).to have_gitlab_http_status(:ok)
          expect(json_response['features']).to eq([{
            'name' => 'feature_a',
            'enabled' => true,
            'strategies' => [{
              'name' => 'default',
              'parameters' => {}
            }]
          }])
        end

        it 'returns all strategies with a matching scope' do
          feature_flag = create(:operations_feature_flag, project: project,
                                name: 'feature1', active: true, version: 2)
          strategy_a = create(:operations_strategy, feature_flag: feature_flag,
                              name: 'userWithId', parameters: { userIds: 'user2,user8,user4' })
          create(:operations_scope, strategy: strategy_a, environment_scope: '*')
          strategy_b = create(:operations_strategy, feature_flag: feature_flag,
                              name: 'default', parameters: {})
          create(:operations_scope, strategy: strategy_b, environment_scope: 'review/*')
          strategy_c = create(:operations_strategy, feature_flag: feature_flag,
                              name: 'gradualRolloutUserId', parameters: { groupId: 'default', percentage: '15' })
          create(:operations_scope, strategy: strategy_c, environment_scope: 'review/patch-1')

          get api(features_url), headers: { 'UNLEASH-INSTANCEID' => client.token, 'UNLEASH-APPNAME' => 'review/patch-1' }

          expect(response).to have_gitlab_http_status(:ok)
          expect(json_response['features'].first['strategies'].sort_by { |s| s['name'] }).to eq([{
            'name' => 'default',
            'parameters' => {}
          }, {
            'name' => 'gradualRolloutUserId',
            'parameters' => { 'groupId' => 'default', 'percentage' => '15' }
          }, {
            'name' => 'userWithId',
            'parameters' => { 'userIds' => 'user2,user8,user4' }
          }])
        end

        it 'returns a strategy with more than one matching scope' do
          feature_flag = create(:operations_feature_flag, project: project,
                                name: 'feature1', active: true, version: 2)
          strategy = create(:operations_strategy, feature_flag: feature_flag,
                            name: 'default', parameters: {})
          create(:operations_scope, strategy: strategy, environment_scope: 'production')
          create(:operations_scope, strategy: strategy, environment_scope: '*')

          get api(features_url), headers: { 'UNLEASH-INSTANCEID' => client.token, 'UNLEASH-APPNAME' => 'production' }

          expect(response).to have_gitlab_http_status(:ok)
          expect(json_response['features']).to eq([{
            'name' => 'feature1',
            'enabled' => true,
            'strategies' => [{
              'name' => 'default',
              'parameters' => {}
            }]
          }])
        end

        it 'returns a disabled flag with a matching scope' do
          feature_flag = create(:operations_feature_flag, project: project,
                                name: 'myfeature', active: false, version: 2)
          strategy = create(:operations_strategy, feature_flag: feature_flag,
                            name: 'default', parameters: {})
          create(:operations_scope, strategy: strategy, environment_scope: 'production')

          get api(features_url), headers: { 'UNLEASH-INSTANCEID' => client.token, 'UNLEASH-APPNAME' => 'production' }

          expect(response).to have_gitlab_http_status(:ok)
          expect(json_response['features']).to eq([{
            'name' => 'myfeature',
            'enabled' => false,
            'strategies' => [{
              'name' => 'default',
              'parameters' => {}
            }]
          }])
        end

        it 'returns a userWithId strategy for a gitlabUserList strategy' do
          feature_flag = create(:operations_feature_flag, :new_version_flag, project: project,
                                name: 'myfeature', active: true)
          user_list = create(:operations_feature_flag_user_list, project: project,
                             name: 'My List', user_xids: 'user1,user2')
          strategy = create(:operations_strategy, feature_flag: feature_flag,
                            name: 'gitlabUserList', parameters: {}, user_list: user_list)
          create(:operations_scope, strategy: strategy, environment_scope: 'production')

          get api(features_url), headers: { 'UNLEASH-INSTANCEID' => client.token, 'UNLEASH-APPNAME' => 'production' }

          expect(response).to have_gitlab_http_status(:ok)
          expect(json_response['features']).to eq([{
            'name' => 'myfeature',
            'enabled' => true,
            'strategies' => [{
              'name' => 'userWithId',
              'parameters' => { 'userIds' => 'user1,user2' }
            }]
          }])
        end
      end

      context 'when mixing version 1 and version 2 feature flags' do
        it 'returns both types of flags when both match' do
          feature_flag_a = create(:operations_feature_flag, project: project,
                                  name: 'feature_a', active: true, version: 2)
          strategy = create(:operations_strategy, feature_flag: feature_flag_a,
                            name: 'userWithId', parameters: { userIds: 'user8' })
          create(:operations_scope, strategy: strategy, environment_scope: 'staging')
          feature_flag_b = create(:operations_feature_flag, project: project,
                                  name: 'feature_b', active: true, version: 1)
          create(:operations_feature_flag_scope, feature_flag: feature_flag_b,
                 active: true, strategies: [{ name: 'default', parameters: {} }], environment_scope: 'staging')

          get api(features_url), headers: { 'UNLEASH-INSTANCEID' => client.token, 'UNLEASH-APPNAME' => 'staging' }

          expect(response).to have_gitlab_http_status(:ok)
          expect(json_response['features'].sort_by {|f| f['name']}).to eq([{
            'name' => 'feature_a',
            'enabled' => true,
            'strategies' => [{
              'name' => 'userWithId',
              'parameters' => { 'userIds' => 'user8' }
            }]
          }, {
            'name' => 'feature_b',
            'enabled' => true,
            'strategies' => [{
              'name' => 'default',
              'parameters' => {}
            }]
          }])
        end

        it 'returns legacy flags when only legacy flags match' do
          feature_flag_a = create(:operations_feature_flag, project: project,
                                  name: 'feature_a', active: true, version: 2)
          strategy = create(:operations_strategy, feature_flag: feature_flag_a,
                            name: 'userWithId', parameters: { userIds: 'user8' })
          create(:operations_scope, strategy: strategy, environment_scope: 'production')
          feature_flag_b = create(:operations_feature_flag, project: project,
                                  name: 'feature_b', active: true, version: 1)
          create(:operations_feature_flag_scope, feature_flag: feature_flag_b,
                 active: true, strategies: [{ name: 'default', parameters: {} }], environment_scope: 'staging')

          get api(features_url), headers: { 'UNLEASH-INSTANCEID' => client.token, 'UNLEASH-APPNAME' => 'staging' }

          expect(response).to have_gitlab_http_status(:ok)
          expect(json_response['features']).to eq([{
            'name' => 'feature_b',
            'enabled' => true,
            'strategies' => [{
              'name' => 'default',
              'parameters' => {}
            }]
          }])
        end
      end
    end
  end

  describe 'POST /feature_flags/unleash/:project_id/client/register' do
    subject { post api("/feature_flags/unleash/#{project_id}/client/register"), params: params, headers: headers }

    it_behaves_like 'authenticated request'
  end

  describe 'POST /feature_flags/unleash/:project_id/client/metrics' do
    subject { post api("/feature_flags/unleash/#{project_id}/client/metrics"), params: params, headers: headers }

    it_behaves_like 'authenticated request'
  end
end
