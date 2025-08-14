# frozen_string_literal: true

require "spec_helper"

RSpec.shared_examples "expose all link paths fields for the namespace" do
  include GraphqlHelpers

  let(:type_specific_fields) { [] }

  specify do
    expected_fields = %i[
      contributionGuidePath
      issuesList
      labelsManage
      newCommentTemplate
      newProject
      register
      reportAbuse
      signIn
      userExportEmail
    ]

    expected_fields.push(*type_specific_fields)

    if Gitlab.ee?
      expected_fields.push(*%i[
        epicsList
        groupIssues
        labelsFetch
        issuesSettings
      ])
    end

    expect(described_class).to have_graphql_fields(*expected_fields)
  end
end

RSpec.shared_examples "common namespace link paths values" do
  include GraphqlHelpers
  using RSpec::Parameterized::TableSyntax

  where(:field, :value) do
    :register | "/users/sign_up?redirect_to_referer=yes"
    :report_abuse | "/-/abuse_reports/add_category"
    :sign_in | "/users/sign_in?redirect_to_referer=yes"
  end

  with_them do
    it { expect(resolve_field(field, namespace, current_user: user)).to eq(value) }
  end
end
