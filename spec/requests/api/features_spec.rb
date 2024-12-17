# frozen_string_literal: true

require 'spec_helper'

RSpec.describe API::Features, :clean_gitlab_redis_feature_flag, stub_feature_flags: false, feature_category: :feature_flags do
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

    skip_default_enabled_yaml_check
  end

  describe 'GET /features' do
    let(:path) { '/features' }

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

    it_behaves_like 'GET request permissions for admin mode'

    it 'returns a 401 for anonymous users' do
      get api(path)

      expect(response).to have_gitlab_http_status(:unauthorized)
    end

    it 'returns the feature list for admins' do
      get api(path, admin, admin_mode: true)

      expect(json_response).to match_array(expected_features)
    end
  end

  describe 'POST /feature' do
    let(:feature_name) { known_feature_flag.name }
    let(:path) { "/features/#{feature_name}" }

    it_behaves_like 'POST request permissions for admin mode' do
      let(:params) { { value: 'true' } }
    end

    it 'returns a 401 for anonymous users' do
      post api(path)

      expect(response).to have_gitlab_http_status(:unauthorized)
    end

    context 'when the service responds with any error' do
      before do
        allow_next_instance_of(Admin::SetFeatureFlagService) do |service|
          allow(service).to receive(:execute).and_return(ServiceResponse.error(message: 'error'))
        end
      end

      it 'returns a 400 with the error message' do
        post api(path, admin, admin_mode: true), params: { value: 'true' }

        expect(response).to have_gitlab_http_status(:bad_request)
        expect(json_response).to eq({ 'message' => '400 Bad request - error' })
      end
    end

    shared_examples 'enables the flag for the actor' do |actor_type|
      it 'sets the feature gate' do
        post api(path, admin, admin_mode: true), params: { value: 'true', actor_type => actor.full_path }

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

    context 'when enabling for a project by path' do
      it_behaves_like 'enables the flag for the actor', :project do
        let(:actor) { create(:project) }
      end
    end

    context 'when enabling for a group by path' do
      it_behaves_like 'enables the flag for the actor', :group do
        let(:actor) { create(:group) }
      end
    end

    context 'when enabling for a namespace by path' do
      it_behaves_like 'enables the flag for the actor', :namespace do
        let(:actor) { create(:namespace) }
      end
    end

    context 'when enabling for a repository by path' do
      it_behaves_like 'enables the flag for the actor', :repository do
        let_it_be(:actor) { create(:project).repository }
      end
    end

    context 'when the value argument is missing' do
      it 'returns a 400' do
        post api("/features/#{feature_name}", admin, admin_mode: true)

        expect(response).to have_gitlab_http_status(:bad_request)
        expect(json_response).to eq('error' => 'value is missing')
      end
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
          post api("/features/#{feature_name}", admin, admin_mode: true), params: { value: '0.01', key: 'percentage_of_actors', feature_group: 'some-value' }
        end

        it_behaves_like 'fails to set the feature flag'
      end

      context 'when key and user are provided' do
        before do
          post api("/features/#{feature_name}", admin, admin_mode: true), params: { value: '0.01', key: 'percentage_of_actors', user: 'some-user' }
        end

        it_behaves_like 'fails to set the feature flag'
      end

      context 'when key and group are provided' do
        before do
          post api("/features/#{feature_name}", admin, admin_mode: true), params: { value: '0.01', key: 'percentage_of_actors', group: 'somepath' }
        end

        it_behaves_like 'fails to set the feature flag'
      end

      context 'when key and namespace are provided' do
        before do
          post api("/features/#{feature_name}", admin, admin_mode: true), params: { value: '0.01', key: 'percentage_of_actors', namespace: 'somepath' }
        end

        it_behaves_like 'fails to set the feature flag'
      end

      context 'when key and project are provided' do
        before do
          post api("/features/#{feature_name}", admin, admin_mode: true), params: { value: '0.01', key: 'percentage_of_actors', project: 'somepath' }
        end

        it_behaves_like 'fails to set the feature flag'
      end
    end
  end

  describe 'DELETE /feature/:name' do
    let(:feature_name) { 'my_feature' }
    let(:path) { "/features/#{feature_name}" }

    it_behaves_like 'DELETE request permissions for admin mode'

    context 'when the user has no access' do
      it 'returns a 401 for anonymous users' do
        delete api(path)

        expect(response).to have_gitlab_http_status(:unauthorized)
      end
    end

    context 'when the user has access' do
      it 'returns 204 when the value is not set' do
        delete api(path, admin, admin_mode: true)

        expect(response).to have_gitlab_http_status(:no_content)
      end

      context 'when the gate value was set' do
        before do
          Feature.enable(feature_name)
        end

        it 'deletes an enabled feature' do
          expect do
            delete api("/features/#{feature_name}", admin, admin_mode: true)
            Feature.reset
          end.to change { Feature.persisted_name?(feature_name) }
            .and change { Feature.enabled?(feature_name, type: :undefined) }

          expect(response).to have_gitlab_http_status(:no_content)
        end

        it 'logs the event' do
          expect(Feature.logger).to receive(:info).once

          delete api("/features/#{feature_name}", admin, admin_mode: true)
        end
      end
    end
  end
end
