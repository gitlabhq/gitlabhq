# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Integrations::SlackInteractionService, feature_category: :integrations do
  describe '#execute' do
    subject(:execute) { described_class.new(params).execute }

    let(:params) do
      {
        type: slack_interaction,
        foo: 'bar'
      }
    end

    context 'when view is closed' do
      let(:slack_interaction) { 'view_closed' }

      it 'executes the correct service' do
        view_closed_service = described_class::INTERACTIONS['view_closed']

        expect_next_instance_of(view_closed_service, { foo: 'bar' }) do |service|
          expect(service).to receive(:execute).and_return(ServiceResponse.success)
        end

        execute
      end
    end

    context 'when view is submitted' do
      let(:slack_interaction) { 'view_submission' }

      it 'executes the submission service' do
        view_submission_service = described_class::INTERACTIONS['view_submission']

        expect_next_instance_of(view_submission_service, { foo: 'bar' }) do |service|
          expect(service).to receive(:execute).and_return(ServiceResponse.success)
        end

        execute
      end
    end

    context 'when block action service is submitted' do
      let(:slack_interaction) { 'block_actions' }

      it 'executes the block actions service' do
        block_action_service = described_class::INTERACTIONS['block_actions']

        expect_next_instance_of(block_action_service, { foo: 'bar' }) do |service|
          expect(service).to receive(:execute).and_return(ServiceResponse.success)
        end

        execute
      end
    end

    context 'when slack_interaction is not known' do
      let(:slack_interaction) { 'foo' }

      it 'raises an error and does not execute a service class' do
        described_class::INTERACTIONS.each_value do |service_class|
          expect(service_class).not_to receive(:new)
        end

        expect { execute }.to raise_error(described_class::UnknownInteractionError)
      end
    end
  end
end
