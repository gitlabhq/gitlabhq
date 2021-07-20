# frozen_string_literal: true

RSpec.shared_examples 'issuable quick actions' do
  QuickAction = Struct.new(:action_text, :expectation, :before_action, keyword_init: true) do
    # Pass a block as :before_action if
    # issuable state needs to be changed before
    # the quick action is executed.
    def call_before_action
      before_action.call if before_action
    end

    def skip_access_check
      action_text["/todo"] ||
        action_text["/done"] ||
        action_text["/subscribe"] ||
        action_text["/shrug"] ||
        action_text["/tableflip"]
    end
  end

  let(:unlabel_expectation) do
    ->(noteable, can_use_quick_action) {
      if can_use_quick_action
        expect(noteable.labels).to be_empty
      else
        expect(noteable.labels).not_to be_empty
      end
    }
  end

  # Quick actions shared by issues and merge requests
  let(:issuable_quick_actions) do
    [
      QuickAction.new(
        action_text: "/subscribe",
        expectation: ->(noteable, can_use_quick_action) {
          if can_use_quick_action
            expect(noteable).to be_subscribed(note_author, issuable.project)
          else
            expect(noteable).not_to be_subscribed(note_author, issuable.project)
          end
        }
      ),
      QuickAction.new(
        action_text: "/unsubscribe",
        expectation: ->(noteable, can_use_quick_action) {
          expect(noteable).not_to be_subscribed(note_author, issuable.project)
        }
      ),
      QuickAction.new(
        action_text: "/todo",
        expectation: ->(noteable, can_use_quick_action) {
          expect(noteable.todos.count == 1).to eq(can_use_quick_action)
        }
      ),
      QuickAction.new(
        action_text: "/done",
        expectation: ->(noteable, can_use_quick_action) {
          expect(noteable.todos.last.done?).to eq(can_use_quick_action)
        }
      ),
      QuickAction.new(
        action_text: "/close",
        expectation: ->(noteable, can_use_quick_action) {
          expect(noteable.closed?).to eq(can_use_quick_action)
        }
      ),
      QuickAction.new(
        action_text: "/reopen",
        before_action: -> {
          issuable.close
        },
        expectation: ->(noteable, can_use_quick_action) {
          expect(noteable.open?).to eq(can_use_quick_action)
        }
      ),
      QuickAction.new(
        action_text: "/assign @#{user.username}",
        expectation: ->(noteable, can_use_quick_action) {
          if noteable.allows_multiple_assignees?
            expect(noteable.assignees == [old_assignee, user]).to eq(can_use_quick_action)
          else
            expect(noteable.assignees == [user]).to eq(can_use_quick_action)
          end
        }
      ),
      QuickAction.new(
        action_text: "/unassign",
        expectation: ->(noteable, can_use_quick_action) {
          if can_use_quick_action
            expect(noteable.assignees).to be_empty
          else
            expect(noteable.assignees).not_to be_empty
          end
        }
      ),
      QuickAction.new(
        action_text: "/title new title",
        expectation: ->(noteable, can_use_quick_action) {
          expect(noteable.title == "new title").to eq(can_use_quick_action)
        }
      ),
      QuickAction.new(
        action_text: "/lock",
        expectation: ->(noteable, can_use_quick_action) {
          expect(noteable.discussion_locked?).to eq(can_use_quick_action)
        }
      ),
      QuickAction.new(
        action_text: "/unlock",
        before_action: -> {
          issuable.update!(discussion_locked: true)
        },
        expectation: ->(noteable, can_use_quick_action) {
          if can_use_quick_action
            expect(noteable).not_to be_discussion_locked
          else
            expect(noteable).to be_discussion_locked
          end
        }
      ),
      QuickAction.new(
        action_text: "/milestone %\"sprint\"",
        expectation: ->(noteable, can_use_quick_action) {
          expect(noteable.milestone == milestone).to eq(can_use_quick_action)
        }
      ),
      QuickAction.new(
        action_text: "/remove_milestone",
        before_action: -> {
          issuable.update!(milestone_id: milestone.id)
        },
        expectation: ->(noteable, can_use_quick_action) {
          if can_use_quick_action
            expect(noteable.milestone_id).to be_nil
          else
            expect(noteable.milestone_id).to eq(milestone.id)
          end
        }
      ),
      QuickAction.new(
        action_text: "/label ~feature",
        expectation: ->(noteable, can_use_quick_action) {
          expect(noteable.labels&.last&.id == feature_label.id).to eq(can_use_quick_action)
        }
      ),
      QuickAction.new(
        action_text: "/unlabel",
        expectation: unlabel_expectation
      ),
      QuickAction.new(
        action_text: "/remove_label",
        expectation: unlabel_expectation
      ),
      QuickAction.new(
        action_text: "/award :100:",
        expectation: ->(noteable, can_use_quick_action) {
          if can_use_quick_action
            expect(noteable.award_emoji.last.name).to eq("100")
          else
            expect(noteable.award_emoji).to be_empty
          end
        }
      ),
      QuickAction.new(
        action_text: "/estimate 1d 2h 3m",
        expectation: ->(noteable, can_use_quick_action) {
          expect(noteable.time_estimate == 36180).to eq(can_use_quick_action)
        }
      ),
      QuickAction.new(
        action_text: "/remove_estimate",
        before_action: -> {
          issuable.update!(time_estimate: 30000)
        },
        expectation: ->(noteable, can_use_quick_action) {
          if can_use_quick_action
            expect(noteable.time_estimate).to be_zero
          else
            expect(noteable.time_estimate).to eq(30000)
          end
        }
      ),
      QuickAction.new(
        action_text: "/spend 1d 2h 3m",
        expectation: ->(noteable, can_use_quick_action) {
          expect(noteable.total_time_spent == 36180).to eq(can_use_quick_action)
        }
      ),
      QuickAction.new(
        action_text: "/remove_time_spent",
        expectation: ->(noteable, can_use_quick_action) {
          if can_use_quick_action
            expect(noteable.total_time_spent == 0)
          else
            expect(noteable.timelogs).to be_empty
          end
        }
      ),
      QuickAction.new(
        action_text: "/shrug oops",
        expectation: ->(noteable, can_use_quick_action) {
          expect(noteable.notes&.last&.note == "HELLO\noops ¯\\＿(ツ)＿/¯\nWORLD").to eq(can_use_quick_action)
        }
      ),
      QuickAction.new(
        action_text: "/tableflip oops",
        expectation: ->(noteable, can_use_quick_action) {
          expect(noteable.notes&.last&.note == "HELLO\noops (╯°□°)╯︵ ┻━┻\nWORLD").to eq(can_use_quick_action)
        }
      ),
      QuickAction.new(
        action_text: "/copy_metadata #{issue_2.to_reference}",
        expectation: ->(noteable, can_use_quick_action) {
          if can_use_quick_action
            expect(noteable.labels).to eq(issue_2.labels)
            expect(noteable.milestone).to eq(issue_2.milestone)
          else
            expect(noteable.labels).not_to eq(issue_2.labels)
            expect(noteable.milestone).not_to eq(issue_2.milestone)
          end
        }
      )
    ]
  end

  let(:old_assignee) { create(:user) }

  before do
    project.add_developer(old_assignee)
    issuable.update!(assignees: [old_assignee])
  end

  context 'when user can update issuable' do
    let_it_be(:developer) { create(:user) }

    let(:note_author) { developer }

    before do
      project.add_developer(developer)
    end

    it 'saves the note and updates the issue' do
      quick_actions.each do |quick_action|
        note_text = %(HELLO\n#{quick_action.action_text}\nWORLD)
        quick_action.call_before_action

        note = described_class.new(project, developer, note_params.merge(note: note_text)).execute
        noteable = note.noteable

        # shrug and tablefip quick actions modifies the note text
        # on these cases we need to skip this assertion
        if !quick_action.action_text["shrug"] && !quick_action.action_text["tableflip"]
          expect(note.note).to eq "HELLO\nWORLD"
        end

        quick_action.expectation.call(noteable, true)
      end
    end
  end

  context 'when user cannot update issuable' do
    let_it_be(:non_member) { create(:user) }

    let(:note_author) { non_member }

    it 'applies commands that user can execute' do
      quick_actions.each do |quick_action|
        note_text = %(HELLO\n#{quick_action.action_text}\nWORLD)
        quick_action.call_before_action

        note = described_class.new(project, non_member, note_params.merge(note: note_text)).execute
        noteable = note.noteable

        if quick_action.skip_access_check
          quick_action.expectation.call(noteable, true)
        else
          quick_action.expectation.call(noteable, false)
        end
      end
    end
  end
end
