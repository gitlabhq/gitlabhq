# frozen_string_literal: true

require 'spec_helper'

RSpec.describe IncidentManagement::TimelineEvents::CreateService, feature_category: :incident_management do
  let_it_be(:user_with_permissions) { create(:user) }
  let_it_be(:user_without_permissions) { create(:user) }
  let_it_be(:project) { create(:project, developers: user_with_permissions, reporters: user_without_permissions) }
  let_it_be_with_refind(:incident) { create(:incident, project: project) }
  let_it_be(:comment) { create(:note, project: project, noteable: incident) }
  let_it_be(:timeline_event_tag) do
    create(:incident_management_timeline_event_tag, name: 'Test tag 1', project: project)
  end

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

      it_behaves_like 'Snowplow event tracking with RedisHLL context' do
        let(:namespace) { project.namespace.reload }
        let(:category) { described_class.to_s }
        let(:user) { current_user }
        let(:action) { 'incident_management_timeline_event_created' }
        let(:label) { 'redis_hll_counters.incident_management.incident_management_total_unique_counts_monthly' }
      end
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

      it_behaves_like 'error response', "Occurred at can't be blank and Timeline text can't be blank"
    end

    context 'with default action' do
      let(:args) { { note: 'note', occurred_at: Time.current, promoted_from_note: comment } }

      it_behaves_like 'success response'

      it 'matches the default action', :aggregate_failures do
        result = execute.payload[:timeline_event]

        expect(result.action).to eq(IncidentManagement::TimelineEvents::DEFAULT_ACTION)
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

    context 'with non_default action' do
      it_behaves_like 'success response'

      it 'matches the action from arguments', :aggregate_failures do
        result = execute.payload[:timeline_event]

        expect(result.action).to eq(args[:action])
      end
    end

    context 'when timeline event tag names are passed' do
      let(:args) do
        {
          note: 'note',
          occurred_at: Time.current,
          action: 'new comment',
          promoted_from_note: comment,
          timeline_event_tag_names: ['Test tag 1']
        }
      end

      it_behaves_like 'success response'

      it 'matches the tag name' do
        result = execute.payload[:timeline_event]
        expect(result.timeline_event_tags.first).to eq(timeline_event_tag)
      end

      context 'when predefined tags are passed' do
        let(:args) do
          {
            note: 'note',
            occurred_at: Time.current,
            action: 'new comment',
            promoted_from_note: comment,
            timeline_event_tag_names: ['start time', 'end time', 'Impact mitigated']
          }
        end

        it_behaves_like 'success response'

        it 'matches the two tags on the event and creates on project' do
          result = execute.payload[:timeline_event]

          expect(result.timeline_event_tags.count).to eq(3)
          expect(result.timeline_event_tags.by_names(['Start time', 'End time', 'Impact mitigated']).pluck_names)
            .to match_array(['Start time', 'End time', 'Impact mitigated'])
          expect(project.incident_management_timeline_event_tags.pluck_names)
            .to include('Start time', 'End time', 'Impact mitigated')
        end
      end

      context 'when invalid tag names are passed' do
        let(:args) do
          {
            note: 'note',
            occurred_at: Time.current,
            action: 'new comment',
            promoted_from_note: comment,
            timeline_event_tag_names: ['some other time']
          }
        end

        it_behaves_like 'error response', "Following tags don't exist: [\"some other time\"]"

        it 'does not create timeline event' do
          expect { execute }.not_to change(IncidentManagement::TimelineEvent, :count)
        end
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

    context 'when note is more than 280 characters long' do
      let(:args) do
        {
          note: 'a' * 281,
          occurred_at: Time.current,
          action: 'new comment',
          promoted_from_note: comment,
          auto_created: auto_created
        }
      end

      let(:auto_created) { false }

      context 'when was not promoted from note' do
        let(:comment) { nil }

        context 'when auto_created is true' do
          let(:auto_created) { true }

          it_behaves_like 'success response'
        end

        context 'when auto_created is false' do
          it_behaves_like 'error response', 'Timeline text is too long (maximum is 280 characters)'
        end
      end

      context 'when promoted from note' do
        it_behaves_like 'success response'
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

      it_behaves_like 'Snowplow event tracking with RedisHLL context' do
        let(:namespace) { project.namespace.reload }
        let(:category) { described_class.to_s }
        let(:user) { current_user }
        let(:action) { 'incident_management_timeline_event_created' }
        let(:label) { 'redis_hll_counters.incident_management.incident_management_total_unique_counts_monthly' }
      end

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

    describe '.change_severity' do
      subject(:execute) { described_class.change_severity(incident, current_user) }

      let_it_be(:severity) { create(:issuable_severity, severity: :critical, issue: incident) }

      let(:expected_note) { "@#{current_user.username} changed the incident severity to **Critical - S1**" }
      let(:expected_action) { 'severity' }

      it_behaves_like 'successfully created timeline event'
    end

    describe '.change_labels' do
      subject(:execute) do
        described_class.change_labels(incident, current_user, added_labels: added, removed_labels: removed)
      end

      let_it_be(:labels) { create_list(:label, 4, project: project) }

      let(:expected_action) { 'label' }

      context 'when there are neither added nor removed labels' do
        let(:added) { [] }
        let(:removed) { [] }

        it 'responds with error', :aggregate_failures do
          expect(execute).to be_error
          expect(execute.message).to eq(_('There are no changed labels'))
        end

        it 'does not create timeline event' do
          expect { execute }.not_to change { incident.incident_management_timeline_events.count }
        end
      end

      context 'when there are only added labels' do
        let(:added) { [labels[0], labels[1]] }
        let(:removed) { [] }

        let(:expected_note) { "@#{current_user.username} added #{added.map(&:to_reference).join(' ')} labels" }

        it_behaves_like 'successfully created timeline event'
      end

      context 'when there are only removed labels' do
        let(:added) { [] }
        let(:removed) { [labels[2], labels[3]] }

        let(:expected_note) { "@#{current_user.username} removed #{removed.map(&:to_reference).join(' ')} labels" }

        it_behaves_like 'successfully created timeline event'
      end

      context 'when there are both added and removed labels' do
        let(:added) { [labels[0], labels[1]] }
        let(:removed) { [labels[2], labels[3]] }

        let(:expected_note) do
          added_note = "added #{added.map(&:to_reference).join(' ')} labels"
          removed_note = "removed #{removed.map(&:to_reference).join(' ')} labels"

          "@#{current_user.username} #{added_note} and #{removed_note}"
        end

        it_behaves_like 'successfully created timeline event'
      end

      context 'when there is a single added and single removed labels' do
        let(:added) { [labels[0]] }
        let(:removed) { [labels[3]] }

        let(:expected_note) do
          added_note = "added #{added.first.to_reference} label"
          removed_note = "removed #{removed.first.to_reference} label"

          "@#{current_user.username} #{added_note} and #{removed_note}"
        end

        it_behaves_like 'successfully created timeline event'
      end

      context 'when feature flag is disabled' do
        let(:added) { [labels[0], labels[1]] }
        let(:removed) { [labels[2], labels[3]] }

        before do
          stub_feature_flags(incident_timeline_events_from_labels: false)
        end

        it 'does not create timeline event' do
          expect { execute }.not_to change { incident.incident_management_timeline_events.count }
        end
      end
    end
  end
end
