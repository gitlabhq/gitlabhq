require 'spec_helper'

describe Gitlab::ChatCommands::IssueShow, service: true do
  describe '#execute' do
    let(:issue) { create(:issue, project: project) }
    let(:project) { create(:empty_project) }
    let(:user) { issue.author }
    let(:title) { subject[:attachments].first[:title] }

    before do
      project.team << [user, :master]
    end

    subject do
      described_class.new(project, user).execute(regex_match)
    end

    context 'the issue exists' do
      let(:regex_match) { described_class.match("issue show #{issue.iid}") }

      it 'returns the issue' do
        expect(title).to eq(issue.title)
      end
    end

    context 'the issue does not exist' do
      let(:regex_match) { described_class.match("issue show 2343242") }

      it "returns nil" do
        expect(subject[:response_type]).to be(:ephemeral)
        expect(subject).not_to have_key(:attachments)
      end
    end
  end

  describe 'self.match' do
    it 'matches the iid' do
      match = described_class.match("issue show 123")

      expect(match[:iid]).to eq("123")
    end

    it 'allows the reference_pattern first' do
      match = described_class.match("issue show #123")

      expect(match[:iid]).to eq("123")
    end
  end
end
