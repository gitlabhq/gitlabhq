# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Setting namespace commit email', feature_category: :user_profile do
  include GraphqlHelpers

  let(:current_user) { create(:user) }
  let(:group) { create(:group, :public) }
  let(:email) { create(:email, :confirmed, user: current_user) }
  let(:input) { {} }
  let(:namespace_id) { group.to_global_id }
  let(:email_id) { email.to_global_id }

  let(:resource_or_permission_error) do
    "The resource that you are attempting to access does not exist or you don't have permission to perform this action"
  end

  let(:mutation) do
    variables = {
      namespace_id: namespace_id,
      email_id: email_id
    }
    graphql_mutation(:user_set_namespace_commit_email, variables.merge(input),
      <<-QL.strip_heredoc
        namespaceCommitEmail {
          email {
            id
          }
        }
        errors
      QL
    )
  end

  def mutation_response
    graphql_mutation_response(:user_set_namespace_commit_email)
  end

  shared_examples 'success' do
    it 'creates a namespace commit email' do
      post_graphql_mutation(mutation, current_user: current_user)

      expect(mutation_response.dig('namespaceCommitEmail', 'email', 'id')).to eq(email.to_global_id.to_s)
      expect(graphql_errors).to be_nil
    end
  end

  before do
    group.add_reporter(current_user)
  end

  context 'when current_user is nil' do
    it 'returns the top level error' do
      post_graphql_mutation(mutation, current_user: nil)

      expect(graphql_errors.first).to match a_hash_including(
        'message' => resource_or_permission_error)
    end
  end

  context 'when the user cannot access the namespace' do
    let(:namespace_id) { create(:group, :private).to_global_id }

    it 'returns the top level error' do
      post_graphql_mutation(mutation, current_user: current_user)

      expect(graphql_errors).not_to be_empty
      expect(graphql_errors.first).to match a_hash_including(
        'message' => resource_or_permission_error)
    end
  end

  context 'when the namespace is public' do
    let(:namespace_id) { create(:group).to_global_id }

    it_behaves_like 'success'
  end

  context 'when the service returns an error' do
    let(:email_id) { create(:email).to_global_id }

    it 'returns the error' do
      post_graphql_mutation(mutation, current_user: current_user)

      expect(mutation_response['errors']).to contain_exactly("Email must be provided.")
      expect(mutation_response['namespaceCommitEmail']).to be_nil
    end
  end

  context 'when namespace is a group' do
    it_behaves_like 'success'
  end

  context 'when namespace is a user' do
    let(:namespace_id) { current_user.namespace.to_global_id }

    it_behaves_like 'success'
  end

  context 'when namespace is a project' do
    let_it_be(:project) { create(:project) }

    let(:namespace_id) { project.project_namespace.to_global_id }

    before do
      project.add_reporter(current_user)
    end

    it_behaves_like 'success'
  end
end
