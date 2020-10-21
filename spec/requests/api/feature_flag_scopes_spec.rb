# frozen_string_literal: true
require 'spec_helper'

RSpec.describe API::FeatureFlagScopes do
  include FeatureFlagHelpers

  let(:project) { create(:project, :repository) }
  let(:developer) { create(:user) }
  let(:reporter) { create(:user) }
  let(:user) { developer }

  before do
    project.add_developer(developer)
    project.add_reporter(reporter)
  end

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

  describe 'GET /projects/:id/feature_flag_scopes' do
    subject do
      get api("/projects/#{project.id}/feature_flag_scopes", user),
          params: params
    end

    let(:feature_flag_1) { create_flag(project, 'flag_1', true) }
    let(:feature_flag_2) { create_flag(project, 'flag_2', true) }

    before do
      create_scope(feature_flag_1, 'staging', false)
      create_scope(feature_flag_1, 'production', true)
      create_scope(feature_flag_2, 'review/*', false)
    end

    context 'when environment is production' do
      let(:params) { { environment: 'production' } }

      it_behaves_like 'check user permission'

      it 'returns all effective feature flags under the environment' do
        subject

        expect(response).to have_gitlab_http_status(:ok)
        expect(response).to match_response_schema('public_api/v4/feature_flag_detailed_scopes')
        expect(json_response.second).to include({ 'name' => 'flag_1', 'active' => true })
        expect(json_response.first).to include({ 'name' => 'flag_2', 'active' => true })
      end
    end

    context 'when environment is staging' do
      let(:params) { { environment: 'staging' } }

      it 'returns all effective feature flags under the environment' do
        subject

        expect(response).to have_gitlab_http_status(:ok)
        expect(json_response.second).to include({ 'name' => 'flag_1', 'active' => false })
        expect(json_response.first).to include({ 'name' => 'flag_2', 'active' => true })
      end
    end

    context 'when environment is review/feature X' do
      let(:params) { { environment: 'review/feature X' } }

      it 'returns all effective feature flags under the environment' do
        subject

        expect(response).to have_gitlab_http_status(:ok)
        expect(json_response.second).to include({ 'name' => 'flag_1', 'active' => true })
        expect(json_response.first).to include({ 'name' => 'flag_2', 'active' => false })
      end
    end
  end

  describe 'GET /projects/:id/feature_flags/:name/scopes' do
    subject do
      get api("/projects/#{project.id}/feature_flags/#{feature_flag.name}/scopes", user)
    end

    context 'when there are two scopes' do
      let(:feature_flag) { create_flag(project, 'test') }
      let!(:additional_scope) { create_scope(feature_flag, 'production', false) }

      it_behaves_like 'check user permission'

      it 'returns scopes of the feature flag' do
        subject

        expect(response).to have_gitlab_http_status(:ok)
        expect(response).to match_response_schema('public_api/v4/feature_flag_scopes')
        expect(json_response.count).to eq(2)
        expect(json_response.first['environment_scope']).to eq(feature_flag.scopes[0].environment_scope)
        expect(json_response.second['environment_scope']).to eq(feature_flag.scopes[1].environment_scope)
      end
    end

    context 'when there are no feature flags' do
      let(:feature_flag) { double(:feature_flag, name: 'test') }

      it_behaves_like 'not found'
    end
  end

  describe 'POST /projects/:id/feature_flags/:name/scopes' do
    subject do
      post api("/projects/#{project.id}/feature_flags/#{feature_flag.name}/scopes", user),
           params: params
    end

    let(:params) do
      {
        environment_scope: 'staging',
        active: true,
        strategies: [{ name: 'userWithId', parameters: { 'userIds': 'a,b,c' } }].to_json
      }
    end

    context 'when there is a corresponding feature flag' do
      let!(:feature_flag) { create(:operations_feature_flag, project: project) }

      it_behaves_like 'check user permission'

      it 'creates a new scope' do
        subject

        expect(response).to have_gitlab_http_status(:created)
        expect(response).to match_response_schema('public_api/v4/feature_flag_scope')
        expect(json_response['environment_scope']).to eq(params[:environment_scope])
        expect(json_response['active']).to eq(params[:active])
        expect(json_response['strategies']).to eq(Gitlab::Json.parse(params[:strategies]))
      end

      context 'when the scope already exists' do
        before do
          create_scope(feature_flag, params[:environment_scope])
        end

        it 'returns error' do
          subject

          expect(response).to have_gitlab_http_status(:bad_request)
          expect(json_response['message']).to include('Scopes environment scope (staging) has already been taken')
        end
      end
    end

    context 'when feature flag is not found' do
      let(:feature_flag) { double(:feature_flag, name: 'test') }

      it_behaves_like 'not found'
    end
  end

  describe 'GET /projects/:id/feature_flags/:name/scopes/:environment_scope' do
    subject do
      get api("/projects/#{project.id}/feature_flags/#{feature_flag.name}/scopes/#{environment_scope}",
              user)
    end

    let(:environment_scope) { scope.environment_scope }

    shared_examples_for 'successful response' do
      it 'returns a scope' do
        subject

        expect(response).to have_gitlab_http_status(:ok)
        expect(response).to match_response_schema('public_api/v4/feature_flag_scope')
        expect(json_response['id']).to eq(scope.id)
        expect(json_response['active']).to eq(scope.active)
        expect(json_response['environment_scope']).to eq(scope.environment_scope)
      end
    end

    context 'when there is a feature flag' do
      let!(:feature_flag) { create(:operations_feature_flag, project: project) }
      let(:scope) { feature_flag.default_scope }

      it_behaves_like 'check user permission'
      it_behaves_like 'successful response'

      context 'when environment scope includes slash' do
        let!(:scope) { create_scope(feature_flag, 'review/*', false) }

        it_behaves_like 'not found'

        context 'when URL-encoding the environment scope parameter' do
          let(:environment_scope) { CGI.escape(scope.environment_scope) }

          it_behaves_like 'successful response'
        end
      end
    end

    context 'when there are no feature flags' do
      let(:feature_flag) { double(:feature_flag, name: 'test') }
      let(:scope) { double(:feature_flag_scope, environment_scope: 'prd') }

      it_behaves_like 'not found'
    end
  end

  describe 'PUT /projects/:id/feature_flags/:name/scopes/:environment_scope' do
    subject do
      put api("/projects/#{project.id}/feature_flags/#{feature_flag.name}/scopes/#{environment_scope}",
              user), params: params
    end

    let(:environment_scope) { scope.environment_scope }

    let(:params) do
      {
        active: true,
        strategies: [{ name: 'userWithId', parameters: { 'userIds': 'a,b,c' } }].to_json
      }
    end

    context 'when there is a corresponding feature flag' do
      let!(:feature_flag) { create(:operations_feature_flag, project: project) }
      let(:scope) { create_scope(feature_flag, 'staging', false, [{ name: "default", parameters: {} }]) }

      it_behaves_like 'check user permission'

      it 'returns the updated scope' do
        subject

        expect(response).to have_gitlab_http_status(:ok)
        expect(response).to match_response_schema('public_api/v4/feature_flag_scope')
        expect(json_response['id']).to eq(scope.id)
        expect(json_response['active']).to eq(params[:active])
        expect(json_response['strategies']).to eq(Gitlab::Json.parse(params[:strategies]))
      end

      context 'when there are no corresponding feature flag scopes' do
        let(:scope) { double(:feature_flag_scope, environment_scope: 'prd') }

        it_behaves_like 'not found'
      end
    end

    context 'when there are no corresponding feature flags' do
      let(:feature_flag) { double(:feature_flag, name: 'test') }
      let(:scope) { double(:feature_flag_scope, environment_scope: 'prd') }

      it_behaves_like 'not found'
    end
  end

  describe 'DELETE /projects/:id/feature_flags/:name/scopes/:environment_scope' do
    subject do
      delete api("/projects/#{project.id}/feature_flags/#{feature_flag.name}/scopes/#{environment_scope}",
                 user)
    end

    let(:environment_scope) { scope.environment_scope }

    shared_examples_for 'successful response' do
      it 'destroys the scope' do
        expect { subject }
          .to change { Operations::FeatureFlagScope.exists?(environment_scope: scope.environment_scope) }
          .from(true).to(false)

        expect(response).to have_gitlab_http_status(:no_content)
      end
    end

    context 'when there is a feature flag' do
      let!(:feature_flag) { create(:operations_feature_flag, project: project) }

      context 'when there is a targeted scope' do
        let!(:scope) { create_scope(feature_flag, 'production', false) }

        it_behaves_like 'check user permission'
        it_behaves_like 'successful response'

        context 'when environment scope includes slash' do
          let!(:scope) { create_scope(feature_flag, 'review/*', false) }

          it_behaves_like 'not found'

          context 'when URL-encoding the environment scope parameter' do
            let(:environment_scope) { CGI.escape(scope.environment_scope) }

            it_behaves_like 'successful response'
          end
        end
      end

      context 'when there are no targeted scopes' do
        let!(:scope) { double(:feature_flag_scope, environment_scope: 'production') }

        it_behaves_like 'not found'
      end
    end

    context 'when there are no feature flags' do
      let(:feature_flag) { double(:feature_flag, name: 'test') }
      let(:scope) { double(:feature_flag_scope, environment_scope: 'prd') }

      it_behaves_like 'not found'
    end
  end
end
