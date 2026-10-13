# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::SlashCommands::Presenters::IssueNew do
  include Gitlab::Routing
  let(:project) { create(:project) }
  let(:issue) { create(:issue, project: project) }

  subject { described_class.new(issue).present }

  it { is_expected.to be_a(Hash) }

  it 'shows the issue' do
    expected_text = "I created an issue on <#{url_for(issue.author)}|#{issue.author.to_reference}>'s behalf: *<#{::Gitlab::UrlBuilder.build(issue)}|#{issue.to_reference}>* in <#{project.web_url}|#{project.full_name}>"

    expect(subject).to eq(
      response_type: :in_channel,
      status: 200,
      text: expected_text
    )
  end

  context 'when the project belongs to a user whose name contains a Markdown link' do
    let_it_be(:owner) { create(:user, :with_namespace, name: '[https://gitlab.example.com/x](https://evil.example.com)') }
    let_it_be(:project) { create(:project, namespace: owner.namespace, creator: owner) }

    it 'links the project name only to the project' do
      expect(subject[:text]).to include("<#{project.web_url}|https://gitlab.example.com/x")
      expect(subject[:text]).not_to include('<https://evil.example.com')
    end
  end
end
