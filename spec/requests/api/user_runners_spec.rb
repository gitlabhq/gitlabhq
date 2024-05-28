# frozen_string_literal: true

require 'spec_helper'

RSpec.describe API::UserRunners, :aggregate_failures, feature_category: :fleet_visibility do
  let_it_be(:admin) { create(:admin) }
  let_it_be(:user, reload: true) { create(:user, username: 'user.withdot') }

  describe 'POST /user/runners' do
    subject(:request) { post api(path, current_user, **post_args), params: runner_attrs }

    let_it_be(:group) { create(:group) }
    let_it_be(:project) { create(:project, namespace: group) }
    let_it_be(:group_owner) { create(:user, owner_of: group) }
    let_it_be(:group_maintainer) { create(:user, maintainer_of: group) }
    let_it_be(:project_developer) { create(:user, developer_of: project) }

    let(:post_args) { { admin_mode: true } }
    let(:runner_attrs) { { runner_type: 'instance_type' } }
    let(:path) { '/user/runners' }

    shared_examples 'when runner creation fails due to authorization' do
      it 'does not create a runner' do
        expect do
          request

          expect(response).to have_gitlab_http_status(:forbidden)
        end.not_to change { Ci::Runner.count }
      end
    end

    shared_context 'when user does not have sufficient permissions returns forbidden' do
      context 'when user is admin and admin mode is disabled' do
        let(:current_user) { admin }
        let(:post_args) { { admin_mode: false } }

        it_behaves_like 'when runner creation fails due to authorization'
      end

      context 'when user is not an admin or a member of the namespace' do
        let(:current_user) { user }

        it_behaves_like 'when runner creation fails due to authorization'
      end
    end

    shared_examples 'creates a runner' do
      it 'creates a runner' do
        expect do
          request

          expect(response).to have_gitlab_http_status(:created)
        end.to change { Ci::Runner.count }.by(1)
      end
    end

    shared_examples 'fails to create runner with expected_status_code' do
      let(:expected_message) { nil }
      let(:expected_error) { nil }

      it 'does not create runner' do
        expect do
          request

          expect(response).to have_gitlab_http_status(expected_status_code)
          expect(json_response['message']).to include(expected_message) if expected_message
          expect(json_response['error']).to include(expected_error) if expected_error
        end.not_to change { Ci::Runner.count }
      end
    end

    shared_context 'with request authorized with access token' do
      let(:current_user) { nil }
      let(:pat) { create(:personal_access_token, user: token_user, scopes: [scope]) }
      let(:path) { "/user/runners?private_token=#{pat.token}" }

      %i[create_runner api].each do |scope|
        context "with #{scope} scope" do
          let(:scope) { scope }

          it_behaves_like 'creates a runner'
        end
      end

      context 'with read_api scope' do
        let(:scope) { :read_api }

        it_behaves_like 'fails to create runner with expected_status_code' do
          let(:expected_status_code) { :forbidden }
          let(:expected_error) { 'insufficient_scope' }
        end
      end
    end

    context 'when runner_type is :instance_type' do
      let(:runner_attrs) { { runner_type: 'instance_type' } }

      context 'when user has sufficient permissions' do
        let(:current_user) { admin }

        it_behaves_like 'creates a runner'
      end

      context 'with admin mode enabled', :enable_admin_mode do
        let(:token_user) { admin }

        it_behaves_like 'with request authorized with access token'
      end

      it_behaves_like 'when user does not have sufficient permissions returns forbidden'

      context 'when user is not an admin' do
        let(:current_user) { user }

        it_behaves_like 'when runner creation fails due to authorization'
      end

      context 'when model validation fails' do
        let(:runner_attrs) { { runner_type: 'instance_type', run_untagged: false, tag_list: [] } }
        let(:current_user) { admin }

        it_behaves_like 'fails to create runner with expected_status_code' do
          let(:expected_status_code) { :bad_request }
          let(:expected_message) { 'Tags list can not be empty' }
        end
      end
    end

    context 'when runner_type is :group_type' do
      let(:post_args) { {} }

      context 'when group_id is specified' do
        let(:runner_attrs) { { runner_type: 'group_type', group_id: group.id } }

        context 'when user has sufficient permissions' do
          let(:current_user) { group_owner }

          it_behaves_like 'creates a runner'
        end

        it_behaves_like 'with request authorized with access token' do
          let(:token_user) { group_owner }
        end

        it_behaves_like 'when user does not have sufficient permissions returns forbidden'

        context 'when user is a maintainer' do
          let(:current_user) { group_maintainer }

          it_behaves_like 'when runner creation fails due to authorization'
        end
      end

      context 'when group_id is not specified' do
        let(:runner_attrs) { { runner_type: 'group_type' } }
        let(:current_user) { group_owner }

        it 'fails to create runner with :bad_request' do
          expect do
            request

            expect(response).to have_gitlab_http_status(:bad_request)
            expect(json_response['error']).to include('group_id is missing')
          end.not_to change { Ci::Runner.count }
        end
      end
    end

    context 'when runner_type is :project_type' do
      let(:post_args) { {} }

      context 'when project_id is specified' do
        let(:runner_attrs) { { runner_type: 'project_type', project_id: project.id } }

        context 'when user has sufficient permissions' do
          let(:current_user) { group_owner }

          it_behaves_like 'creates a runner'
        end

        it_behaves_like 'with request authorized with access token' do
          let(:token_user) { group_owner }
        end

        it_behaves_like 'when user does not have sufficient permissions returns forbidden'

        context 'when user is a developer' do
          let(:current_user) { project_developer }

          it_behaves_like 'when runner creation fails due to authorization'
        end
      end

      context 'when project_id is not specified' do
        let(:runner_attrs) { { runner_type: 'project_type' } }
        let(:current_user) { group_owner }

        it 'fails to create runner with :bad_request' do
          expect do
            request

            expect(response).to have_gitlab_http_status(:bad_request)
            expect(json_response['error']).to include('project_id is missing')
          end.not_to change { Ci::Runner.count }
        end
      end
    end

    context 'with missing runner_type' do
      let(:runner_attrs) { {} }
      let(:current_user) { admin }

      it 'fails to create runner with :bad_request' do
        expect do
          request

          expect(response).to have_gitlab_http_status(:bad_request)
          expect(json_response['error']).to eq('runner_type is missing, runner_type does not have a valid value')
        end.not_to change { Ci::Runner.count }
      end
    end

    context 'with unknown runner_type' do
      let(:runner_attrs) { { runner_type: 'unknown' } }
      let(:current_user) { admin }

      it 'fails to create runner with :bad_request' do
        expect do
          request

          expect(response).to have_gitlab_http_status(:bad_request)
          expect(json_response['error']).to eq('runner_type does not have a valid value')
        end.not_to change { Ci::Runner.count }
      end
    end

    it 'returns a 401 error if unauthorized' do
      post api(path), params: runner_attrs

      expect(response).to have_gitlab_http_status(:unauthorized)
    end
  end
end
