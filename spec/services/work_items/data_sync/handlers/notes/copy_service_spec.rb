# frozen_string_literal: true

require 'spec_helper'

RSpec.describe WorkItems::DataSync::Handlers::Notes::CopyService, feature_category: :team_planning do
  describe '#execute' do
    let_it_be(:current_user) { create(:user) }
    let_it_be(:user2) { create(:user) }
    let_it_be(:group) { create(:group, developers: [current_user]) }

    let_it_be_with_reload(:work_item) { create(:work_item) }
    let_it_be_with_reload(:target_work_item) { create(:work_item) }

    let_it_be(:label_event) { create(:resource_label_event, issue: work_item) }
    let_it_be(:milestone_event) { create(:resource_milestone_event, issue: work_item) }
    let_it_be(:state_event) { create(:resource_state_event, issue: work_item) }

    let_it_be(:system_note_with_description_version_metadata) do
      create(:system_note, project: work_item.project, noteable: work_item).tap do |system_note|
        description_version = create(:description_version, issue: work_item)
        create(:system_note_metadata, description_version: description_version, note: system_note)
      end
    end

    let_it_be(:system_note_with_other_metadata) do
      create(:system_note, project: work_item.project, noteable: work_item).tap do |system_note|
        create(:system_note_metadata, note: system_note)
      end
    end

    let_it_be(:system_note_without_metadata) do
      create(:system_note, project: work_item.project, noteable: work_item)
    end

    let_it_be(:user_notes) do
      create_list(:note, 2, project: work_item.project, noteable: work_item).tap do |notes|
        create_list(:award_emoji, 2, name: AwardEmoji::THUMBS_UP, awardable: notes[0])
        create_list(:award_emoji, 2, name: AwardEmoji::THUMBS_UP, awardable: notes[1])
        create(:issue_user_mention, issue: work_item, note: notes[0], mentioned_users_ids: [user2.id])
        create(:issue_user_mention, issue: work_item, note: notes[1], mentioned_users_ids: [user2.id])
      end
    end

    subject(:execute_service) { described_class.new(current_user, work_item, target_work_item).execute }

    context 'when source_noteable and target_noteable are the same' do
      subject(:execute_service) { described_class.new(current_user, work_item, work_item).execute }

      it 'validates that we cannot copy notes to the same Noteable' do
        response = execute_service

        expect(response).to be_error
        expect(response.message).to eq('Noteables must be different')
      end
    end

    it 'copies notes from work_item to target_work_item', :aggregate_failures do
      expect(::Note).to receive(:insert_all).and_call_original
      expect(::SystemNoteMetadata).to receive(:insert_all).and_call_original
      expect(::AwardEmoji).to receive(:insert_all).and_call_original

      expected_notes_details = work_item.notes.pluck(:note, :discussion_id)

      # 4 notes are copied to the target work item: 2 system notes and 2 user notes
      # 2 system notes had also description version metadata
      # 2 user notes notes had also description version metadata
      expect { execute_service }.to change { ::Note.count }.by(5).and(
        change { ::SystemNoteMetadata.count }.by(2)).and(
          change { ::DescriptionVersion.count }.by(1)).and(
            change { ::AwardEmoji.count }.by(4)).and(
              change { ::IssueUserMention.count }.by(2))

      notes_details = target_work_item.reload.notes.pluck(:note, :discussion_id)
      expect(notes_details).to match_array(expected_notes_details)
    end
  end
end
