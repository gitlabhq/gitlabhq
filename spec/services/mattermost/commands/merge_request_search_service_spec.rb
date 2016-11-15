require 'spec_helper'

describe Mattermost::Commands::MergeRequestSearchService, service: true do
  describe '#execute' do
    let!(:merge_request) { create(:merge_request, title: 'The bird is the word') }
    let(:project)        { merge_request.source_project }
    let(:user)           { merge_request.author }
    let(:params)         { { text: "mergerequest search #{merge_request.title}" } }

    before { project.team << [user, :master] }

    subject { described_class.new(project, user, params).execute }

    context 'the merge request exists' do
      it 'returns the merge request' do
        expect(subject[:response_type]).to be :in_channel
        expect(subject[:text]).to match merge_request.title
      end
    end

    context 'no results can be found' do
      let(:params) { { text: "mergerequest search 12345" } }

      it "returns a 404 message" do
        expect(subject[:response_type]).to be :ephemeral
        expect(subject[:text]).to start_with '404 not found!'
      end
    end
  end
end
