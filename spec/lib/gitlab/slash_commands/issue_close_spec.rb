# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::SlashCommands::IssueClose do
  describe '#execute' do
    let(:issue) { create(:issue, project: project) }
    let(:project) { create(:project) }
    let(:user) { issue.author }
    let(:chat_name) { double(:chat_name, user: user) }
    let(:regex_match) { described_class.match("issue close #{issue.iid}") }

    subject do
      described_class.new(project, chat_name).execute(regex_match)
    end

    context 'when the user does not have permission' do
      let(:chat_name) { double(:chat_name, user: create(:user)) }

      it 'does not allow the user to close the issue' do
        expect(subject[:response_type]).to be(:ephemeral)
        expect(subject[:text]).to match("not found")
        expect(issue.reload).to be_open
      end
    end

    context 'the issue exists' do
      let(:title) { subject[:attachments].first[:title] }

      it 'closes and returns the issue' do
        expect(subject[:response_type]).to be(:in_channel)
        expect(issue.reload).to be_closed
        expect(title).to start_with(issue.title)
      end

      context 'when its reference is given' do
        let(:regex_match) { described_class.match("issue close #{issue.to_reference}") }

        it 'closes and returns the issue' do
          expect(subject[:response_type]).to be(:in_channel)
          expect(issue.reload).to be_closed
          expect(title).to start_with(issue.title)
        end
      end
    end

    context 'the issue does not exist' do
      let(:regex_match) { described_class.match("issue close 2343242") }

      it "returns not found" do
        expect(subject[:response_type]).to be(:ephemeral)
        expect(subject[:text]).to match("not found")
      end
    end

    context 'when the issue is already closed' do
      let(:issue) { create(:issue, :closed, project: project) }

      it 'shows the issue' do
        expect(subject[:response_type]).to be(:ephemeral)
        expect(issue.reload).to be_closed
        expect(subject[:text]).to match("already closed")
      end
    end
  end

  describe '.match' do
    it 'matches the iid' do
      match = described_class.match("issue close 123")

      expect(match[:iid]).to eq("123")
    end

    it 'accepts a reference' do
      match = described_class.match("issue close #{Issue.reference_prefix}123")

      expect(match[:iid]).to eq("123")
    end
  end
end
