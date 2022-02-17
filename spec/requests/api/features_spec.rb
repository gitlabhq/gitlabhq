# frozen_string_literal: true

require 'spec_helper'

RSpec.describe API::Features, stub_feature_flags: false do
  let_it_be(:user)  { create(:user) }
  let_it_be(:admin) { create(:admin) }

  # Find any `development` feature flag name
  let(:known_feature_flag) do
    Feature::Definition.definitions
      .values.find(&:development?)
  end

  let(:known_feature_flag_definition_hash) do
    a_hash_including(
      'type' => 'development'
    )
  end

  before do
    Feature.reset
    Flipper.unregister_groups
    Flipper.register(:perf_team) do |actor|
      actor.respond_to?(:admin) && actor.admin?
    end

    skip_feature_flags_yaml_validation
  end

  describe 'GET /features' do
    let(:expected_features) do
      [
        {
          'name' => 'feature_1',
          'state' => 'on',
          'gates' => [{ 'key' => 'boolean', 'value' => true }],
          'definition' => nil
        },
        {
          'name' => 'feature_2',
          'state' => 'off',
          'gates' => [{ 'key' => 'boolean', 'value' => false }],
          'definition' => nil
        },
        {
          'name' => 'feature_3',
          'state' => 'conditional',
          'gates' => [
            { 'key' => 'boolean', 'value' => false },
            { 'key' => 'groups', 'value' => ['perf_team'] }
          ],
          'definition' => nil
        },
        {
          'name' => known_feature_flag.name,
          'state' => 'on',
          'gates' => [{ 'key' => 'boolean', 'value' => true }],
          'definition' => known_feature_flag_definition_hash
        }
      ]
    end

    before do
      Feature.enable('feature_1')
      Feature.disable('feature_2')
      Feature.enable('feature_3', Feature.group(:perf_team))
      Feature.enable(known_feature_flag.name)
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
    let(:feature_name) { known_feature_flag.name }

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
          expect(json_response).to match(
            'name' => feature_name,
            'state' => 'on',
            'gates' => [{ 'key' => 'boolean', 'value' => true }],
            'definition' => known_feature_flag_definition_hash
          )
        end

        it 'logs the event' do
          expect(Feature.logger).to receive(:info).once

          post api("/features/#{feature_name}", admin), params: { value: 'true' }
        end

        it 'creates an enabled feature for the given Flipper group when passed feature_group=perf_team' do
          post api("/features/#{feature_name}", admin), params: { value: 'true', feature_group: 'perf_team' }

          expect(response).to have_gitlab_http_status(:created)
          expect(json_response).to match(
            'name' => feature_name,
            'state' => 'conditional',
            'gates' => [
              { 'key' => 'boolean', 'value' => false },
              { 'key' => 'groups', 'value' => ['perf_team'] }
            ],
            'definition' => known_feature_flag_definition_hash
          )
        end

        it 'creates an enabled feature for the given user when passed user=username' do
          post api("/features/#{feature_name}", admin), params: { value: 'true', user: user.username }

          expect(response).to have_gitlab_http_status(:created)
          expect(json_response).to match(
            'name' => feature_name,
            'state' => 'conditional',
            'gates' => [
              { 'key' => 'boolean', 'value' => false },
              { 'key' => 'actors', 'value' => ["User:#{user.id}"] }
            ],
            'definition' => known_feature_flag_definition_hash
          )
        end

        it 'creates an enabled feature for the given user and feature group when passed user=username and feature_group=perf_team' do
          post api("/features/#{feature_name}", admin), params: { value: 'true', user: user.username, feature_group: 'perf_team' }

          expect(response).to have_gitlab_http_status(:created)
          expect(json_response['name']).to eq(feature_name)
          expect(json_response['state']).to eq('conditional')
          expect(json_response['gates']).to contain_exactly(
            { 'key' => 'boolean', 'value' => false },
            { 'key' => 'groups', 'value' => ['perf_team'] },
            { 'key' => 'actors', 'value' => ["User:#{user.id}"] }
          )
        end
      end

      shared_examples 'does not enable the flag' do |actor_type, actor_path|
        it 'returns the current state of the flag without changes' do
          post api("/features/#{feature_name}", admin), params: { value: 'true', actor_type => actor_path }

          expect(response).to have_gitlab_http_status(:created)
          expect(json_response).to match(
            "name" => feature_name,
            "state" => "off",
            "gates" => [
              { "key" => "boolean", "value" => false }
            ],
            'definition' => known_feature_flag_definition_hash
          )
        end
      end

      shared_examples 'enables the flag for the actor' do |actor_type|
        it 'sets the feature gate' do
          post api("/features/#{feature_name}", admin), params: { value: 'true', actor_type => actor.full_path }

          expect(response).to have_gitlab_http_status(:created)
          expect(json_response).to match(
            'name' => feature_name,
            'state' => 'conditional',
            'gates' => [
              { 'key' => 'boolean', 'value' => false },
              { 'key' => 'actors', 'value' => ["#{actor.class}:#{actor.id}"] }
            ],
            'definition' => known_feature_flag_definition_hash
          )
        end
      end

      context 'when enabling for a project by path' do
        context 'when the project exists' do
          it_behaves_like 'enables the flag for the actor', :project do
            let(:actor) { create(:project) }
          end
        end

        context 'when the project does not exist' do
          it_behaves_like 'does not enable the flag', :project, 'mep/to/the/mep/mep'
        end
      end

      context 'when enabling for a group by path' do
        context 'when the group exists' do
          it_behaves_like 'enables the flag for the actor', :group do
            let(:actor) { create(:group) }
          end
        end

        context 'when the group does not exist' do
          it_behaves_like 'does not enable the flag', :group, 'not/a/group'
        end
      end

      context 'when enabling for a namespace by path' do
        context 'when the user namespace exists' do
          it_behaves_like 'enables the flag for the actor', :namespace do
            let(:actor) { create(:namespace) }
          end
        end

        context 'when the group namespace exists' do
          it_behaves_like 'enables the flag for the actor', :namespace do
            let(:actor) { create(:group) }
          end
        end

        context 'when the user namespace does not exist' do
          it_behaves_like 'does not enable the flag', :namespace, 'not/a/group'
        end

        context 'when a project namespace exists' do
          let(:project_namespace) { create(:project_namespace) }

          it_behaves_like 'does not enable the flag', :namespace do
            let(:actor_path) { project_namespace.full_path }
          end
        end
      end

      it 'creates a feature with the given percentage of time if passed an integer' do
        post api("/features/#{feature_name}", admin), params: { value: '50' }

        expect(response).to have_gitlab_http_status(:created)
        expect(json_response).to match(
          'name' => feature_name,
          'state' => 'conditional',
          'gates' => [
            { 'key' => 'boolean', 'value' => false },
            { 'key' => 'percentage_of_time', 'value' => 50 }
          ],
          'definition' => known_feature_flag_definition_hash
        )
      end

      it 'creates a feature with the given percentage of time if passed a float' do
        post api("/features/#{feature_name}", admin), params: { value: '0.01' }

        expect(response).to have_gitlab_http_status(:created)
        expect(json_response).to match(
          'name' => feature_name,
          'state' => 'conditional',
          'gates' => [
            { 'key' => 'boolean', 'value' => false },
            { 'key' => 'percentage_of_time', 'value' => 0.01 }
          ],
          'definition' => known_feature_flag_definition_hash
        )
      end

      it 'creates a feature with the given percentage of actors if passed an integer' do
        post api("/features/#{feature_name}", admin), params: { value: '50', key: 'percentage_of_actors' }

        expect(response).to have_gitlab_http_status(:created)
        expect(json_response).to match(
          'name' => feature_name,
          'state' => 'conditional',
          'gates' => [
            { 'key' => 'boolean', 'value' => false },
            { 'key' => 'percentage_of_actors', 'value' => 50 }
          ],
          'definition' => known_feature_flag_definition_hash
        )
      end

      it 'creates a feature with the given percentage of actors if passed a float' do
        post api("/features/#{feature_name}", admin), params: { value: '0.01', key: 'percentage_of_actors' }

        expect(response).to have_gitlab_http_status(:created)
        expect(json_response).to match(
          'name' => feature_name,
          'state' => 'conditional',
          'gates' => [
            { 'key' => 'boolean', 'value' => false },
            { 'key' => 'percentage_of_actors', 'value' => 0.01 }
          ],
          'definition' => known_feature_flag_definition_hash
        )
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
          expect(json_response).to match(
            'name' => feature_name,
            'state' => 'on',
            'gates' => [{ 'key' => 'boolean', 'value' => true }],
            'definition' => known_feature_flag_definition_hash
          )
        end

        it 'enables the feature for the given Flipper group when passed feature_group=perf_team' do
          post api("/features/#{feature_name}", admin), params: { value: 'true', feature_group: 'perf_team' }

          expect(response).to have_gitlab_http_status(:created)
          expect(json_response).to match(
            'name' => feature_name,
            'state' => 'conditional',
            'gates' => [
              { 'key' => 'boolean', 'value' => false },
              { 'key' => 'groups', 'value' => ['perf_team'] }
            ],
            'definition' => known_feature_flag_definition_hash
          )
        end

        it 'enables the feature for the given user when passed user=username' do
          post api("/features/#{feature_name}", admin), params: { value: 'true', user: user.username }

          expect(response).to have_gitlab_http_status(:created)
          expect(json_response).to match(
            'name' => feature_name,
            'state' => 'conditional',
            'gates' => [
              { 'key' => 'boolean', 'value' => false },
              { 'key' => 'actors', 'value' => ["User:#{user.id}"] }
            ],
            'definition' => known_feature_flag_definition_hash
          )
        end
      end

      context 'when feature is enabled and value=false is passed' do
        it 'disables the feature' do
          Feature.enable(feature_name)
          expect(Feature.enabled?(feature_name)).to eq(true)

          post api("/features/#{feature_name}", admin), params: { value: 'false' }

          expect(response).to have_gitlab_http_status(:created)
          expect(json_response).to match(
            'name' => feature_name,
            'state' => 'off',
            'gates' => [{ 'key' => 'boolean', 'value' => false }],
            'definition' => known_feature_flag_definition_hash
          )
        end

        it 'disables the feature for the given Flipper group when passed feature_group=perf_team' do
          Feature.enable(feature_name, Feature.group(:perf_team))
          expect(Feature.enabled?(feature_name, admin)).to be_truthy

          post api("/features/#{feature_name}", admin), params: { value: 'false', feature_group: 'perf_team' }

          expect(response).to have_gitlab_http_status(:created)
          expect(json_response).to match(
            'name' => feature_name,
            'state' => 'off',
            'gates' => [{ 'key' => 'boolean', 'value' => false }],
            'definition' => known_feature_flag_definition_hash
          )
        end

        it 'disables the feature for the given user when passed user=username' do
          Feature.enable(feature_name, user)
          expect(Feature.enabled?(feature_name, user)).to be_truthy

          post api("/features/#{feature_name}", admin), params: { value: 'false', user: user.username }

          expect(response).to have_gitlab_http_status(:created)
          expect(json_response).to match(
            'name' => feature_name,
            'state' => 'off',
            'gates' => [{ 'key' => 'boolean', 'value' => false }],
            'definition' => known_feature_flag_definition_hash
          )
        end
      end

      context 'with a pre-existing percentage of time value' do
        before do
          Feature.enable_percentage_of_time(feature_name, 50)
        end

        it 'updates the percentage of time if passed an integer' do
          post api("/features/#{feature_name}", admin), params: { value: '30' }

          expect(response).to have_gitlab_http_status(:created)
          expect(json_response).to match(
            'name' => feature_name,
            'state' => 'conditional',
            'gates' => [
              { 'key' => 'boolean', 'value' => false },
              { 'key' => 'percentage_of_time', 'value' => 30 }
            ],
            'definition' => known_feature_flag_definition_hash
          )
        end
      end

      context 'with a pre-existing percentage of actors value' do
        before do
          Feature.enable_percentage_of_actors(feature_name, 42)
        end

        it 'updates the percentage of actors if passed an integer' do
          post api("/features/#{feature_name}", admin), params: { value: '74', key: 'percentage_of_actors' }

          expect(response).to have_gitlab_http_status(:created)
          expect(json_response).to match(
            'name' => feature_name,
            'state' => 'conditional',
            'gates' => [
              { 'key' => 'boolean', 'value' => false },
              { 'key' => 'percentage_of_actors', 'value' => 74 }
            ],
            'definition' => known_feature_flag_definition_hash
          )
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

        it 'logs the event' do
          expect(Feature.logger).to receive(:info).once

          delete api("/features/#{feature_name}", admin)
        end
      end
    end
  end
end
