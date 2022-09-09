# frozen_string_literal: true

RSpec.shared_examples 'timeline quick action' do
  describe '/timeline' do
    context 'with valid args' do
      where(:timeline_text, :date_time_arg) do
        [
          ['timeline comment', '2022-09-09 09:30'],
          ['new timeline comment', '09:30'],
          ['another timeline comment', '    2022-09-09 09:15']
        ]
      end

      with_them do
        it 'adds a timeline event' do
          add_note("/timeline #{timeline_text} | #{date_time_arg}")

          expect(page).to have_content('Timeline event added successfully.')
          expect(issue.incident_management_timeline_events.first.note).to eq(timeline_text)
          expect(issue.incident_management_timeline_events.first.occurred_at).to eq(DateTime.parse(date_time_arg))
        end
      end

      it 'adds a timeline event when no date is passed' do
        freeze_time do
          add_note('/timeline timeline event with not date')

          expect(page).to have_content('Timeline event added successfully.')
          expect(issue.incident_management_timeline_events.first.note).to eq('timeline event with not date')
          expect(issue.incident_management_timeline_events.first.occurred_at).to eq(DateTime
            .current.strftime("%Y-%m-%d %H:%M:00 UTC"))
        end
      end

      it 'adds a timeline event when only date is passed' do
        freeze_time do
          add_note('/timeline timeline event with not date | 2022-10-11')

          expect(page).to have_content('Timeline event added successfully.')
          expect(issue.incident_management_timeline_events.first.note).to eq('timeline event with not date')
          expect(issue.incident_management_timeline_events.first.occurred_at).to eq(DateTime
            .current.strftime("%Y-%m-%d %H:%M:00 UTC"))
        end
      end
    end

    context 'with invalid args' do
      where(:timeline_text, :date_time_arg) do
        [
          ['timeline comment', '2022-13-13 09:30'],
          ['timeline comment 2', '2022-09-06 24:30']
        ]
      end

      with_them do
        it 'does not add a timeline event' do
          add_note("/timeline #{timeline_text} | #{date_time_arg}")

          expect(page).to have_content('Failed to apply commands.')
          expect(issue.incident_management_timeline_events.length).to eq(0)
        end
      end
    end

    context 'when create service fails' do
      before do
        allow_next_instance_of(::IncidentManagement::TimelineEvents::CreateService) do |service|
          allow(service).to receive(:execute).and_return(
            ServiceResponse.error(payload: { timeline_event: nil }, message: 'Some error')
          )
        end
      end

      it 'does not add a timeline event' do
        add_note('/timeline text | 2022-09-10 09:30')

        expect(page).to have_content('Something went wrong while adding timeline event.')
        expect(issue.incident_management_timeline_events.length).to eq(0)
      end
    end
  end
end
