require 'spec_helper'

describe Gitlab::ChatCommands::MergeRequestSearch, service: true do
  describe '#execute' do
    let!(:merge_request) { create(:merge_request, title: 'The bird is the word') }
    let(:project)        { merge_request.source_project }
    let(:user)           { merge_request.author }
    let(:regex_match)    { described_class.match("mergerequest search #{merge_request.title}") }

    before { project.team << [user, :master] }

    subject { described_class.new(project, user, {}).execute(regex_match) }

    context 'the merge request exists' do
      it 'returns the merge request' do
        expect(subject[:response_type]).to be :in_channel
        expect(subject[:text]).to match merge_request.title
      end
    end

    context 'no results can be found' do
      let(:regex_match) { described_class.match("mergerequest search 12334") }

      it "returns a 404 message" do
        expect(subject[:response_type]).to be :ephemeral
        expect(subject[:text]).to start_with '404 not found!'
      end
    end
  end

  describe 'self.match' do
    it 'matches a valid query' do
      expect(described_class.match("mergerequest search my title here")).to be_truthy
    end
  end
end
