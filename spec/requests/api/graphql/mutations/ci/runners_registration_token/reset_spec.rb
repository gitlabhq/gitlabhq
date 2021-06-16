# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'RunnersRegistrationTokenReset' do
  include GraphqlHelpers

  let(:mutation) { graphql_mutation(:runners_registration_token_reset, input) }
  let(:mutation_response) { graphql_mutation_response(:runners_registration_token_reset) }

  subject { post_graphql_mutation(mutation, current_user: user) }

  shared_examples 'unauthorized' do
    it 'returns an error' do
      subject

      expect(graphql_errors).not_to be_empty
      expect(graphql_errors).to include(a_hash_including('message' => "The resource that you are attempting to access does not exist or you don't have permission to perform this action"))
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
    it 'resets runner registration token' do
      expect { subject }.to change { get_token }
      expect(response).to have_gitlab_http_status(:success)

      expect(mutation_response).not_to be_nil
      expect(mutation_response['errors']).to be_empty
      expect(mutation_response['token']).not_to be_empty
      expect(mutation_response['token']).to eq(get_token)
    end

    context 'when malformed id is provided' do
      let(:input) { { type: "#{scope.upcase}_TYPE", id: 'some string' } }

      it 'returns errors' do
        expect { subject }.not_to change { get_token }

        expect(graphql_errors).not_to be_empty
        expect(mutation_response).to be_nil
      end
    end
  end

  context 'applied to project' do
    let_it_be(:project) { create_default(:project) }

    let(:input) { { type: 'PROJECT_TYPE', id: project.to_global_id.to_s } }

    include_context 'when unauthorized', 'project' do
      let(:target) { project }
    end

    include_context 'when authorized', 'project' do
      let_it_be(:user) { project.owner }

      def get_token
        project.reload.runners_token
      end
    end
  end

  context 'applied to group' do
    let_it_be(:group) { create_default(:group) }

    let(:input) { { type: 'GROUP_TYPE', id: group.to_global_id.to_s } }

    include_context 'when unauthorized', 'group' do
      let(:target) { group }
    end

    include_context 'when authorized', 'group' do
      let_it_be(:user) { create_default(:group_member, :maintainer, user: create(:user), group: group ).user }

      def get_token
        group.reload.runners_token
      end
    end
  end

  context 'applied to instance' do
    before do
      ApplicationSetting.create_from_defaults
      stub_env('IN_MEMORY_APPLICATION_SETTINGS', 'false')
    end

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
