require 'spec_helper'

describe Gitlab::ChatCommands::Command, service: true do
  let(:project) { create(:empty_project) }
  let(:user) { create(:user) }

  subject { described_class.new(project, user, params).execute }

  describe '#execute' do
    context 'when no command is available' do
      let(:params) { { text: 'issue show 1' } }
      let(:project) { create(:project, has_external_issue_tracker: true) }

      it 'displays 404 messages' do
        expect(subject[:response_type]).to be(:ephemeral)
        expect(subject[:text]).to start_with('404 not found')
      end
    end

    context 'when an unknown command is triggered' do
      let(:params) { { command: '/gitlab', text: "unknown command 123" } }

      it 'displays the help message' do
        expect(subject[:response_type]).to be(:ephemeral)
        expect(subject[:text]).to start_with('Available commands')
        expect(subject[:text]).to match('/gitlab issue show')
      end
    end

    context 'the user can not create an issue' do
      let(:params) { { text: "issue create my new issue" } }

      it 'rejects the actions' do
        expect(subject[:response_type]).to be(:ephemeral)
        expect(subject[:text]).to start_with('Whoops! That action is not allowed')
      end
    end

    context 'issue is successfully created' do
      let(:params) { { text: "issue create my new issue" } }

      before do
        project.team << [user, :master]
      end

      it 'presents the issue' do
        expect(subject[:text]).to match("my new issue")
      end

      it 'shows a link to the new issue' do
        expect(subject[:text]).to match(/\/issues\/\d+/)
      end
    end
  end
end
