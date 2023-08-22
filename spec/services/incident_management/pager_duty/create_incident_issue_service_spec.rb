# frozen_string_literal: true

require 'spec_helper'

RSpec.describe IncidentManagement::PagerDuty::CreateIncidentIssueService, feature_category: :incident_management do
  let_it_be(:project, reload: true) { create(:project) }
  let_it_be(:user) { Users::Internal.alert_bot }

  let(:webhook_payload) { Gitlab::Json.parse(fixture_file('pager_duty/webhook_incident_trigger.json')) }
  let(:parsed_payload) { ::PagerDuty::WebhookPayloadParser.call(webhook_payload) }
  let(:incident_payload) { parsed_payload['incident'] }

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
          expect(execute.payload[:issue].author).to eq(Users::Internal.alert_bot)
        end

        it 'issue has a correct title' do
          expect(execute.payload[:issue].title).to eq(incident_payload['title'])
        end

        it 'issue has a correct description' do
          markdown_line_break = '  '

          expect(execute.payload[:issue].description).to eq(
            <<~MARKDOWN.chomp
              **Incident:** [[FILTERED]](https://gitlab-1.pagerduty.com/incidents/Q1XZUF87W1HB5A)#{markdown_line_break}
              **Incident number:** 2#{markdown_line_break}
              **Urgency:** high#{markdown_line_break}
              **Status:** triggered#{markdown_line_break}
              **Incident key:** [FILTERED]#{markdown_line_break}
              **Created at:** 30 November 2022, 8:46AM (UTC)#{markdown_line_break}
              **Assignees:** [Rajendra Kadam](https://gitlab-1.pagerduty.com/users/PIN0B5C)#{markdown_line_break}
              **Impacted service:** [Test service](https://gitlab-1.pagerduty.com/services/PK6IKMT)
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
          expect(execute.errors).to contain_exactly("Title can't be blank")
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
