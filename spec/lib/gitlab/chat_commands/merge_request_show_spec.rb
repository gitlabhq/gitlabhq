require 'spec_helper'

describe Gitlab::ChatCommands::MergeRequestShow, service: true do
  describe '#execute' do
    let!(:merge_request)  { create(:merge_request) }
    let(:project)         { merge_request.source_project }
    let(:user)            { merge_request.author }
    let(:regex_match)     { described_class.match("mergerequest show #{merge_request.iid}") }

    before { project.team << [user, :master] }

    subject { described_class.new(project, user).execute(regex_match) }

    context 'the merge request exists' do
      it 'returns the merge request' do
        expect(subject[:response_type]).to be :in_channel
        expect(subject[:text]).to match merge_request.title
      end
    end

    context 'the merge request does not exist' do
      let(:regex_match) { described_class.match("mergerequest show 12345") }

      it "returns nil" do
        expect(subject[:response_type]).to be :ephemeral
        expect(subject[:text]).to start_with '404 not found!'
      end
    end
  end

  describe "self.match" do
    it 'matches valid strings' do
      expect(described_class.match("mergerequest show 123")).to be_truthy
      expect(described_class.match("mergerequest show sdf23")).to be_falsy
    end
  end
end
