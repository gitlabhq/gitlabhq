# frozen_string_literal: true
require 'spec_helper'

RSpec.describe Gitlab::SlashCommands::Presenters::IssueNew do
  include Gitlab::Routing
  let(:project) { create(:project) }
  let(:issue) { create(:issue, project: project) }

  subject { described_class.new(issue).present }

  it { is_expected.to be_a(Hash) }

  it 'shows the issue' do
    expected_text = "I created an issue on <#{url_for(issue.author)}|#{issue.author.to_reference}>'s behalf: *<#{project_issue_url(issue.project, issue)}|#{issue.to_reference}>* in <#{project.web_url}|#{project.full_name}>"

    expect(subject).to eq(
      response_type: :in_channel,
      status: 200,
      text: expected_text
    )
  end
end
