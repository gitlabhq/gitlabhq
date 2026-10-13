# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::SlashCommands::Presenters::IssueShow do
  let(:user) { create(:user, :with_avatar) }
  let(:project) { create(:project, creator: user) }
  let(:issue) { create(:issue, project: project) }
  let(:attachment) { subject[:attachments].first }

  subject { described_class.new(issue).present }

  it { is_expected.to be_a(Hash) }

  it 'shows the issue' do
    expect(subject[:response_type]).to be(:in_channel)
    expect(subject).to have_key(:attachments)
    expect(attachment[:title]).to start_with(issue.title)
    expect(attachment[:author_icon]).to eq(user.avatar_url(only_path: false))
  end

  context 'with upvotes' do
    before do
      create(:award_emoji, :upvote, awardable: issue)
    end

    it 'shows the upvote count' do
      expect(subject[:response_type]).to be(:in_channel)
      expect(attachment[:text]).to start_with("**Open** · :+1: 1")
    end
  end

  context 'with labels' do
    let(:label) { create(:label, project: project, title: 'mep') }
    let(:label1) { create(:label, project: project, title: 'mop') }

    before do
      issue.labels << [label, label1]
    end

    it 'shows the labels' do
      labels = attachment[:fields].find { |f| f[:title] == 'Labels' }

      expect(labels[:value]).to eq("mep, mop")
    end
  end

  context 'when user-controlled text contains Slack link markup' do
    let(:markup) { '<https://evil.example.com|https://gitlab.example.com/issue>' }
    let(:stripped) { 'https://evil.example.comhttps://gitlab.example.com/issue' }
    let(:assignee) { create(:user) }
    let(:milestone) { create(:milestone, project: project, title: markup) }
    let(:label) { create(:label, project: project, title: markup) }
    let(:issue) do
      create(:issue, project: project, title: markup, milestone: milestone, assignees: [assignee], labels: [label])
    end

    before do
      issue
      # User#sanitize_attrs rewrites the markup on save, so persist it directly to exercise the presenter.
      assignee.update_column(:name, markup)
      user.update_column(:name, markup)
    end

    it 'strips the markup from the title, author, fallback, and fields' do
      expect(attachment[:title]).to start_with(stripped)
      expect(attachment[:author_name]).to eq(stripped)
      expect(attachment[:fallback]).to eq("Issue #{issue.to_reference}: #{stripped}")

      %w[Assignee Milestone Labels].each do |name|
        field = attachment[:fields].find { |f| f[:title] == name }

        expect(field[:value]).to eq(stripped)
      end
    end
  end

  context 'when the project belongs to a user whose name contains a Markdown link' do
    let_it_be(:owner) { create(:user, :with_namespace, name: '[https://gitlab.example.com/x](https://evil.example.com)') }
    let_it_be(:project) { create(:project, namespace: owner.namespace, creator: owner) }

    it 'does not turn the project name into a Slack link' do
      expect(attachment[:pretext]).to include('https://gitlab.example.com/x')
      expect(attachment[:pretext]).not_to include('<https://evil.example.com')
    end
  end

  context 'confidential issue' do
    let(:issue) { create(:issue, project: project) }

    it 'shows an ephemeral response' do
      expect(subject[:response_type]).to be(:in_channel)
      expect(attachment[:text]).to start_with("**Open**")
    end
  end
end
