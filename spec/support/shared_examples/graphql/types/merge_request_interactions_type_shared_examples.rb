# frozen_string_literal: true

require 'spec_helper'

RSpec.shared_examples "a user type with merge request interaction type" do
  specify { expect(described_class).to require_graphql_authorizations(:read_user) }

  it 'has the expected fields' do
    expected_fields = %w[
      id
      bot
      user_permissions
      snippets
      name
      username
      email
      emails
      publicEmail
      commitEmail
      namespaceCommitEmails
      avatarUrl
      webUrl
      webPath
      todos
      state
      status
      location
      authoredMergeRequests
      assignedMergeRequests
      reviewRequestedMergeRequests
      groupMemberships
      groupCount
      projectMemberships
      starredProjects
      callouts
      merge_request_interaction
      namespace
      timelogs
      groups
      gitpodEnabled
      preferencesGitpodPath
      profileEnableGitpodPath
      savedReplies
      savedReply
      user_achievements
    ]

    expect(described_class).to have_graphql_fields(*expected_fields)
  end

  describe '#merge_request_interaction' do
    subject { described_class.fields['mergeRequestInteraction'] }

    it 'returns the correct type' do
      is_expected.to have_graphql_type(Types::UserMergeRequestInteractionType)
    end

    it 'has the correct arguments' do
      is_expected.to have_attributes(arguments: be_empty)
    end
  end
end
