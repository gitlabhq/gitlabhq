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
      # 2 user notes had also description version metadata
      expect { execute_service }.to change { ::Note.count }.by(5).and(
        change { ::SystemNoteMetadata.count }.by(2)).and(
          change { ::DescriptionVersion.count }.by(1)).and(
            change { ::AwardEmoji.count }.by(4)).and(
              change { ::IssueUserMention.count }.by(2))

      notes_details = target_work_item.reload.notes.pluck(:note, :discussion_id)
      # same number of discussions in target and source work items
      expect(notes_details.size).to eq(expected_notes_details.size)
      # but with different discussion ids
      expect(notes_details).not_to match_array(expected_notes_details)
    end

    it 'sets correct attributes from target on copied description versions', :aggregate_failures do
      expect { execute_service }.to change { ::DescriptionVersion.count }.by(1)

      expected_description_version = DescriptionVersion.last

      expect(expected_description_version.namespace_id).to eq(target_work_item.namespace_id)
      expect(expected_description_version.issue_id).to eq(target_work_item.id)
    end

    it 'sets correct attributes from target on copied award emoji', :aggregate_failures do
      expect { execute_service }.to change { ::AwardEmoji.count }.by(4)

      copied_award_emoji = AwardEmoji.last(4)

      expect(copied_award_emoji).to contain_exactly(
        have_attributes(organization_id: nil, namespace_id: target_work_item.namespace_id),
        have_attributes(organization_id: nil, namespace_id: target_work_item.namespace_id),
        have_attributes(organization_id: nil, namespace_id: target_work_item.namespace_id),
        have_attributes(organization_id: nil, namespace_id: target_work_item.namespace_id)
      )
    end

    it 'sets correct attributes from target on copied system_note_metadata', :aggregate_failures do
      expect { execute_service }.to change { ::SystemNoteMetadata.count }.by(2)

      copied_system_note_metadata = SystemNoteMetadata.last(2)

      expect(copied_system_note_metadata).to contain_exactly(
        have_attributes(organization_id: nil, namespace_id: target_work_item.namespace_id),
        have_attributes(organization_id: nil, namespace_id: target_work_item.namespace_id)
      )
    end

    describe 'discussion_id generation' do
      it 'generates new discussion_ids for copied notes' do
        original_discussion_ids = work_item.notes.pluck(:discussion_id).uniq

        execute_service

        copied_discussion_ids = target_work_item.reload.notes.pluck(:discussion_id).uniq

        # All copied notes should have different discussion_ids from originals
        expect(copied_discussion_ids).not_to include(*original_discussion_ids)
        # Each copied discussion_id should be a valid 40-character hex string
        copied_discussion_ids.all? { |discussion_id| expect(discussion_id).to match(/\A\h{40}\z/) }
      end

      it 'reuses the same new discussion_id for notes in the same discussion' do
        # Create notes that are part of the same discussion
        discussion_note = create(:note, project: work_item.project, noteable: work_item)
        reply_note = create(:note,
          project: work_item.project,
          noteable: work_item,
          discussion_id: discussion_note.discussion_id,
          in_reply_to: discussion_note
        )

        execute_service

        copied_notes = target_work_item.reload.notes.where(note: [discussion_note.note, reply_note.note])
        copied_discussion_ids = copied_notes.pluck(:discussion_id).uniq

        # Both copied notes should have the same new discussion_id
        expect(copied_discussion_ids.size).to eq(1)
        # But it should be different from the original
        expect(copied_discussion_ids.first).not_to eq(discussion_note.discussion_id)
      end

      it 'generates different discussion_ids for different original discussions' do
        # Create two separate discussions
        discussion1_note = create(:note, project: work_item.project, noteable: work_item)
        discussion2_note = create(:note, project: work_item.project, noteable: work_item)

        execute_service

        copied_notes = target_work_item.reload.notes.where(note: [discussion1_note.note, discussion2_note.note])
        copied_discussion_ids = copied_notes.pluck(:discussion_id)

        # Each copied note should have a different discussion_id
        expect(copied_discussion_ids.uniq.size).to eq(2)
        expect(copied_discussion_ids).not_to include(discussion1_note.discussion_id, discussion2_note.discussion_id)
      end

      it 'calls Discussion.discussion_id to generate new discussion_ids' do
        expect(::Discussion).to receive(:discussion_id).at_least(:once).and_call_original

        execute_service
      end

      it 'maintains discussion structure when copying notes with replies' do
        # Create a discussion with multiple replies
        parent_note = create(:note, project: work_item.project, noteable: work_item, note: 'Parent note')
        create(:note,
          project: work_item.project,
          noteable: work_item,
          note: 'Reply 1',
          discussion_id: parent_note.discussion_id,
          in_reply_to: parent_note
        )
        create(:note,
          project: work_item.project,
          noteable: work_item,
          note: 'Reply 2',
          discussion_id: parent_note.discussion_id,
          in_reply_to: parent_note
        )

        execute_service

        # Find the copied notes
        copied_parent = target_work_item.reload.notes.find_by(note: 'Parent note')
        copied_reply1 = target_work_item.notes.find_by(note: 'Reply 1')
        copied_reply2 = target_work_item.notes.find_by(note: 'Reply 2')

        # All copied notes should have the same new discussion_id
        expect(copied_parent.discussion_id).to eq(copied_reply1.discussion_id)
        expect(copied_parent.discussion_id).to eq(copied_reply2.discussion_id)

        # But different from the original
        expect(copied_parent.discussion_id).not_to eq(parent_note.discussion_id)

        # Verify the discussion structure is maintained
        discussion = target_work_item.notes.find_discussion(copied_parent.discussion_id)
        expect(discussion.notes.size).to eq(3)
        expect(discussion.notes.map(&:note)).to contain_exactly('Parent note', 'Reply 1', 'Reply 2')
      end
    end
  end
end
