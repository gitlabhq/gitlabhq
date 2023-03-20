# frozen_string_literal: true

require 'spec_helper'

RSpec.describe IncidentManagement::PagerDuty::ProcessIncidentWorker, feature_category: :incident_management do
  let_it_be(:project) { create(:project) }
  let_it_be(:incident_management_setting) { create(:project_incident_management_setting, project: project, pagerduty_active: true) }

  describe '#perform' do
    subject(:perform) { described_class.new.perform(project.id, incident_payload) }

    context 'with valid incident payload' do
      let(:incident_payload) do
        {
          'url' => 'https://webdemo.pagerduty.com/incidents/PRORDTY',
          'incident_number' => 33,
          'title' => 'My new incident',
          'status' => 'triggered',
          'created_at' => '2017-09-26T15:14:36Z',
          'urgency' => 'high',
          'incident_key' => nil,
          'assignees' => [{
            'summary' => 'Laura Haley', 'url' => 'https://webdemo.pagerduty.com/users/P553OPV'
          }],
          'impacted_service' => {
            'summary' => 'Production XDB Cluster', 'url' => 'https://webdemo.pagerduty.com/services/PN49J75'
          }
        }
      end

      it 'creates a GitLab issue' do
        expect { perform }.to change { Issue.count }.by(1)
      end
    end

    context 'with invalid incident payload' do
      let(:incident_payload) { {} }

      before do
        allow(Gitlab::AppLogger).to receive(:warn).and_call_original
      end

      it 'does not create a GitLab issue' do
        expect { perform }.not_to change { Issue.count }
      end

      it 'logs a warning' do
        perform

        expect(Gitlab::AppLogger).to have_received(:warn).with(
          message: 'Cannot create issue for PagerDuty incident',
          issue_errors: "Title can't be blank"
        )
      end
    end
  end
end
