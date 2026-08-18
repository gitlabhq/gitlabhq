# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Integrations::SlackInteractions::SlackBlockActions::BaseHandler,
  feature_category: :integrations do
  let_it_be(:slack_installation) { create(:slack_integration) }

  let(:team_id) { slack_installation.team_id }
  let(:response_url) { 'https://hooks.slack.com/actions/T123/456/xyz' }
  let(:action) { { action_id: 'some_action', value: Gitlab::Json.dump(channel: 'C123', ts: '123.456') } }

  let(:params) do
    {
      team: { id: team_id },
      user: { id: 'U123' },
      response_url: response_url
    }
  end

  let(:handler) { described_class.new(params, action) }

  describe '#execute' do
    it 'raises NotImplementedError' do
      expect { handler.execute }.to raise_error(NotImplementedError)
    end
  end

  describe '#button_value' do
    subject(:button_value) { handler.send(:button_value) }

    it 'parses the JSON button value with indifferent access' do
      expect(button_value[:channel]).to eq('C123')
      expect(button_value['ts']).to eq('123.456')
    end

    context 'when the value is not valid JSON' do
      let(:action) { { action_id: 'some_action', value: 'not json{' } }

      it { is_expected.to eq({}) }
    end

    context 'when the value is valid JSON but not a hash' do
      let(:action) { { action_id: 'some_action', value: '[1, 2]' } }

      it { is_expected.to eq({}) }
    end

    context 'when the value is missing' do
      let(:action) { { action_id: 'some_action' } }

      it { is_expected.to eq({}) }
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

  describe '#replace_original_message' do
    subject(:replace_original_message) { handler.send(:replace_original_message, 'Updated text') }

    before do
      stub_request(:post, response_url).to_return(status: 200, body: 'ok')
    end

    it 'posts the replacement text to the response_url' do
      replace_original_message

      expect(WebMock).to have_requested(:post, response_url).with(
        body: hash_including('replace_original' => true, 'text' => 'Updated text')
      )
    end

    context 'when the response_url is missing' do
      let(:params) { { team: { id: team_id }, user: { id: 'U123' } } }

      it 'does not make a request' do
        replace_original_message

        expect(WebMock).not_to have_requested(:post, response_url)
      end
    end

    context 'when the request raises an HTTP error' do
      before do
        stub_request(:post, response_url).to_raise(Errno::ECONNREFUSED.new('error'))
      end

      it 'tracks the exception without raising' do
        expect(Gitlab::ErrorTracking).to receive(:track_exception)
          .with(an_instance_of(Errno::ECONNREFUSED), slack_workspace_id: team_id)

        expect { replace_original_message }.not_to raise_error
      end
    end
  end
end
