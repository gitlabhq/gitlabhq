# frozen_string_literal: true

require 'spec_helper'

RSpec.shared_examples 'expose all link paths fields for the namespace' do
  include GraphqlHelpers

  specify do
    expected_fields = %i[
      issuesList
      labelsManage
      newCommentTemplate
      newProject
      register
      reportAbuse
      signIn
    ]

    if Gitlab.ee?
      expected_fields.push(*%i[
        labelsFetch
        epicsList
        groupIssues
      ])
    end

    expect(described_class).to have_graphql_fields(*expected_fields)
  end
end
