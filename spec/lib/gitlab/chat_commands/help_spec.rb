require 'spec_helper'

describe Gitlab::ChatCommands::Help do
  describe '#execute' do
    let(:project) { create(:empty_project) }
    let(:commands) { [Gitlab::ChatCommands::IssueShow] }

    subject { described_class.new(project, nil, command: '/trigger').execute(commands) }

    it do
      is_expected.to have_key(:status)
      is_expected.to have_key(:text)
      is_expected.to have_key(:response_type)
      is_expected.not_to have_key(:attachments)
    end

    it 'shows the available issue commands' do
      message = subject[:text]

      expect(message).to start_with("Available commands")
      expect(message).to include("- /trigger issue show")
    end
  end
end
