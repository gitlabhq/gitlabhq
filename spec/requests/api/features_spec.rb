# frozen_string_literal: true

require 'spec_helper'

describe API::Features, stub_feature_flags: false do
  let_it_be(:user)  { create(:user) }
  let_it_be(:admin) { create(:admin) }

  before do
    Feature.reset
    Flipper.unregister_groups
    Flipper.register(:perf_team) do |actor|
      actor.respond_to?(:admin) && actor.admin?
    end
  end

  describe 'GET /features' do
    let(:expected_features) do
      [
        {
          'name' => 'feature_1',
          'state' => 'on',
          'gates' => [{ 'key' => 'boolean', 'value' => true }]
        },
        {
          'name' => 'feature_2',
          'state' => 'off',
          'gates' => [{ 'key' => 'boolean', 'value' => false }]
        },
        {
          'name' => 'feature_3',
          'state' => 'conditional',
          'gates' => [
            { 'key' => 'boolean', 'value' => false },
            { 'key' => 'groups', 'value' => ['perf_team'] }
          ]
        }
      ]
    end

    before do
      Feature.enable('feature_1')
      Feature.disable('feature_2')
      Feature.enable('feature_3', Feature.group(:perf_team))
    end

    it 'returns a 401 for anonymous users' do
      get api('/features')

      expect(response).to have_gitlab_http_status(:unauthorized)
    end

    it 'returns a 403 for users' do
      get api('/features', user)

      expect(response).to have_gitlab_http_status(:forbidden)
    end

    it 'returns the feature list for admins' do
      get api('/features', admin)

      expect(response).to have_gitlab_http_status(:ok)
      expect(json_response).to match_array(expected_features)
    end
  end

  describe 'POST /feature' do
    let(:feature_name) { 'my_feature' }

    context 'when the feature does not exist' do
      it 'returns a 401 for anonymous users' do
        post api("/features/#{feature_name}")

        expect(response).to have_gitlab_http_status(:unauthorized)
      end

      it 'returns a 403 for users' do
        post api("/features/#{feature_name}", user)

        expect(response).to have_gitlab_http_status(:forbidden)
      end

      context 'when passed value=true' do
        it 'creates an enabled feature' do
          post api("/features/#{feature_name}", admin), params: { value: 'true' }

          expect(response).to have_gitlab_http_status(:created)
          expect(json_response).to eq(
            'name' => 'my_feature',
            'state' => 'on',
            'gates' => [{ 'key' => 'boolean', 'value' => true }])
        end

        it 'creates an enabled feature for the given Flipper group when passed feature_group=perf_team' do
          post api("/features/#{feature_name}", admin), params: { value: 'true', feature_group: 'perf_team' }

          expect(response).to have_gitlab_http_status(:created)
          expect(json_response).to eq(
            'name' => 'my_feature',
            'state' => 'conditional',
            'gates' => [
              { 'key' => 'boolean', 'value' => false },
              { 'key' => 'groups', 'value' => ['perf_team'] }
            ])
        end

        it 'creates an enabled feature for the given user when passed user=username' do
          post api("/features/#{feature_name}", admin), params: { value: 'true', user: user.username }

          expect(response).to have_gitlab_http_status(:created)
          expect(json_response).to eq(
            'name' => 'my_feature',
            'state' => 'conditional',
            'gates' => [
              { 'key' => 'boolean', 'value' => false },
              { 'key' => 'actors', 'value' => ["User:#{user.id}"] }
            ])
        end

        it 'creates an enabled feature for the given user and feature group when passed user=username and feature_group=perf_team' do
          post api("/features/#{feature_name}", admin), params: { value: 'true', user: user.username, feature_group: 'perf_team' }

          expect(response).to have_gitlab_http_status(:created)
          expect(json_response['name']).to eq('my_feature')
          expect(json_response['state']).to eq('conditional')
          expect(json_response['gates']).to contain_exactly(
            { 'key' => 'boolean', 'value' => false },
            { 'key' => 'groups', 'value' => ['perf_team'] },
            { 'key' => 'actors', 'value' => ["User:#{user.id}"] }
          )
        end
      end

      context 'when enabling for a project by path' do
        context 'when the project exists' do
          let!(:project) { create(:project) }

          it 'sets the feature gate' do
            post api("/features/#{feature_name}", admin), params: { value: 'true', project: project.full_path }

            expect(response).to have_gitlab_http_status(:created)
            expect(json_response).to eq(
              'name' => 'my_feature',
              'state' => 'conditional',
              'gates' => [
                { 'key' => 'boolean', 'value' => false },
                { 'key' => 'actors', 'value' => ["Project:#{project.id}"] }
              ])
          end
        end

        context 'when the project does not exist' do
          it 'sets no new values' do
            post api("/features/#{feature_name}", admin), params: { value: 'true', project: 'mep/to/the/mep/mep' }

            expect(response).to have_gitlab_http_status(:created)
            expect(json_response).to eq(
              "name" => "my_feature",
              "state" => "off",
              "gates" => [
                { "key" => "boolean", "value" => false }
              ]
            )
          end
        end
      end

      context 'when enabling for a group by path' do
        context 'when the group exists' do
          it 'sets the feature gate' do
            group = create(:group)

            post api("/features/#{feature_name}", admin), params: { value: 'true', group: group.full_path }

            expect(response).to have_gitlab_http_status(:created)
            expect(json_response).to eq(
              'name' => 'my_feature',
              'state' => 'conditional',
              'gates' => [
                { 'key' => 'boolean', 'value' => false },
                { 'key' => 'actors', 'value' => ["Group:#{group.id}"] }
              ])
          end
        end

        context 'when the group does not exist' do
          it 'sets no new values and keeps the feature disabled' do
            post api("/features/#{feature_name}", admin), params: { value: 'true', group: 'not/a/group' }

            expect(response).to have_gitlab_http_status(:created)
            expect(json_response).to eq(
              "name" => "my_feature",
              "state" => "off",
              "gates" => [
                { "key" => "boolean", "value" => false }
              ]
            )
          end
        end
      end

      it 'creates a feature with the given percentage of time if passed an integer' do
        post api("/features/#{feature_name}", admin), params: { value: '50' }

        expect(response).to have_gitlab_http_status(:created)
        expect(json_response).to eq(
          'name' => 'my_feature',
          'state' => 'conditional',
          'gates' => [
            { 'key' => 'boolean', 'value' => false },
            { 'key' => 'percentage_of_time', 'value' => 50 }
          ])
      end

      it 'creates a feature with the given percentage of actors if passed an integer' do
        post api("/features/#{feature_name}", admin), params: { value: '50', key: 'percentage_of_actors' }

        expect(response).to have_gitlab_http_status(:created)
        expect(json_response).to eq(
          'name' => 'my_feature',
          'state' => 'conditional',
          'gates' => [
            { 'key' => 'boolean', 'value' => false },
            { 'key' => 'percentage_of_actors', 'value' => 50 }
          ])
      end
    end

    context 'when the feature exists' do
      before do
        Feature.disable(feature_name) # This also persists the feature on the DB
      end

      context 'when passed value=true' do
        it 'enables the feature' do
          post api("/features/#{feature_name}", admin), params: { value: 'true' }

          expect(response).to have_gitlab_http_status(:created)
          expect(json_response).to eq(
            'name' => 'my_feature',
            'state' => 'on',
            'gates' => [{ 'key' => 'boolean', 'value' => true }])
        end

        it 'enables the feature for the given Flipper group when passed feature_group=perf_team' do
          post api("/features/#{feature_name}", admin), params: { value: 'true', feature_group: 'perf_team' }

          expect(response).to have_gitlab_http_status(:created)
          expect(json_response).to eq(
            'name' => 'my_feature',
            'state' => 'conditional',
            'gates' => [
              { 'key' => 'boolean', 'value' => false },
              { 'key' => 'groups', 'value' => ['perf_team'] }
            ])
        end

        it 'enables the feature for the given user when passed user=username' do
          post api("/features/#{feature_name}", admin), params: { value: 'true', user: user.username }

          expect(response).to have_gitlab_http_status(:created)
          expect(json_response).to eq(
            'name' => 'my_feature',
            'state' => 'conditional',
            'gates' => [
              { 'key' => 'boolean', 'value' => false },
              { 'key' => 'actors', 'value' => ["User:#{user.id}"] }
            ])
        end
      end

      context 'when feature is enabled and value=false is passed' do
        it 'disables the feature' do
          Feature.enable(feature_name)
          expect(Feature.enabled?(feature_name)).to eq(true)

          post api("/features/#{feature_name}", admin), params: { value: 'false' }

          expect(response).to have_gitlab_http_status(:created)
          expect(json_response).to eq(
            'name' => 'my_feature',
            'state' => 'off',
            'gates' => [{ 'key' => 'boolean', 'value' => false }])
        end

        it 'disables the feature for the given Flipper group when passed feature_group=perf_team' do
          Feature.enable(feature_name, Feature.group(:perf_team))
          expect(Feature.enabled?(feature_name, admin)).to be_truthy

          post api("/features/#{feature_name}", admin), params: { value: 'false', feature_group: 'perf_team' }

          expect(response).to have_gitlab_http_status(:created)
          expect(json_response).to eq(
            'name' => 'my_feature',
            'state' => 'off',
            'gates' => [{ 'key' => 'boolean', 'value' => false }])
        end

        it 'disables the feature for the given user when passed user=username' do
          Feature.enable(feature_name, user)
          expect(Feature.enabled?(feature_name, user)).to be_truthy

          post api("/features/#{feature_name}", admin), params: { value: 'false', user: user.username }

          expect(response).to have_gitlab_http_status(:created)
          expect(json_response).to eq(
            'name' => 'my_feature',
            'state' => 'off',
            'gates' => [{ 'key' => 'boolean', 'value' => false }])
        end
      end

      context 'with a pre-existing percentage of time value' do
        before do
          Feature.enable_percentage_of_time(feature_name, 50)
        end

        it 'updates the percentage of time if passed an integer' do
          post api("/features/#{feature_name}", admin), params: { value: '30' }

          expect(response).to have_gitlab_http_status(:created)
          expect(json_response).to eq(
            'name' => 'my_feature',
            'state' => 'conditional',
            'gates' => [
              { 'key' => 'boolean', 'value' => false },
              { 'key' => 'percentage_of_time', 'value' => 30 }
            ])
        end
      end

      context 'with a pre-existing percentage of actors value' do
        before do
          Feature.enable_percentage_of_actors(feature_name, 42)
        end

        it 'updates the percentage of actors if passed an integer' do
          post api("/features/#{feature_name}", admin), params: { value: '74', key: 'percentage_of_actors' }

          expect(response).to have_gitlab_http_status(:created)
          expect(json_response).to eq(
            'name' => 'my_feature',
            'state' => 'conditional',
            'gates' => [
              { 'key' => 'boolean', 'value' => false },
              { 'key' => 'percentage_of_actors', 'value' => 74 }
            ])
        end
      end
    end
  end

  describe 'DELETE /feature/:name' do
    let(:feature_name) { 'my_feature' }

    context 'when the user has no access' do
      it 'returns a 401 for anonymous users' do
        delete api("/features/#{feature_name}")

        expect(response).to have_gitlab_http_status(:unauthorized)
      end

      it 'returns a 403 for users' do
        delete api("/features/#{feature_name}", user)

        expect(response).to have_gitlab_http_status(:forbidden)
      end
    end

    context 'when the user has access' do
      it 'returns 204 when the value is not set' do
        delete api("/features/#{feature_name}", admin)

        expect(response).to have_gitlab_http_status(:no_content)
      end

      context 'when the gate value was set' do
        before do
          Feature.enable(feature_name)
        end

        it 'deletes an enabled feature' do
          expect do
            delete api("/features/#{feature_name}", admin)
            Feature.reset
          end.to change { Feature.persisted_name?(feature_name) }
            .and change { Feature.enabled?(feature_name) }

          expect(response).to have_gitlab_http_status(:no_content)
        end
      end
    end
  end
end
