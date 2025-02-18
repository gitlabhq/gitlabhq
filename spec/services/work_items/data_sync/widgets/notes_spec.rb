# frozen_string_literal: true

require 'spec_helper'

RSpec.describe WorkItems::DataSync::Widgets::Notes, feature_category: :team_planning do
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

  let(:params) { { operation: :move } }

  subject(:callback) do
    described_class.new(
      work_item: work_item, target_work_item: target_work_item, current_user: current_user, params: params
    )
  end

  describe '#after_save_commit' do
    context 'when cloning work item without notes option' do
      let(:params) { { operation: :clone } }

      it 'does not copy notes or resource events' do
        expect(::Gitlab::Issuable::Clone::CopyResourceEventsService).not_to receive(:new)
        expect(::WorkItems::DataSync::Handlers::Notes::CopyService).not_to receive(:new)

        expect { callback.after_save_commit }.to not_change { ::Note.count }.and(
          not_change { ::ResourceLabelEvent.count }.and(
            not_change { ::ResourceMilestoneEvent.count }).and(
              not_change { ::ResourceStateEvent.count })
        )
      end
    end

    context 'when target work item does not have notes widget' do
      before do
        allow(target_work_item).to receive(:get_widget).with(:notes).and_return(false)
      end

      shared_examples 'does not copy notes, copies resource events' do
        it 'does not copy notes' do
          expect(::Gitlab::Issuable::Clone::CopyResourceEventsService).to receive(:new).and_call_original
          expect(::WorkItems::DataSync::Handlers::Notes::CopyService).not_to receive(:new)

          expect { callback.after_save_commit }.to not_change { ::Note.count }
        end

        it 'copies resource events' do
          expect { callback.after_save_commit }.to change { ::ResourceLabelEvent.count }.by(1).and(
            change { ::ResourceMilestoneEvent.count }.by(1)).and(
              change { ::ResourceStateEvent.count }.by(1))
        end
      end

      context 'when cloning work item with notes option' do
        let(:params) { { operation: :clone, clone_with_notes: true } }

        it_behaves_like 'does not copy notes, copies resource events'
      end

      context 'when moving work item' do
        it_behaves_like 'does not copy notes, copies resource events'
      end
    end

    context 'when target work item has notes widget' do
      shared_examples 'copies notes and resource events' do
        it 'copies notes from work_item to target_work_item', :aggregate_failures do
          expect(::Gitlab::Issuable::Clone::CopyResourceEventsService).to receive(:new).and_call_original
          expect(::WorkItems::DataSync::Handlers::Notes::CopyService).to receive(:new).and_call_original

          expected_notes_details = work_item.notes.pluck(:note, :discussion_id)

          # 4 notes are copied to the target work item: 2 system notes and 2 user notes
          # 2 system notes had also description version metadata
          # 2 user notes notes had also description version metadata
          expect { callback.after_save_commit }.to change { ::Note.count }.by(5).and(
            change { ::SystemNoteMetadata.count }.by(2)).and(
              change { ::DescriptionVersion.count }.by(1)).and(
                change { ::AwardEmoji.count }.by(4)).and(
                  change { ::ResourceLabelEvent.count }.by(1)).and(
                    change { ::ResourceMilestoneEvent.count }.by(1)).and(
                      change { ::ResourceStateEvent.count }.by(1)).and(
                        change { ::IssueUserMention.count }.by(2))

          notes_details = target_work_item.reload.notes.pluck(:note, :discussion_id)
          expect(notes_details).to match_array(expected_notes_details)
        end
      end

      context 'when cloning work item without notes option' do
        let(:params) { { operation: :clone, clone_with_notes: true } }

        it_behaves_like 'copies notes and resource events'
      end

      context 'when moving work item' do
        it_behaves_like 'copies notes and resource events'
      end
    end
  end

  describe '#post_move_cleanup' do
    before do
      stub_const("#{described_class}::BATCH_SIZE", 2)
    end

    it 'removes original work item notes' do
      expect { callback.post_move_cleanup }.to change { work_item.reload.notes.count }.from(5).to(0).and(
        change { SystemNoteMetadata.count }.by(-2)).and(
          change { AwardEmoji.count }.by(-4)).and(
            change { IssueUserMention.count }.by(-2))
    end
  end
end
