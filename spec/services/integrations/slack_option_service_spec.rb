# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Integrations::SlackOptionService, feature_category: :integrations do
  describe '#execute' do
    subject(:execute) { described_class.new(params).execute }

    let_it_be(:slack_installation) { create(:slack_integration) }
    let_it_be(:user) { create(:user) }

    let_it_be(:chat_name) do
      create(:chat_name,
        user: user,
        team_id: slack_installation.team_id,
        chat_id: slack_installation.user_id
      )
    end

    let(:params) do
      {
        action_id: action_id,
        view: {
          id: 'VHDFR54DSA'
        },
        value: 'Search value',
        team: {
          id: slack_installation.team_id
        },
        user: {
          id: slack_installation.user_id
        }
      }
    end

    context 'when action_id is assignee' do
      let(:action_id) { 'assignee' }

      it 'executes the user search handler' do
        user_search_handler = described_class::OPTIONS['assignee']

        expect_next_instance_of(user_search_handler, chat_name, 'Search value', 'VHDFR54DSA') do |service|
          expect(service).to receive(:execute).and_return(ServiceResponse.success)
        end

        execute
      end
    end

    context 'when action_id is labels' do
      let(:action_id) { 'labels' }

      it 'executes the label search handler' do
        label_search_handler = described_class::OPTIONS['labels']

        expect_next_instance_of(label_search_handler, chat_name, 'Search value', 'VHDFR54DSA') do |service|
          expect(service).to receive(:execute).and_return(ServiceResponse.success)
        end

        execute
      end
    end

    context 'when action_id is unknown' do
      let(:action_id) { 'foo' }

      it 'raises an error and does not execute a service class' do
        described_class::OPTIONS.each_value do |service_class|
          expect(service_class).not_to receive(:new)
        end

        expect { execute }.to raise_error(described_class::UnknownOptionError)
      end
    end
  end
end
