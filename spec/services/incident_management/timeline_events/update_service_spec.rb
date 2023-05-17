# frozen_string_literal: true

require 'spec_helper'

RSpec.describe IncidentManagement::TimelineEvents::UpdateService, feature_category: :incident_management do
  let_it_be(:user) { create(:user) }
  let_it_be(:project) { create(:project) }
  let_it_be(:incident) { create(:incident, project: project) }
  let_it_be(:tag1) { create(:incident_management_timeline_event_tag, project: project, name: 'Tag 1') }
  let_it_be(:tag2) { create(:incident_management_timeline_event_tag, project: project, name: 'Tag 2') }
  let_it_be(:tag3) { create(:incident_management_timeline_event_tag, project: project, name: 'Tag 3') }

  let!(:tag_link1) do
    create(:incident_management_timeline_event_tag_link,
      timeline_event: timeline_event,
      timeline_event_tag: tag3
    )
  end

  let!(:timeline_event) { create(:incident_management_timeline_event, project: project, incident: incident) }
  let(:occurred_at) { 1.minute.ago }
  let(:params) { { note: 'Updated note', occurred_at: occurred_at } }
  let(:current_user) { user }

  describe '#execute' do
    shared_examples 'successful tag response' do
      it_behaves_like 'successful response'

      it 'adds the new tag' do
        expect { execute }.to change { timeline_event.timeline_event_tags.count }.by(1)
      end

      it 'adds the new tag link' do
        expect { execute }.to change { IncidentManagement::TimelineEventTagLink.count }.by(1)
      end

      it 'returns the new tag in response' do
        timeline_event = execute.payload[:timeline_event]

        expect(timeline_event.timeline_event_tags.pluck_names).to contain_exactly(tag1.name, tag3.name)
      end
    end

    shared_examples 'successful response' do
      it 'responds with success', :aggregate_failures do
        expect(execute).to be_success
        expect(execute.payload).to eq(timeline_event: timeline_event.reload)
      end

      it_behaves_like 'an incident management tracked event', :incident_management_timeline_event_edited

      it_behaves_like 'Snowplow event tracking with RedisHLL context' do
        let(:namespace) { project.namespace.reload }
        let(:category) { described_class.to_s }
        let(:action) { 'incident_management_timeline_event_edited' }
        let(:label) { 'redis_hll_counters.incident_management.incident_management_total_unique_counts_monthly' }
      end
    end

    shared_examples 'error response' do |message|
      it 'has an informative message' do
        expect(execute).to be_error
        expect(execute.message).to eq(message)
      end

      it 'does not update the note' do
        expect { execute }.not_to change { timeline_event.reload.note }
      end

      it_behaves_like 'does not track incident management event', :incident_management_timeline_event_edited
    end

    shared_examples 'passing the correct was_changed value' do |was_changed|
      it 'passes the correct was_changed value into SysteNoteService.edit_timeline_event' do
        expect(SystemNoteService)
          .to receive(:edit_timeline_event)
          .with(timeline_event, user, was_changed: was_changed)
          .and_call_original

        execute
      end
    end

    subject(:execute) { described_class.new(timeline_event, user, params).execute }

    context 'when user has permissions' do
      before do
        project.add_developer(user)
      end

      it_behaves_like 'successful response'

      it 'updates attributes' do
        expect { execute }.to change { timeline_event.note }.to(params[:note])
          .and change { timeline_event.occurred_at }.to(params[:occurred_at])
      end

      it 'creates a system note' do
        expect { execute }.to change { incident.notes.reload.count }.by(1)
      end

      it_behaves_like 'passing the correct was_changed value', :occurred_at_and_note

      context 'when note is nil' do
        let(:params) { { occurred_at: occurred_at, timeline_event_tag_names: [tag3.name, tag2.name] } }

        it_behaves_like 'successful response'
        it_behaves_like 'passing the correct was_changed value', :occurred_at

        it 'does not update the note' do
          expect { execute }.not_to change { timeline_event.reload.note }
        end

        it 'updates occurred_at' do
          expect { execute }.to change { timeline_event.occurred_at }.to(params[:occurred_at])
        end

        it 'updates the tags' do
          expect { execute }.to change { timeline_event.timeline_event_tags.count }.by(1)
        end
      end

      context 'when note is blank' do
        let(:params) { { note: '', occurred_at: occurred_at, timeline_event_tag_names: [tag3.name, tag2.name] } }

        it_behaves_like 'error response', "Timeline text can't be blank"

        it 'does not add the tags as it rollsback the transaction' do
          expect { execute }.not_to change { timeline_event.timeline_event_tags.count }
        end
      end

      context 'when note is more than 280 characters long' do
        let(:params) { { note: 'n' * 281, occurred_at: occurred_at, timeline_event_tag_names: [tag3.name, tag2.name] } }

        it_behaves_like 'error response', 'Timeline text is too long (maximum is 280 characters)'

        it 'does not add the tags as it rollsback the transaction' do
          expect { execute }.not_to change { timeline_event.timeline_event_tags.count }
        end
      end

      context 'when occurred_at is nil' do
        let(:params) { { note: 'Updated note' } }

        it_behaves_like 'successful response'
        it_behaves_like 'passing the correct was_changed value', :note

        it 'updates the note' do
          expect { execute }.to change { timeline_event.note }.to(params[:note])
        end

        it 'does not update occurred_at' do
          expect { execute }.not_to change { timeline_event.reload.occurred_at }
        end
      end

      context 'when occurred_at is blank' do
        let(:params) { { note: 'Updated note', occurred_at: '', timeline_event_tag_names: [tag3.name, tag2.name] } }

        it_behaves_like 'error response', "Occurred at can't be blank"

        it 'does not add the tags as it rollsback the transaction' do
          expect { execute }.not_to change { timeline_event.timeline_event_tags.count }
        end
      end

      context 'when both occurred_at and note is nil' do
        let(:params) { {} }

        it_behaves_like 'successful response'

        it 'does not update the note' do
          expect { execute }.not_to change { timeline_event.note }
        end

        it 'does not update occurred_at' do
          expect { execute }.not_to change { timeline_event.reload.occurred_at }
        end

        it 'does not call SysteNoteService.edit_timeline_event' do
          expect(SystemNoteService).not_to receive(:edit_timeline_event)

          execute
        end
      end

      context 'when timeline event is non-editable' do
        let!(:timeline_event) do
          create(:incident_management_timeline_event, :non_editable, project: project, incident: incident)
        end

        it_behaves_like 'error response',
          'You have insufficient permissions to manage timeline events for this incident'
      end

      context 'when timeline event tags are passed' do
        context 'when predefined tags are passed' do
          let(:params) do
            {
              note: 'Updated note',
              occurred_at: occurred_at,
              timeline_event_tag_names: ['start time', 'end time', 'response initiated']
            }
          end

          it 'returns the new tag in response' do
            timeline_event = execute.payload[:timeline_event]

            expect(timeline_event.timeline_event_tags.pluck_names).to contain_exactly(
              'Start time', 'End time', 'Response initiated')
          end

          it 'creates the predefined tags on the project' do
            execute

            expect(project.incident_management_timeline_event_tags.pluck_names).to include(
              'Start time', 'End time', 'Response initiated')
          end
        end

        context 'when they exist' do
          let(:params) do
            {
              note: 'Updated note',
              occurred_at: occurred_at,
              timeline_event_tag_names: [tag3.name, tag1.name]
            }
          end

          it_behaves_like 'successful tag response'

          context 'when tag name is of random case' do
            let(:params) do
              {
                note: 'Updated note',
                occurred_at: occurred_at,
                timeline_event_tag_names: ['tAg 3', 'TaG 1']
              }
            end

            it_behaves_like 'successful tag response'
          end

          context 'when tag is removed' do
            let(:params) { { note: 'Updated note', occurred_at: occurred_at, timeline_event_tag_names: [tag2.name] } }

            it_behaves_like 'successful response'

            it 'adds the new tag and removes the old tag' do
              # Since it adds a tag (+1) and removes old tag (-1) so next change in count in 0
              expect { execute }.to change { timeline_event.timeline_event_tags.count }.by(0)
            end

            it 'adds the new tag link and removes the old tag link' do
              # Since it adds a tag link (+1) and removes old tag link (-1) so next change in count in 0
              expect { execute }.to change { IncidentManagement::TimelineEventTagLink.count }.by(0)
            end

            it 'returns the new tag and does not contain the old tag in response' do
              timeline_event = execute.payload[:timeline_event]

              expect(timeline_event.timeline_event_tags.pluck_names).to contain_exactly(tag2.name)
            end
          end

          context 'when all assigned tags are removed' do
            let(:params) { { note: 'Updated note', occurred_at: occurred_at, timeline_event_tag_names: [] } }

            it_behaves_like 'successful response'

            it 'removes all the assigned tags' do
              expect { execute }.to change { timeline_event.timeline_event_tags.count }.by(-1)
            end

            it 'removes all the assigned tag links' do
              expect { execute }.to change { IncidentManagement::TimelineEventTagLink.count }.by(-1)
            end

            it 'does not contain any tags in response' do
              timeline_event = execute.payload[:timeline_event]

              expect(timeline_event.timeline_event_tags.pluck_names).to be_empty
            end
          end
        end

        context 'when they do not exist' do
          let(:params) do
            {
              note: 'Updated note 2',
              occurred_at: occurred_at,
              timeline_event_tag_names: ['non existing tag']
            }
          end

          it_behaves_like 'error response', "Following tags don't exist: [\"non existing tag\"]"

          it 'does not update the note' do
            expect { execute }.not_to change { timeline_event.reload.note }
          end
        end
      end
    end

    context 'when user does not have permissions' do
      before do
        project.add_reporter(user)
      end

      it_behaves_like 'error response',
        'You have insufficient permissions to manage timeline events for this incident'
    end
  end
end
