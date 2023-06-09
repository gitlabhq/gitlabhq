# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::SlashCommands::IncidentManagement::IncidentNew, feature_category: :incident_management do
  let_it_be(:project) { create(:project) }
  let_it_be(:user) { create(:user) }
  let_it_be(:chat_name) { create(:chat_name, user: user) }
  let_it_be(:regex_match) { described_class.match('incident declare') }

  subject do
    described_class.new(project, chat_name)
  end

  describe '#execute' do
    before do
      allow_next_instance_of(
        Integrations::SlackInteractions::IncidentManagement::IncidentModalOpenedService
      ) do |modal_service|
        allow(modal_service).to receive(:execute).and_return(
          ServiceResponse.success(message: 'Please fill the incident creation form.')
        )
      end
    end

    context 'when invoked' do
      it 'sends ephemeral response' do
        response = subject.execute(regex_match)

        expect(response[:response_type]).to be(:ephemeral)
        expect(response[:text]).to eq('Please fill the incident creation form.')
      end
    end
  end

  describe '#allowed?' do
    it 'returns true' do
      expect(described_class).to be_allowed(project, user)
    end

    context 'when feature flag is disabled' do
      before do
        stub_feature_flags(incident_declare_slash_command: false)
      end

      it 'returns false in allowed?' do
        expect(described_class).not_to be_allowed(project, user)
      end
    end
  end

  describe '#collection' do
    context 'when collection method id called' do
      it 'calls IssuesFinder' do
        expect_next_instance_of(IssuesFinder) do |finder|
          expect(finder).to receive(:execute)
        end

        subject.collection
      end
    end
  end
end
