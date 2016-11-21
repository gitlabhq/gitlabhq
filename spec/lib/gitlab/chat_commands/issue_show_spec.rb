require 'spec_helper'

describe Gitlab::ChatCommands::IssueShow, service: true do
  describe '#execute' do
    let(:issue) { create(:issue) }
    let(:project) { issue.project }
    let(:user) { issue.author }
    let(:regex_match) { described_class.match("issue show #{issue.iid}") }

    before do
      project.team << [user, :master]
    end

    subject do
      described_class.new(project, user).execute(regex_match)
    end

    context 'the issue exists' do
      it 'returns the issue' do
        expect(subject.iid).to be issue.iid
      end
    end

    context 'the issue does not exist' do
      let(:regex_match) { described_class.match("issue show 2343242") }

      it "returns nil" do
        expect(subject).to be_nil
      end
    end
  end

  describe 'self.match' do
    it 'matches the iid' do
      match = described_class.match("issue show 123")

      expect(match[:iid]).to eq("123")
    end
  end
end
