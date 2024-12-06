# frozen_string_literal: true

require 'spec_helper'

RSpec.shared_examples "a user type with merge request interaction type" do
  specify { expect(described_class).to require_graphql_authorizations(:read_user) }

  it 'has the expected fields' do
    expected_fields = %w[
      id
      active
      bot
      human
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
      organizations
      groupMemberships
      groupCount
      projectMemberships
      starredProjects
      contributedProjects
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
      userAchievements
      bio
      linkedin
      twitter
      discord
      organization
      jobTitle
      createdAt
      lastActivityOn
      pronouns
      ide
      userPreferences
      type
    ]

    # TODO: 'workspaces' needs to be included, but only when this spec is run in EE context, to account for the
    #       ee-only extension in ee/app/graphql/ee/types/user_interface.rb. Not sure how else to handle this.
    expected_fields << 'workspaces' if Gitlab.ee?

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
