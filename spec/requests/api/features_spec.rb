# frozen_string_literal: true

require 'spec_helper'

RSpec.describe API::Features, stub_feature_flags: false, feature_category: :feature_flags do
  let_it_be(:user) { create(:user) }
  let_it_be(:opted_out) { create(:user) }
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
    skip_default_enabled_yaml_check
  end

  describe 'GET /features' do
    let(:expected_features) do
      [
        {
          'name' => 'feature_1',
          'state' => 'on',
          'gates' => [
            { 'key' => 'boolean', 'value' => true },
            { 'key' => 'actors', 'value' => ["#{opted_out.flipper_id}:opt_out"] }
          ],
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
      Feature.opt_out('feature_1', opted_out)
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

    # TODO: remove this shared examples block when set_feature_flag_service feature flag
    # is removed. Then remove also any duplicate specs covered by the service class.
    shared_examples 'sets the feature flag status' do
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

        shared_examples 'does not enable the flag' do |actor_type|
          let(:actor_path) { raise NotImplementedError }
          let(:expected_inexistent_path) { actor_path }

          it 'returns the current state of the flag without changes' do
            post api("/features/#{feature_name}", admin), params: { value: 'true', actor_type => actor_path }

            expect(response).to have_gitlab_http_status(:bad_request)
            expect(json_response['message']).to eq("400 Bad request - #{expected_inexistent_path} is not found!")
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
                { 'key' => 'actors', 'value' => [actor.flipper_id] }
              ],
              'definition' => known_feature_flag_definition_hash
            )
          end
        end

        shared_examples 'creates an enabled feature for the specified entries' do
          it do
            post api("/features/#{feature_name}", admin), params: { value: 'true', **gate_params }

            expect(response).to have_gitlab_http_status(:created)
            expect(json_response['name']).to eq(feature_name)
            expect(json_response['gates']).to contain_exactly(
              { 'key' => 'boolean', 'value' => false },
              { 'key' => 'actors', 'value' => array_including(expected_gate_params) }
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
            it_behaves_like 'does not enable the flag', :project do
              let(:actor_path) { 'mep/to/the/mep/mep' }
            end
          end
        end

        context 'when enabling for a group by path' do
          context 'when the group exists' do
            it_behaves_like 'enables the flag for the actor', :group do
              let(:actor) { create(:group) }
            end
          end

          context 'when the group does not exist' do
            it_behaves_like 'does not enable the flag', :group do
              let(:actor_path) { 'not/a/group' }
            end
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
            it_behaves_like 'does not enable the flag', :namespace do
              let(:actor_path) { 'not/a/group' }
            end
          end

          context 'when a project namespace exists' do
            let(:project_namespace) { create(:project_namespace) }

            it_behaves_like 'does not enable the flag', :namespace do
              let(:actor_path) { project_namespace.full_path }
            end
          end
        end

        context 'when enabling for a repository by path' do
          context 'when the repository exists' do
            it_behaves_like 'enables the flag for the actor', :repository do
              let_it_be(:actor) { create(:project).repository }
            end
          end

          context 'when the repository does not exist' do
            it_behaves_like 'does not enable the flag', :repository do
              let(:actor_path) { 'not/a/repository' }
            end
          end
        end

        context 'with multiple users' do
          let_it_be(:users) { create_list(:user, 3) }

          it_behaves_like 'creates an enabled feature for the specified entries' do
            let(:gate_params) { { user: users.map(&:username).join(',') } }
            let(:expected_gate_params) { users.map(&:flipper_id) }
          end

          context 'when empty value exists between comma' do
            it_behaves_like 'creates an enabled feature for the specified entries' do
              let(:gate_params) { { user: "#{users.first.username},,,," } }
              let(:expected_gate_params) { users.first.flipper_id }
            end
          end

          context 'when one of the users does not exist' do
            it_behaves_like 'does not enable the flag', :user do
              let(:actor_path) { "#{users.first.username},inexistent-entry" }
              let(:expected_inexistent_path) { "inexistent-entry" }
            end
          end
        end

        context 'with multiple projects' do
          let_it_be(:projects) { create_list(:project, 3) }

          it_behaves_like 'creates an enabled feature for the specified entries' do
            let(:gate_params) { { project: projects.map(&:full_path).join(',') } }
            let(:expected_gate_params) { projects.map(&:flipper_id) }
          end

          context 'when empty value exists between comma' do
            it_behaves_like 'creates an enabled feature for the specified entries' do
              let(:gate_params) { { project: "#{projects.first.full_path},,,," } }
              let(:expected_gate_params) { projects.first.flipper_id }
            end
          end

          context 'when one of the projects does not exist' do
            it_behaves_like 'does not enable the flag', :project do
              let(:actor_path) { "#{projects.first.full_path},inexistent-entry" }
              let(:expected_inexistent_path) { "inexistent-entry" }
            end
          end
        end

        context 'with multiple groups' do
          let_it_be(:groups) { create_list(:group, 3) }

          it_behaves_like 'creates an enabled feature for the specified entries' do
            let(:gate_params) { { group: groups.map(&:full_path).join(',') } }
            let(:expected_gate_params) { groups.map(&:flipper_id) }
          end

          context 'when empty value exists between comma' do
            it_behaves_like 'creates an enabled feature for the specified entries' do
              let(:gate_params) { { group: "#{groups.first.full_path},,,," } }
              let(:expected_gate_params) { groups.first.flipper_id }
            end
          end

          context 'when one of the groups does not exist' do
            it_behaves_like 'does not enable the flag', :group do
              let(:actor_path) { "#{groups.first.full_path},inexistent-entry" }
              let(:expected_inexistent_path) { "inexistent-entry" }
            end
          end
        end

        context 'with multiple namespaces' do
          let_it_be(:namespaces) { create_list(:namespace, 3) }

          it_behaves_like 'creates an enabled feature for the specified entries' do
            let(:gate_params) { { namespace: namespaces.map(&:full_path).join(',') } }
            let(:expected_gate_params) { namespaces.map(&:flipper_id) }
          end

          context 'when empty value exists between comma' do
            it_behaves_like 'creates an enabled feature for the specified entries' do
              let(:gate_params) { { namespace: "#{namespaces.first.full_path},,,," } }
              let(:expected_gate_params) { namespaces.first.flipper_id }
            end
          end

          context 'when one of the namespaces does not exist' do
            it_behaves_like 'does not enable the flag', :namespace do
              let(:actor_path) { "#{namespaces.first.full_path},inexistent-entry" }
              let(:expected_inexistent_path) { "inexistent-entry" }
            end
          end
        end

        context 'with multiple repository' do
          let_it_be(:projects) { create_list(:project, 3) }

          it_behaves_like 'creates an enabled feature for the specified entries' do
            let(:gate_params) { { repository: projects.map { |p| p.repository.full_path }.join(',') } }
            let(:expected_gate_params) { projects.map { |p| p.repository.flipper_id } }
          end

          context 'when empty value exists between comma' do
            it_behaves_like 'creates an enabled feature for the specified entries' do
              let(:gate_params) { { repository: "#{projects.first.repository.full_path},,,," } }
              let(:expected_gate_params) { projects.first.repository.flipper_id }
            end
          end

          context 'when one of the projects does not exist' do
            it_behaves_like 'does not enable the flag', :project do
              let(:actor_path) { "#{projects.first.repository.full_path},inexistent-entry" }
              let(:expected_inexistent_path) { "inexistent-entry" }
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

        describe 'mutually exclusive parameters' do
          shared_examples 'fails to set the feature flag' do
            it 'returns an error' do
              expect(response).to have_gitlab_http_status(:bad_request)
              expect(json_response['error']).to match(/key, \w+ are mutually exclusive/)
            end
          end

          context 'when key and feature_group are provided' do
            before do
              post api("/features/#{feature_name}", admin), params: { value: '0.01', key: 'percentage_of_actors', feature_group: 'some-value' }
            end

            it_behaves_like 'fails to set the feature flag'
          end

          context 'when key and user are provided' do
            before do
              post api("/features/#{feature_name}", admin), params: { value: '0.01', key: 'percentage_of_actors', user: 'some-user' }
            end

            it_behaves_like 'fails to set the feature flag'
          end

          context 'when key and group are provided' do
            before do
              post api("/features/#{feature_name}", admin), params: { value: '0.01', key: 'percentage_of_actors', group: 'somepath' }
            end

            it_behaves_like 'fails to set the feature flag'
          end

          context 'when key and namespace are provided' do
            before do
              post api("/features/#{feature_name}", admin), params: { value: '0.01', key: 'percentage_of_actors', namespace: 'somepath' }
            end

            it_behaves_like 'fails to set the feature flag'
          end

          context 'when key and project are provided' do
            before do
              post api("/features/#{feature_name}", admin), params: { value: '0.01', key: 'percentage_of_actors', project: 'somepath' }
            end

            it_behaves_like 'fails to set the feature flag'
          end
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

    before do
      stub_feature_flags(set_feature_flag_service: true)
    end

    it_behaves_like 'sets the feature flag status'

    it 'opts given actors out' do
      Feature.enable(feature_name)
      expect(Feature.enabled?(feature_name, user)).to be_truthy

      post api("/features/#{feature_name}", admin), params: { value: 'opt_out', user: user.username }

      expect(response).to have_gitlab_http_status(:created)
      expect(json_response).to include(
        'name' => feature_name,
        'state' => 'on',
        'gates' => [
          { 'key' => 'boolean', 'value' => true },
          { 'key' => 'actors', 'value' => ["#{user.flipper_id}:opt_out"] }
        ]
      )
    end

    context 'when the actor has opted-out' do
      before do
        Feature.enable(feature_name)
        Feature.opt_out(feature_name, user)
      end

      it 'refuses to enable the feature' do
        post api("/features/#{feature_name}", admin), params: { value: 'true', user: user.username }

        expect(Feature).not_to be_enabled(feature_name, user)

        expect(response).to have_gitlab_http_status(:bad_request)
      end
    end

    context 'when feature flag set_feature_flag_service is disabled' do
      before do
        stub_feature_flags(set_feature_flag_service: false)
      end

      it_behaves_like 'sets the feature flag status'

      it 'rejects opt_out requests' do
        Feature.enable(feature_name)
        expect(Feature).to be_enabled(feature_name, user)

        post api("/features/#{feature_name}", admin), params: { value: 'opt_out', user: user.username }

        expect(response).to have_gitlab_http_status(:bad_request)
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
