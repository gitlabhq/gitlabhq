require 'spec_helper'

describe Mattermost::Commands::MergeRequestShowService, service: true do
  describe '#execute' do
    let!(:merge_request)  { create(:merge_request) }
    let(:project)         { merge_request.source_project }
    let(:user)            { merge_request.author }
    let(:params)          { { text: "mergerequest show #{merge_request.iid}" } }

    before { project.team << [user, :master] }

    subject { described_class.new(project, user, params).execute }

    context 'the merge request exists' do
      it 'returns the merge request' do
        expect(subject[:response_type]).to be :in_channel
        expect(subject[:text]).to match merge_request.title
      end
    end

    context 'the merge request does not exist' do
      let(:params) { { text: "mergerequest show 12345" } }

      it "returns nil" do
        expect(subject[:response_type]).to be :ephemeral
        expect(subject[:text]).to start_with '404 not found!'
      end
    end
  end
end
