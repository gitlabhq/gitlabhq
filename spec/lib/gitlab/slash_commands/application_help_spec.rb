# frozen_string_literal: true

require 'spec_helper'

describe Gitlab::SlashCommands::ApplicationHelp do
  let(:params) { { command: '/gitlab', text: 'help' } }
  let(:project) { build(:project) }

  describe '#execute' do
    subject do
      described_class.new(project, params).execute
    end

    it 'displays the help section' do
      expect(subject[:response_type]).to be(:ephemeral)
      expect(subject[:text]).to include('Available commands')
      expect(subject[:text]).to include('/gitlab [project name or alias] issue show')
    end
  end
end
