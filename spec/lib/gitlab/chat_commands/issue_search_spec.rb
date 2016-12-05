require 'spec_helper'

describe Gitlab::ChatCommands::IssueSearch, service: true do
  describe '#execute' do
    let!(:issue) { create(:issue, title: 'find me', project: project) }
    let!(:confidential) { create(:issue, :confidential, project: project, title: 'mepmep find') }
    let(:project) { create(:empty_project, :public) }
    let(:user) { issue.author }
    let(:regex_match) { described_class.match("issue search find") }

    subject do
      described_class.new(project, user).execute(regex_match)
    end

    context 'when the user has no access' do
      it 'only returns one issue' do
        title = subject[:attachments].first[:title]

        is_expected.to have_key(:attachments)
        is_expected.not_to have_key(:text)
        expect(title).to eq(issue.title)
      end
    end

    context 'the user has access' do
      before do
        project.team << [user, :master]
      end

      it 'returns all results' do
        expect(subject[:text]).to match /^- <\S+\|#{confidential.title}>$/
        expect(subject[:text]).to match /^- <\S+\|#{issue.title}>$/
      end
    end

    context 'without hits on the query' do
      let(:regex_match) { described_class.match("issue search no matching item") }

      it 'returns an empty collection' do
        expect(subject[:response_type]).to be(:ephemeral)
        expect(subject[:text]).to start_with("404 not found!")
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
