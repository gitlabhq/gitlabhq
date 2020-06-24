# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::SlashCommands::IssueShow do
  describe '#execute' do
    let(:issue) { create(:issue, project: project) }
    let(:project) { create(:project) }
    let(:user) { issue.author }
    let(:chat_name) { double(:chat_name, user: user) }
    let(:regex_match) { described_class.match("issue show #{issue.iid}") }

    before do
      project.add_maintainer(user)
    end

    subject do
      described_class.new(project, chat_name).execute(regex_match)
    end

    context 'the issue exists' do
      let(:title) { subject[:attachments].first[:title] }

      it 'returns the issue' do
        expect(subject[:response_type]).to be(:in_channel)
        expect(title).to start_with(issue.title)
      end

      context 'when its reference is given' do
        let(:regex_match) { described_class.match("issue show #{issue.to_reference}") }

        it 'shows the issue' do
          expect(subject[:response_type]).to be(:in_channel)
          expect(title).to start_with(issue.title)
        end
      end
    end

    context 'the issue does not exist' do
      let(:regex_match) { described_class.match("issue show 2343242") }

      it "returns not found" do
        expect(subject[:response_type]).to be(:ephemeral)
        expect(subject[:text]).to match("not found")
      end
    end
  end

  describe '.match' do
    it 'matches the iid' do
      match = described_class.match("issue show 123")

      expect(match[:iid]).to eq("123")
    end

    it 'accepts a reference' do
      match = described_class.match("issue show #{Issue.reference_prefix}123")

      expect(match[:iid]).to eq("123")
    end
  end
end
