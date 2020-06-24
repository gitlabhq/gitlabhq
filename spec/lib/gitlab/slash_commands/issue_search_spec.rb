# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::SlashCommands::IssueSearch do
  describe '#execute' do
    let!(:issue) { create(:issue, project: project, title: 'find me') }
    let!(:confidential) { create(:issue, :confidential, project: project, title: 'mepmep find') }
    let(:project) { create(:project) }
    let(:user) { create(:user) }
    let(:chat_name) { double(:chat_name, user: user) }
    let(:regex_match) { described_class.match("issue search find") }

    subject do
      described_class.new(project, chat_name).execute(regex_match)
    end

    context 'when the user has no access' do
      it 'only returns the open issues' do
        expect(subject[:response_type]).to be(:ephemeral)
        expect(subject[:text]).to match("not found")
      end
    end

    context 'the user has access' do
      before do
        project.add_maintainer(user)
      end

      it 'returns all results' do
        expect(subject).to have_key(:attachments)
        expect(subject[:text]).to eq("Here are the 2 issues I found:")
      end
    end

    context 'without hits on the query' do
      it 'returns an empty collection' do
        expect(subject[:text]).to match("not found")
      end
    end
  end

  describe 'self.match' do
    let(:query) { "my search keywords" }

    it 'matches the query' do
      match = described_class.match("issue search #{query}")

      expect(match[:query]).to eq(query)
    end
  end
end
