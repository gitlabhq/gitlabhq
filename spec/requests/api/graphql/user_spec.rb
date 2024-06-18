# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'User', feature_category: :user_profile do
  include GraphqlHelpers

  let_it_be(:current_user) { create(:user) }

  shared_examples 'a working user query' do
    it_behaves_like 'a working graphql query' do
      before do
        # TODO: This license stub is necessary because the remote development workspaces field
        #       defined in the EE version of UserInterface gets picked up here and thus the license
        #       check happens. This comes from the `ancestors` call in
        #       lib/graphql/schema/member/has_fields.rb#fields in the graphql library.
        stub_licensed_features(remote_development: true)

        post_graphql(query, current_user: current_user)
      end
    end

    it 'includes the user' do
      post_graphql(query, current_user: current_user)

      expect(graphql_data['user']).not_to be_nil
    end

    it 'returns no user when global restricted_visibility_levels includes PUBLIC' do
      stub_application_setting(restricted_visibility_levels: [Gitlab::VisibilityLevel::PUBLIC])

      post_graphql(query)

      expect(graphql_data['user']).to be_nil
    end
  end

  context 'when id parameter is used' do
    let(:query) { graphql_query_for(:user, { id: current_user.to_global_id.to_s }) }

    it_behaves_like 'a working user query'
  end

  context 'when username parameter is used' do
    context 'when username is identically cased' do
      let(:query) { graphql_query_for(:user, { username: current_user.username.to_s }) }

      it_behaves_like 'a working user query'
    end

    context 'when username is differently cased' do
      let(:query) { graphql_query_for(:user, { username: current_user.username.to_s.upcase }) }

      it_behaves_like 'a working user query'
    end
  end

  context 'when username and id parameter are used' do
    let_it_be(:query) do
      graphql_query_for(
        :user,
        { id: current_user.to_global_id.to_s, username: current_user.username },
        'id'
      )
    end

    it 'displays an error' do
      post_graphql(query)

      expect_graphql_errors_to_include(
        'One and only one of [id, username] arguments is required.'
      )
    end
  end

  describe 'email fields' do
    before_all do
      current_user.commit_email = current_user.emails.first.email
      current_user.save!
    end

    let_it_be(:query) do
      graphql_query_for(
        :user,
        { username: current_user.username },
        'emails { nodes { email } } commitEmail namespaceCommitEmails { nodes { id } }'
      )
    end

    let_it_be(:email_1) { create(:email, user: current_user) }
    let_it_be(:email_2) { create(:email, user: current_user) }
    let_it_be(:namespace_commit_email_1) { create(:namespace_commit_email, email: email_1) }
    let_it_be(:namespace_commit_email_2) { create(:namespace_commit_email, email: email_2) }

    context 'with permission' do
      it 'returns the relevant email details' do
        post_graphql(query, current_user: current_user)

        expect(graphql_data['user']['emails']['nodes'].pluck('email')).to match_array(
          current_user.emails.map(&:email))
        expect(graphql_data['user']['namespaceCommitEmails']['nodes']).not_to be_empty
        expect(graphql_data['user']['commitEmail']).to eq(current_user.commit_email)
      end
    end

    context 'without permission' do
      it 'does not return email details' do
        post_graphql(query, current_user: create(:user))

        expect(graphql_data['user']['emails']['nodes']).to be_empty
        expect(graphql_data['user']['namespaceCommitEmails']['nodes']).to be_empty
        expect(graphql_data['user']['commitEmail']).to be_nil
      end
    end
  end

  describe 'organizations field' do
    let_it_be(:organization_user) { create(:organization_user, user: current_user) }
    let_it_be(:organization) { organization_user.organization }
    let_it_be(:another_organization) { create(:organization) }
    let_it_be(:another_user) { create(:user) }

    let(:query) do
      graphql_query_for(
        :user,
        { username: current_user.username.to_s.upcase },
        'organizations { nodes { path } }'
      )
    end

    context 'with permission' do
      it 'returns the relevant organization details' do
        post_graphql(query, current_user: current_user)

        expect(graphql_data.dig('user', 'organizations', 'nodes').pluck('path'))
          .to match_array(organization.path)
      end
    end

    context 'without permission' do
      it 'does not return organization details' do
        post_graphql(query, current_user: another_user)

        expect(graphql_data.dig('user', 'organizations', 'nodes')).to be_nil
      end
    end
  end
end
