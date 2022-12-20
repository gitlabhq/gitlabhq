# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'PagerDuty webhook', feature_category: :incident_management do
  let_it_be(:project) { create(:project) }

  describe 'POST /incidents/pagerduty' do
    let(:payload) { Gitlab::Json.parse(fixture_file('pager_duty/webhook_incident_trigger.json')) }
    let(:webhook_processor_class) { ::IncidentManagement::PagerDuty::ProcessWebhookService }
    let(:webhook_processor) { instance_double(webhook_processor_class) }

    def make_request
      headers = { 'Content-Type' => 'application/json' }
      post project_incidents_integrations_pagerduty_url(project, token: 'VALID-TOKEN'), params: payload.to_json, headers: headers
    end

    before do
      allow(webhook_processor_class).to receive(:new).and_return(webhook_processor)
      allow(webhook_processor).to receive(:execute).and_return(ServiceResponse.success(http_status: :accepted))
    end

    it 'calls PagerDuty webhook processor with correct parameters' do
      make_request

      expect(webhook_processor_class).to have_received(:new).with(project, payload)
      expect(webhook_processor).to have_received(:execute).with('VALID-TOKEN')
    end

    it 'responds with 202 Accepted' do
      make_request

      expect(response).to have_gitlab_http_status(:accepted)
    end
  end
end
