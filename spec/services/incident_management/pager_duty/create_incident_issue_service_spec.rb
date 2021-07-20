# frozen_string_literal: true

require 'spec_helper'

RSpec.describe IncidentManagement::PagerDuty::CreateIncidentIssueService do
  let_it_be(:project, reload: true) { create(:project) }
  let_it_be(:user) { User.alert_bot }

  let(:webhook_payload) { Gitlab::Json.parse(fixture_file('pager_duty/webhook_incident_trigger.json')) }
  let(:parsed_payload) { ::PagerDuty::WebhookPayloadParser.call(webhook_payload) }
  let(:incident_payload) { parsed_payload.first['incident'] }

  subject(:execute) { described_class.new(project, incident_payload).execute }

  describe '#execute' do
    context 'when PagerDuty webhook setting is active' do
      let_it_be(:incident_management_setting) { create(:project_incident_management_setting, project: project, pagerduty_active: true) }

      context 'when issue can be created' do
        it 'creates a new issue' do
          expect { execute }.to change(Issue, :count).by(1)
        end

        it 'responds with success' do
          response = execute

          expect(response).to be_success
          expect(response.payload[:issue]).to be_kind_of(Issue)
        end

        it 'the issue author is Alert bot' do
          expect(execute.payload[:issue].author).to eq(User.alert_bot)
        end

        it 'issue has a correct title' do
          expect(execute.payload[:issue].title).to eq(incident_payload['title'])
        end

        it 'issue has a correct description' do
          markdown_line_break = '  '

          expect(execute.payload[:issue].description).to eq(
            <<~MARKDOWN.chomp
              **Incident:** [My new incident](https://webdemo.pagerduty.com/incidents/PRORDTY)#{markdown_line_break}
              **Incident number:** 33#{markdown_line_break}
              **Urgency:** high#{markdown_line_break}
              **Status:** triggered#{markdown_line_break}
              **Incident key:** #{markdown_line_break}
              **Created at:** 26 September 2017, 3:14PM (UTC)#{markdown_line_break}
              **Assignees:** [Laura Haley](https://webdemo.pagerduty.com/users/P553OPV)#{markdown_line_break}
              **Impacted services:** [Production XDB Cluster](https://webdemo.pagerduty.com/services/PN49J75)
            MARKDOWN
          )
        end
      end

      context 'when the payload does not contain a title' do
        let(:incident_payload) { {} }

        it 'does not create a GitLab issue' do
          expect { execute }.not_to change(Issue, :count)
        end

        it 'responds with error' do
          expect(execute).to be_error
          expect(execute.message).to eq("Title can't be blank")
        end
      end
    end

    context 'when PagerDuty webhook setting is not active' do
      let_it_be(:incident_management_setting) { create(:project_incident_management_setting, project: project, pagerduty_active: false) }

      it 'does not create a GitLab issue' do
        expect { execute }.not_to change(Issue, :count)
      end

      it 'responds with forbidden' do
        expect(execute).to be_error
        expect(execute.http_status).to eq(:forbidden)
      end
    end
  end
end
