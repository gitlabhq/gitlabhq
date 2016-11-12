require 'spec_helper'

describe Mattermost::Commands::MergeRequestService do
  let(:project)       { create(:project, :private) }
  let(:merge_request) { create(:merge_request, title: 'Bird is the word', source_project: project) }
  let(:user)          { merge_request.author }

  subject { described_class.new(project, user, params).execute }

  before do
    project.team << [user, :developer]
  end

  context 'show as subcommand' do
    context 'merge request can be found' do
      let(:params) { { text: "mergerequest show #{merge_request.iid}" } }

      it 'returns the merge request' do
        expect(subject).to eq merge_request
      end

      context 'the user has no access' do
        let(:non_member) { create(:user) }
        subject { described_class.new(project, non_member, params).execute }

        it 'returns nil' do
          expect(subject).to eq nil
        end
      end
    end

    context 'merge request can not be found' do
      let(:params) { { text: 'mergerequest show 12345' } }

      it 'returns nil' do
        expect(subject).to eq nil
      end
    end
  end

  context 'search as a subcommand' do
    context 'with results' do
      let(:params) { { text: "mergerequest search is the word" } }

      it 'returns the merge_request' do
        expect(subject).to eq [merge_request]
      end
    end

    context 'without results' do
      let(:params) { { text: 'mergerequest search mepmep' } }

      it 'returns an empty collection' do
        expect(subject).to eq []
      end
    end
  end

  describe 'help_message' do
    context 'issues are disabled' do
      it 'returns nil' do
        allow(described_class).to receive(:available?).and_return false

        expect(described_class.help_message(project)).to eq nil
      end
    end
  end
end
