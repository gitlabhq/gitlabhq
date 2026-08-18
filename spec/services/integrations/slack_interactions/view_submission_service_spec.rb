# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Integrations::SlackInteractions::ViewSubmissionService, feature_category: :integrations do
  describe '#execute' do
    subject(:execute) { described_class.new(params).execute }

    let(:params) do
      {
        view: { callback_id: callback_id },
        foo: 'bar'
      }
    end

    context 'when the callback_id is the incident modal' do
      let(:callback_id) { 'incident_modal' }

      it 'delegates to the incident modal submit service' do
        expect_next_instance_of(
          Integrations::SlackInteractions::IncidentManagement::IncidentModalSubmitService, params
        ) do |service|
          expect(service).to receive(:execute).and_return(ServiceResponse.success)
        end

        execute
      end
    end

    context 'when the callback_id is unknown' do
      let(:callback_id) { 'unknown_modal' }

      it 'returns success without delegating' do
        expect(Integrations::SlackInteractions::IncidentManagement::IncidentModalSubmitService)
          .not_to receive(:new)

        expect(execute).to be_success
      end

      it 'logs a warning' do
        expect(Gitlab::IntegrationsLogger).to receive(:warn).with(
          message: 'Ignoring Slack view_submission with unknown callback_id',
          callback_id: 'unknown_modal'
        )

        execute
      end
    end

    context 'when the callback_id is missing' do
      let(:params) { { foo: 'bar' } }

      it 'returns success without delegating' do
        expect(execute).to be_success
      end
    end
  end
end
