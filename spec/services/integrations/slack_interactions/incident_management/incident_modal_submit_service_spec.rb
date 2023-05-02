# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Integrations::SlackInteractions::IncidentManagement::IncidentModalSubmitService,
  feature_category: :incident_management do
  include Gitlab::Routing

  describe '#execute' do
    let_it_be(:slack_installation) { create(:slack_integration) }
    let_it_be(:project) { create(:project) }
    let_it_be(:user) { create(:user) }
    let_it_be(:api_url) { 'https://api.slack.com/id/1234' }

    let_it_be(:chat_name) do
      create(:chat_name,
        user: user,
        team_id: slack_installation.team_id,
        chat_id: slack_installation.user_id
      )
    end

    # Setting below params as they are optional, have added values wherever required in specs
    let(:zoom_link) { '' }
    let(:severity) { {} }
    let(:status) { '' }
    let(:assignee_id) { nil }
    let(:selected_label_ids) { [] }
    let(:label_ids) { { selected_options: selected_label_ids } }
    let(:confidential_selected_options) { [] }
    let(:confidential) { { selected_options: confidential_selected_options } }
    let(:title) { 'Incident title' }

    let(:zoom) do
      {
        link: {
          value: zoom_link
        }
      }
    end

    let(:params) do
      {
        team: {
          id: slack_installation.team_id
        },
        user: {
          id: slack_installation.user_id
        },
        view: {
          private_metadata: api_url,
          state: {
            values: {
              title_input: {
                title: {
                  value: title
                }
              },
              incident_description: {
                description: {
                  value: 'Incident description'
                }
              },
              project_and_severity_selector: {
                incident_management_project: {
                  selected_option: {
                    value: project.id.to_s
                  }
                },
                severity: severity
              },
              confidentiality: {
                confidential: confidential
              },
              zoom: zoom,
              status_and_assignee_selector: {
                status: {
                  selected_option: {
                    value: status
                  }
                },
                assignee: {
                  selected_option: {
                    value: assignee_id
                  }
                }
              },
              label_selector: {
                labels: label_ids
              }
            }
          }
        }
      }
    end

    subject(:execute_service) { described_class.new(params).execute }

    shared_examples 'error in creation' do |error_message|
      it 'returns error and raises exception' do
        expect(::Gitlab::ErrorTracking).to receive(:track_exception)
          .with(
            described_class::IssueCreateError.new(error_message),
            {
              slack_workspace_id: slack_installation.team_id,
              slack_user_id: slack_installation.user_id
            }
          )

        expect(Gitlab::HTTP).to receive(:post)
          .with(
            api_url,
            body: Gitlab::Json.dump(
              {
                replace_original: 'true',
                text: 'There was a problem creating the incident. Please try again.'
              }
            ),
            headers: { 'Content-Type' => 'application/json' }
          )

        response = execute_service

        expect(response).to be_error
        expect(response.message).to eq(error_message)
      end
    end

    context 'when user has permissions to create incidents' do
      let(:api_response) { '{"ok":true}' }

      before do
        project.add_developer(user)
        stub_request(:post, api_url)
          .to_return(body: api_response, headers: { 'Content-Type' => 'application/json' })
      end

      context 'with markup string in title' do
        let(:title) { '<a href="url">incident title</a>' }
        let(:incident) { create(:incident, title: title, project: project) }

        before do
          allow_next_instance_of(Issues::CreateService) do |service|
            allow(service).to receive(:execute).and_return(
              ServiceResponse.success(payload: { issue: incident, error: [] })
            )
          end
        end

        it 'strips the markup and saves sends the title' do
          expect(Gitlab::HTTP).to receive(:post)
            .with(
              api_url,
              body: Gitlab::Json.dump(
                {
                  replace_original: 'true',
                  text: "New incident has been created: " \
                        "<#{issue_url(incident)}|#{incident.to_reference} - a href=\"url\"incident title/a>. "
                }
              ),
              headers: { 'Content-Type' => 'application/json' }
            ).and_return(api_response)

          execute_service
        end
      end

      context 'with non-optional params' do
        it 'creates incident' do
          response = execute_service
          incident = response[:incident]

          expect(response).to be_success
          expect(incident).not_to be_nil
          expect(incident.description).to eq('Incident description')
          expect(incident.author).to eq(user)
          expect(incident.severity).to eq('unknown')
          expect(incident.confidential).to be_falsey
          expect(incident.escalation_status).to be_triggered
        end

        it 'sends incident link to slack' do
          execute_service

          expect(WebMock).to have_requested(:post, api_url)
        end
      end

      context 'with zoom_link' do
        let(:zoom_link) { 'https://gitlab.zoom.us/j/1234' }

        it 'sets zoom link as quick action' do
          incident = execute_service[:incident]
          zoom_meeting = ZoomMeeting.find_by_issue_id(incident.id)

          expect(incident.description).to eq("Incident description")
          expect(zoom_meeting.url).to eq(zoom_link)
        end
      end

      context 'with confidential and severity' do
        let(:confidential_selected_options) { ['confidential'] }
        let(:severity) do
          {
            selected_option: {
              value: 'high'
            }
          }
        end

        it 'sets confidential and severity' do
          incident = execute_service[:incident]

          expect(incident.confidential).to be_truthy
          expect(incident.severity).to eq('high')
        end
      end

      context 'with incident status' do
        let(:status) { 'resolved' }

        it 'sets the incident status' do
          incident = execute_service[:incident]

          expect(incident.escalation_status).to be_resolved
        end
      end

      context 'with assignee id' do
        let(:assignee_id) { user.id.to_s }

        it 'assigns the incident to user' do
          incident = execute_service[:incident]

          expect(incident.assignees).to contain_exactly(user)
        end

        context 'when user is not a member of the project' do
          let(:assignee_id) { create(:user).id.to_s }

          it 'does not assign the user' do
            incident = execute_service[:incident]

            expect(incident.assignees).to be_empty
          end
        end
      end

      context 'with label ids' do
        let_it_be(:project_label1) { create(:label, project: project, title: 'Label 1') }
        let_it_be(:project_label2) { create(:label, project: project, title: 'Label 2') }

        let(:selected_label_ids) do
          [
            { value: project_label1.id.to_s },
            { value: project_label2.id.to_s }
          ]
        end

        it 'assigns the label to the incident' do
          incident = execute_service[:incident]

          expect(incident.labels).to contain_exactly(project_label1, project_label2)
        end
      end

      context 'when response is not ok' do
        let(:api_response) { '{"ok":false}' }

        it 'returns error response and tracks the exception' do
          expect(::Gitlab::ErrorTracking).to receive(:track_exception)
            .with(
              StandardError.new('Something went wrong when sending the incident link to Slack.'),
              {
                response: { 'ok' => false },
                slack_workspace_id: slack_installation.team_id,
                slack_user_id: slack_installation.user_id
              }
            )

          execute_service
        end
      end

      context 'when incident creation fails' do
        let(:title) { '' }

        it_behaves_like 'error in creation', "Title can't be blank"
      end
    end

    context 'when user does not have permission to create incidents' do
      it_behaves_like 'error in creation', 'Operation not allowed'
    end
  end
end
