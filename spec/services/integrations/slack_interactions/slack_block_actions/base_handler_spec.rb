# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Integrations::SlackInteractions::SlackBlockActions::BaseHandler,
  feature_category: :integrations do
  let_it_be(:slack_installation) { create(:slack_integration) }

  let(:team_id) { slack_installation.team_id }
  let(:action) { { action_id: 'some_action', value: 'up:1' } }
  let(:params) { { team: { id: team_id }, user: { id: 'U123' } } }

  let(:handler) { described_class.new(params, action) }

  describe '#execute' do
    it 'raises NotImplementedError' do
      expect { handler.execute }.to raise_error(NotImplementedError)
    end
  end

  describe '#slack_installation' do
    subject { handler.send(:slack_installation) }

    it { is_expected.to eq(slack_installation) }

    context 'when no installation exists for the team' do
      let(:team_id) { 'T_UNKNOWN' }

      it { is_expected.to be_nil }
    end
  end
end
