require 'spec_helper'

describe Gitlab::ChatCommands::Command, service: true do
  let(:project) { create(:project) }
  let(:user) { create(:user) }

  subject { described_class.new(project, user, params).execute }

  describe '#execute' do
    context 'when no command is not available' do
      let(:params) { { text: 'issue show 1' } }
      let(:project) { create(:project, has_external_issue_tracker: true) }

      it 'displays the help message' do
        expect(subject[:response_type]).to be(:ephemeral)
        expect(subject[:text]).to start_with('404 not found')
      end
    end

    context 'when an unknown command is triggered' do
      let(:params) { { text: "unknown command 123" } }

      it 'displays the help message' do
        expect(subject[:response_type]).to be(:ephemeral)
        expect(subject[:text]).to start_with('Available commands')
      end
    end

    context 'issue is succesfully created' do
      let(:params) { { text: "issue create my new issue" } }

      before do
        project.team << [user, :master]
      end

      it 'presents the issue' do
        expect(subject[:text]).to match("my new issue")
      end
    end
  end
end
