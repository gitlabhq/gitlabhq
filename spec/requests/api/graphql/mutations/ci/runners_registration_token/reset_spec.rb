# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'RunnersRegistrationTokenReset', feature_category: :runner do
  include GraphqlHelpers

  let(:mutation) { graphql_mutation(:runners_registration_token_reset, input) }
  let(:mutation_response) { graphql_mutation_response(:runners_registration_token_reset) }

  subject(:request) { post_graphql_mutation(mutation, current_user: user) }

  before do
    stub_application_setting(allow_runner_registration_token: true)
  end

  shared_examples 'unauthorized' do
    it 'returns an error' do
      request

      expect(graphql_errors).not_to be_empty
      expect(graphql_errors).to include(a_hash_including('message' => Gitlab::Graphql::Authorize::AuthorizeResource::RESOURCE_ACCESS_ERROR))
      expect(mutation_response).to be_nil
    end
  end

  shared_context 'when unauthorized' do |scope|
    context 'when unauthorized' do
      let_it_be(:user) { create(:user) }

      context "when not a #{scope} member" do
        it_behaves_like 'unauthorized'
      end

      context "with a non-admin #{scope} member" do
        before do
          target.add_developer(user)
        end

        it_behaves_like 'unauthorized'
      end
    end
  end

  shared_context 'when authorized' do |scope|
    let(:allow_runner_registration_token) { false }

    before do
      stub_application_setting(allow_runner_registration_token: allow_runner_registration_token)
    end

    it 'does not reset runner registration token', :aggregate_failures do
      request

      expect(graphql_errors).not_to be_empty
      expect(graphql_errors).to include(a_hash_including('message' => Gitlab::Graphql::Authorize::AuthorizeResource::RESOURCE_ACCESS_ERROR))
      expect(mutation_response).to be_nil
    end

    context 'when malformed id is provided' do
      let(:input) { { type: "#{scope.upcase}_TYPE", id: 'some string' } }

      it 'returns errors' do
        expect { request }.not_to change { get_token }

        expect(graphql_errors).not_to be_empty
        expect(mutation_response).to be_nil
      end
    end

    context 'when runner registration is allowed' do
      let(:allow_runner_registration_token) { true }

      it 'resets runner registration token' do
        expect { request }.to change { get_token }
        expect(response).to have_gitlab_http_status(:success)

        expect(mutation_response).not_to be_nil
        expect(mutation_response['errors']).to be_empty
        expect(mutation_response['token']).not_to be_empty
        expect(mutation_response['token']).to eq(get_token)
      end
    end
  end

  context 'applied to project' do
    let_it_be(:project) { create_default(:project, :allow_runner_registration_token) }

    let(:target) { project }
    let(:input) { { type: 'PROJECT_TYPE', id: project.to_global_id.to_s } }

    include_context('when unauthorized', 'project')

    include_context 'when authorized', 'project' do
      let_it_be(:user) { project.first_owner }

      def get_token
        project.reload.runners_token
      end
    end
  end

  context 'applied to group' do
    let_it_be(:group) { create(:group, :allow_runner_registration_token) }

    let(:target) { group }
    let(:input) { { type: 'GROUP_TYPE', id: group.to_global_id.to_s } }

    include_context('when unauthorized', 'group')

    include_context 'when authorized', 'group' do
      let_it_be(:user) { create_default(:group_member, :owner, user: create(:user), group: group).user }

      def get_token
        group.reload.runners_token
      end
    end
  end

  context 'applied to instance' do
    before do
      target
      stub_env('IN_MEMORY_APPLICATION_SETTINGS', 'false')
    end

    let_it_be(:target) { ApplicationSetting.create_from_defaults }

    let(:input) { { type: 'INSTANCE_TYPE' } }

    context 'when unauthorized' do
      let(:user) { create(:user) }

      it_behaves_like 'unauthorized'
    end

    include_context 'when authorized', 'instance' do
      let_it_be(:user) { create(:user, :admin) }

      def get_token
        ApplicationSetting.current_without_cache.runners_registration_token
      end
    end
  end
end
