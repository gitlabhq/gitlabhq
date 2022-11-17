# frozen_string_literal: true

require 'spec_helper'

RSpec.describe IncidentManagement::TimelineEvents::UpdateService do
  let_it_be(:user) { create(:user) }
  let_it_be(:project) { create(:project) }
  let_it_be(:incident) { create(:incident, project: project) }

  let!(:timeline_event) { create(:incident_management_timeline_event, project: project, incident: incident) }
  let(:occurred_at) { 1.minute.ago }
  let(:params) { { note: 'Updated note', occurred_at: occurred_at } }
  let(:current_user) { user }

  describe '#execute' do
    shared_examples 'successful response' do
      it 'responds with success', :aggregate_failures do
        expect(execute).to be_success
        expect(execute.payload).to eq(timeline_event: timeline_event.reload)
      end

      it_behaves_like 'an incident management tracked event', :incident_management_timeline_event_edited
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
        let(:params) { { occurred_at: occurred_at } }

        it_behaves_like 'successful response'
        it_behaves_like 'passing the correct was_changed value', :occurred_at

        it 'does not update the note' do
          expect { execute }.not_to change { timeline_event.reload.note }
        end

        it 'updates occurred_at' do
          expect { execute }.to change { timeline_event.occurred_at }.to(params[:occurred_at])
        end
      end

      context 'when note is blank' do
        let(:params) { { note: '', occurred_at: occurred_at } }

        it_behaves_like 'error response', "Timeline text can't be blank"
      end

      context 'when note is more than 280 characters long' do
        let(:params) { { note: 'n' * 281, occurred_at: occurred_at } }

        it_behaves_like 'error response', 'Timeline text is too long (maximum is 280 characters)'
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
        let(:params) { { note: 'Updated note', occurred_at: '' } }

        it_behaves_like 'error response', "Occurred at can't be blank"
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
