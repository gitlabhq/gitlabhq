# frozen_string_literal: true

require 'spec_helper'

RSpec.describe IncidentManagement::TimelineEvents::CreateService do
  let_it_be(:user_with_permissions) { create(:user) }
  let_it_be(:user_without_permissions) { create(:user) }
  let_it_be(:project) { create(:project) }
  let_it_be_with_refind(:incident) { create(:incident, project: project) }
  let_it_be(:comment) { create(:note, project: project, noteable: incident) }

  let(:args) do
    {
      note: 'note',
      occurred_at: Time.current,
      action: 'new comment',
      promoted_from_note: comment
    }
  end

  let(:editable) { false }
  let(:current_user) { user_with_permissions }
  let(:service) { described_class.new(incident, current_user, args) }

  before_all do
    project.add_developer(user_with_permissions)
    project.add_reporter(user_without_permissions)
  end

  describe '#execute' do
    shared_examples 'error response' do |message|
      it 'has an informative message' do
        expect(execute).to be_error
        expect(execute.message).to eq(message)
      end

      it_behaves_like 'does not track incident management event', :incident_management_timeline_event_created
    end

    shared_examples 'success response' do
      it 'has timeline event', :aggregate_failures do
        expect(execute).to be_success

        result = execute.payload[:timeline_event]
        expect(result).to be_a(::IncidentManagement::TimelineEvent)
        expect(result.author).to eq(current_user)
        expect(result.incident).to eq(incident)
        expect(result.project).to eq(project)
        expect(result.note).to eq(args[:note])
        expect(result.promoted_from_note).to eq(comment)
        expect(result.editable).to eq(editable)
      end

      it_behaves_like 'an incident management tracked event', :incident_management_timeline_event_created
    end

    subject(:execute) { service.execute }

    context 'when current user is blank' do
      let(:current_user) { nil }

      it_behaves_like 'error response', 'You have insufficient permissions to manage timeline events for this incident'
    end

    context 'when user does not have permissions to create timeline events' do
      let(:current_user) { user_without_permissions }

      it_behaves_like 'error response', 'You have insufficient permissions to manage timeline events for this incident'
    end

    context 'when error occurs during creation' do
      let(:args) { {} }

      it_behaves_like 'error response', "Occurred at can't be blank, Note can't be blank, and Note html can't be blank"
    end

    context 'with default action' do
      let(:args) { { note: 'note', occurred_at: Time.current, promoted_from_note: comment } }

      it_behaves_like 'success response'

      it 'matches the default action', :aggregate_failures do
        result = execute.payload[:timeline_event]

        expect(result.action).to eq(IncidentManagement::TimelineEvents::DEFAULT_ACTION)
      end
    end

    context 'with non_default action' do
      it_behaves_like 'success response'

      it 'matches the action from arguments', :aggregate_failures do
        result = execute.payload[:timeline_event]

        expect(result.action).to eq(args[:action])
      end
    end

    context 'with editable param' do
      let(:args) do
        {
          note: 'note',
          occurred_at: Time.current,
          action: 'new comment',
          promoted_from_note: comment,
          editable: editable
        }
      end

      context 'when editable is true' do
        let(:editable) { true }

        it_behaves_like 'success response'
      end

      context 'when editable is false' do
        let(:editable) { false }

        it_behaves_like 'success response'
      end
    end

    it 'successfully creates a database record', :aggregate_failures do
      expect { execute }.to change { ::IncidentManagement::TimelineEvent.count }.by(1)
    end

    context 'when incident_timeline feature flag is enabled' do
      before do
        stub_feature_flags(incident_timeline: project)
      end

      it 'creates a system note' do
        expect { execute }.to change { incident.notes.reload.count }.by(1)
      end

      context 'with auto_created param' do
        let(:args) do
          {
            note: 'note',
            occurred_at: Time.current,
            action: 'new comment',
            promoted_from_note: comment,
            auto_created: auto_created
          }
        end

        context 'when auto_created is true' do
          let(:auto_created) { true }

          it 'does not create a system note' do
            expect { execute }.not_to change { incident.notes.reload.count }
          end

          context 'when user does not have permissions' do
            let(:current_user) { user_without_permissions }

            it_behaves_like 'success response'
          end
        end

        context 'when auto_created is false' do
          let(:auto_created) { false }

          it 'creates a system note' do
            expect { execute }.to change { incident.notes.reload.count }.by(1)
          end
        end
      end
    end

    context 'when incident_timeline feature flag is disabled' do
      before do
        stub_feature_flags(incident_timeline: false)
      end

      it 'does not create a system note' do
        expect { execute }.not_to change { incident.notes.reload.count }
      end
    end
  end

  describe 'automatically created timeline events' do
    shared_examples 'successfully created timeline event' do
      it 'creates a timeline event', :aggregate_failures do
        expect(execute).to be_success

        result = execute.payload[:timeline_event]
        expect(result).to be_a(::IncidentManagement::TimelineEvent)
        expect(result.author).to eq(current_user)
        expect(result.incident).to eq(incident)
        expect(result.project).to eq(project)
        expect(result.note).to eq(expected_note)
        expect(result.editable).to eq(false)
        expect(result.action).to eq(expected_action)
      end

      it_behaves_like 'an incident management tracked event', :incident_management_timeline_event_created

      it 'successfully creates a database record', :aggregate_failures do
        expect { execute }.to change { ::IncidentManagement::TimelineEvent.count }.by(1)
      end

      it 'does not create a system note' do
        expect { execute }.not_to change { incident.notes.reload.count }
      end
    end

    describe '.create_incident' do
      subject(:execute) { described_class.create_incident(incident, current_user) }

      let(:expected_note) { "@#{current_user.username} created the incident" }
      let(:expected_action) { 'issues' }

      it_behaves_like 'successfully created timeline event'
    end

    describe '.reopen_incident' do
      subject(:execute) { described_class.reopen_incident(incident, current_user) }

      let(:expected_note) { "@#{current_user.username} reopened the incident" }
      let(:expected_action) { 'issues' }

      it_behaves_like 'successfully created timeline event'
    end

    describe '.resolve_incident' do
      subject(:execute) { described_class.resolve_incident(incident, current_user) }

      let(:expected_note) { "@#{current_user.username} resolved the incident" }
      let(:expected_action) { 'status' }

      it_behaves_like 'successfully created timeline event'
    end

    describe '.change_incident_status' do
      subject(:execute) { described_class.change_incident_status(incident, current_user, escalation_status) }

      let(:escalation_status) do
        instance_double('IncidentManagement::IssuableEscalationStatus', status_name: 'acknowledged')
      end

      let(:expected_note) { "@#{current_user.username} changed the incident status to **Acknowledged**" }
      let(:expected_action) { 'status' }

      it_behaves_like 'successfully created timeline event'
    end
  end
end
