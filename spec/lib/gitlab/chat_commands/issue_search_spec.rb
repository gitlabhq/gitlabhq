require 'spec_helper'

describe Gitlab::ChatCommands::IssueSearch, service: true do
  describe '#execute' do
    let!(:issue)    { create(:issue, title: 'The bird is the word') }
    let(:project)  { issue.project }
    let(:user)     { issue.author }
    let(:regex_match) { described_class.match("issue search bird is the") }

    before { project.team << [user, :master] }

    subject { described_class.new(project, user).execute(regex_match) }

    context 'without results' do
      let(:regex_match) { described_class.match("issue search no results for this one") }

      it "returns nil" do
        expect(subject[:response_type]).to be :ephemeral
        expect(subject[:text]).to start_with '404 not found!'
      end
    end

    context 'with 1 result' do
      it 'returns the issue' do
        expect(subject[:response_type]).to be :in_channel
        expect(subject[:text]).to match issue.title
      end
    end

    context 'with 2 or more results' do
      let!(:issue2) { create(:issue, project: project, title: 'bird is the word!') }

      it 'returns multiple resources' do
        expect(subject[:response_type]).to be :ephemeral
        expect(subject[:text]).to start_with 'Multiple results were found'
      end
    end
  end
end
