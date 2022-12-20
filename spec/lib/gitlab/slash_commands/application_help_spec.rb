# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::SlashCommands::ApplicationHelp do
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

    context 'with incident declare command' do
      context 'when feature flag is enabled' do
        it 'displays the declare command' do
          expect(subject[:text]).to include('/gitlab incident declare')
        end
      end

      context 'when feature flag is disabled' do
        before do
          stub_feature_flags(incident_declare_slash_command: false)
        end

        it 'does not displays the declare command' do
          expect(subject[:text]).not_to include('/gitlab incident declare')
        end
      end
    end
  end
end
