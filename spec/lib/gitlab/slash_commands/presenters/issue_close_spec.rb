# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::SlashCommands::Presenters::IssueClose do
  let(:project) { create(:project) }
  let(:issue) { create(:issue, project: project) }
  let(:attachment) { subject[:attachments].first }

  subject { described_class.new(issue).present }

  it { is_expected.to be_a(Hash) }

  it 'shows the issue' do
    expect(subject[:response_type]).to be(:in_channel)
    expect(subject).to have_key(:attachments)
    expect(attachment[:title]).to start_with(issue.title)
  end

  context 'confidential issue' do
    let(:issue) { create(:issue, :confidential, project: project) }

    it 'shows an ephemeral response' do
      expect(subject[:response_type]).to be(:ephemeral)
    end
  end
end
