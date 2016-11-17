require 'spec_helper'

describe Gitlab::ChatCommands::Command, service: true do
  let(:project)         { create(:project) }
  let(:user)            { create(:user) }
  let(:params)          { { text: 'issue show 1' } }

  subject { described_class.new(project, user, params).execute }

  describe '#execute' do
    context 'when the command is not available' do
      let(:project) { create(:project, has_external_issue_tracker: true) }

      it 'displays the help message' do
        expect(subject[:response_type]).to be(:ephemeral)
        expect(subject[:text]).to start_with('Available commands')
      end
    end

    context 'when an unknown command is triggered' do
      let(:params) { { text: "unknown command 123" } }

      it 'displays the help message' do
        expect(subject[:response_type]).to be(:ephemeral)
        expect(subject[:text]).to start_with('Available commands')
      end
    end
  end
end
