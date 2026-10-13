# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::SlashCommands::Presenters::IssueSearch, feature_category: :team_planning do
  let(:project) { create(:project) }
  let(:message) { subject[:text] }

  before do
    create_list(:issue, 2, project: project)
  end

  subject { described_class.new(project.issues).present }

  it 'formats the message correct' do
    is_expected.to have_key(:text)
    is_expected.to have_key(:status)
    is_expected.to have_key(:response_type)
    is_expected.to have_key(:attachments)
  end

  it 'shows a list of results' do
    expect(subject[:response_type]).to be(:ephemeral)

    expect(message).to start_with("Here are the 2 issues I found")
  end

  context 'when an issue title contains an HTML link' do
    let(:title) { '<a href="https://evil.example.com">https://gitlab.example.com/issue</a>' }

    before do
      create(:issue, project: project, title: title)
    end

    it 'does not convert the HTML link into a Slack link' do
      text = subject[:attachments].map { |attachment| attachment[:text] }.join("\n")

      expect(text).to include('https://gitlab.example.com/issue')
      expect(text).not_to include('<https://evil.example.com')
    end
  end

  context 'when an issue title contains Slack or Markdown link markup' do
    let(:title) do
      '<https://evil.example.com|https://gitlab.example.com/issue> [https://gitlab.example.com/x](https://evil.example.com)'
    end

    before do
      create(:issue, project: project, title: title)
    end

    it 'strips the markup and renders the title as plain text' do
      text = subject[:attachments].map { |attachment| attachment[:text] }.join("\n")
      fallback = subject[:attachments].map { |attachment| attachment[:fallback] }.join("\n")

      expect(text).to include('https://gitlab.example.com/issue')
      expect(text).not_to include('<https://evil.example.com')
      expect(fallback).to include('https://gitlab.example.com/issue')
      expect(fallback).not_to include('<https://evil.example.com')
    end
  end
end
