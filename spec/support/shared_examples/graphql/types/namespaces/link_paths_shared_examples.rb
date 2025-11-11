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
      emailsHelpPagePath
      markdownHelpPath
      quickActionsHelpPath
      rssPath
      calendarPath
      autocompleteAwardEmojisPath
      newTrialPath
      namespaceFullPath
      newIssuePath
      groupPath
      issuesListPath
    ]

    expected_fields.push(*type_specific_fields)

    if Gitlab.ee?
      expected_fields.push(*%i[
        epicsList
        groupIssues
        labelsFetch
        issuesSettings
        epicsListPath
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
    :emails_help_page_path | "/help/development/emails.md#email-namespace"
    :markdown_help_path | "/help/user/markdown.md"
    :quick_actions_help_path | "/help/user/project/quick_actions.md"
    :autocomplete_award_emojis_path | "/-/autocomplete/award_emojis"
  end

  with_them do
    it { expect(resolve_field(field, namespace, current_user: user)).to eq(value) }
  end
end

RSpec.shared_examples 'new trial path behavior' do
  describe '#new_trial_path' do
    context 'when on GitLab.com' do
      before do
        allow(::Gitlab::Saas).to receive(:feature_available?)
          .with(:gitlab_com_subscriptions).and_return(true)
      end

      it 'returns the new trial path with namespace_id' do
        expect(resolve_field(:new_trial_path, namespace, current_user: user))
          .to eq("/-/trials/new?namespace_id=#{expected_namespace_id}")
      end
    end

    context 'when on self-managed' do
      before do
        allow(::Gitlab::Saas).to receive(:feature_available?)
          .with(:gitlab_com_subscriptions).and_return(false)
      end

      it 'returns the self-managed trial URL' do
        path = resolve_field(:new_trial_path, namespace, current_user: user)
        expect(path).to match(%r{/free-trial/|/trials/new})
      end
    end
  end
end
