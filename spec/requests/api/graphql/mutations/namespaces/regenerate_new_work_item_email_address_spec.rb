# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'NamespacesRegenerateNewWorkItemEmailAddress', feature_category: :team_planning do
  include GraphqlHelpers

  let_it_be(:user) { create(:user) }
  let_it_be(:group) { create(:group, :private) }
  let_it_be(:project) { create(:project, group: group) }

  let(:mutation) do
    graphql_mutation(
      :namespaces_regenerate_new_work_item_email_address,
      { full_path: namespace.full_path },
      <<~FIELDS
        namespace {
          id
          fullPath
        }
        errors
      FIELDS
    )
  end

  shared_examples 'successful regeneration' do
    it 'regenerates the new work item email address' do
      expect { post_graphql_mutation(mutation, current_user: user) }
        .to change { user.reload.incoming_email_token }

      expect(response).to have_gitlab_http_status(:success)
      expect(graphql_mutation_response(:namespaces_regenerate_new_work_item_email_address)['namespace']['fullPath'])
        .to eq(namespace.full_path)

      expect(graphql_mutation_response(:namespaces_regenerate_new_work_item_email_address)['errors']).to be_empty
    end
  end

  shared_examples 'permission denied' do
    it 'returns an error' do
      post_graphql_mutation(mutation, current_user: user)

      expect(graphql_errors).to include(
        a_hash_including(
          'message' => 'The resource that you are attempting to access does not exist or you don\'t have ' \
            'permission to perform this action'
        )
      )
    end
  end

  describe 'for group namespace' do
    let(:namespace) { group }

    context 'when work item creation via email is supported' do
      before do
        stub_incoming_email_setting(enabled: true, address: 'incoming+%{key}@localhost.com')
        user.ensure_incoming_email_token!
      end

      context 'when user has access to namespace' do
        before_all do
          group.add_developer(user)
        end

        it 'returns an error about work item creation only being supported for projects' do
          post_graphql_mutation(mutation, current_user: user)

          expect(response).to have_gitlab_http_status(:success)
          expect(graphql_mutation_response(:namespaces_regenerate_new_work_item_email_address)['namespace']).to be_nil
          expect(graphql_mutation_response(:namespaces_regenerate_new_work_item_email_address)['errors'])
            .to include('Work item creation via email is only supported for projects')
        end
      end

      context 'when user does not have access to namespace' do
        it_behaves_like 'permission denied'
      end
    end
  end

  describe 'for project namespace' do
    let(:namespace) { project.project_namespace }

    context 'when work item creation via email is supported' do
      before do
        stub_incoming_email_setting(enabled: true, address: 'incoming+%{key}@localhost.com')
        user.ensure_incoming_email_token!
      end

      context 'when user has access to namespace' do
        before_all do
          project.add_developer(user)
        end

        it_behaves_like 'successful regeneration'
      end

      context 'when user does not have access to namespace' do
        it_behaves_like 'permission denied'
      end
    end

    context 'when work item creation via email is not supported' do
      before do
        stub_incoming_email_setting(enabled: false)
      end

      before_all do
        project.add_developer(user)
      end

      it 'returns an error about work item creation not being supported' do
        post_graphql_mutation(mutation, current_user: user)

        expect(response).to have_gitlab_http_status(:success)
        expect(graphql_mutation_response(:namespaces_regenerate_new_work_item_email_address)['namespace']).to be_nil
        expect(graphql_mutation_response(:namespaces_regenerate_new_work_item_email_address)['errors'])
          .to include('Work item creation via email is not supported')
      end
    end

    context 'when token reset fails' do
      before do
        stub_incoming_email_setting(enabled: true, address: 'incoming+%{key}@localhost.com')
        user.ensure_incoming_email_token!
        allow_next_found_instance_of(User) do |instance|
          allow(instance).to receive(:reset_incoming_email_token!).and_return(false)
        end
      end

      before_all do
        project.add_developer(user)
      end

      it 'returns an error about failed regeneration' do
        post_graphql_mutation(mutation, current_user: user)

        expect(response).to have_gitlab_http_status(:success)
        expect(graphql_mutation_response(:namespaces_regenerate_new_work_item_email_address)['namespace']).to be_nil
        expect(graphql_mutation_response(:namespaces_regenerate_new_work_item_email_address)['errors'])
          .to include('Failed to regenerate new work item email address')
      end
    end
  end
end
