require 'spec_helper'

describe Gitlab::ChatCommands::IssueShow, service: true do
  describe '#execute' do
    let(:issue)    { create(:issue) }
    let(:project)  { issue.project }
    let(:user)     { issue.author }
    let(:regex_match) { described_class.match("issue show #{issue.iid}") }

    before { project.team << [user, :master] }

    subject { described_class.new(project, user).execute(regex_match) }

    context 'the issue exists' do
      it 'returns the issue' do
        expect(subject[:response_type]).to be :in_channel
        expect(subject[:text]).to match issue.title
      end
    end

    context 'the issue does not exist' do
      let(:regex_match) { described_class.match("issue show 1234") }

      it "returns nil" do
        expect(subject[:response_type]).to be :ephemeral
        expect(subject[:text]).to start_with '404 not found!'
      end
    end
  end
end
