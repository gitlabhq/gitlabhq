require 'spec_helper'

describe Mattermost::Commands::IssueService do
  let(:project) { create(:project) }
  let(:issue )  { create(:issue, :confidential, title: 'Bird is the word', project: project) }
  let(:user)    { issue.author }

  subject { described_class.new(project, user, params).execute }

  before do
    project.team << [user, :developer]
  end

  describe '#execute' do
    context 'show as subcommand' do
      context 'issue can be found' do
        let(:params) { { text: "issue show #{issue.iid}" } }

        it 'returns the merge request' do
          expect(subject).to eq issue
        end

        context 'the user has no access' do
          let(:non_member) { create(:user) }
          subject { described_class.new(project, non_member, params).execute }

          it 'returns nil' do
            expect(subject).to eq nil
          end
        end
      end

      context 'issue can not be found' do
        let(:params) { { text: 'issue show 12345' } }

        it 'returns nil' do
          expect(subject).to eq nil
        end
      end
    end

    context 'search as a subcommand' do
      context 'with results' do
        let(:params) { { text: "issue search is the word" } }

        it 'returns the issue' do
          expect(subject).to eq [issue]
        end
      end

      context 'without results' do
        let(:params) { { text: 'issue search mepmep' } }

        it 'returns an empty collection' do
          expect(subject).to eq []
        end
      end
    end

    context 'create as subcommand' do
      let(:title)  { 'my new issue' }
      let(:params) { { text: "issue create #{title}" } }

      it 'return the new issue' do
        expect(subject).to be_a Issue
      end

      it 'creates a new issue' do
        expect { subject }.to change { Issue.count }.by(1)
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
