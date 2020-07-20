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

  context 'confidential issue' do
    let(:issue) { create(:issue, project: project) }

    it 'shows an ephemeral response' do
      expect(subject[:response_type]).to be(:in_channel)
      expect(attachment[:text]).to start_with("**Open**")
    end
  end
end
