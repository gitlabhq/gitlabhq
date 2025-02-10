# frozen_string_literal: true

require 'spec_helper'

RSpec.describe QuickActions::InterpretService, feature_category: :text_editors do
  include AfterNextHelpers

  let_it_be(:support_bot) { Users::Internal.support_bot }
  let_it_be(:group) { create(:group) }
  let_it_be(:public_project) { create(:project, :public, group: group) }
  let_it_be(:repository_project) { create(:project, :repository) }
  let_it_be(:project) { public_project }
  let_it_be(:developer) { create(:user, developer_of: [public_project, repository_project]) }
  let_it_be(:developer2) { create(:user) }
  let_it_be(:developer3) { create(:user) }
  let_it_be_with_reload(:issue) { create(:issue, project: project) }
  let_it_be(:inprogress) { create(:label, project: project, title: 'In Progress') }
  let_it_be(:helmchart) { create(:label, project: project, title: 'Helm Chart Registry') }
  let_it_be(:bug) { create(:label, project: project, title: 'Bug') }

  let(:milestone) { create(:milestone, project: project, title: '9.10') }
  let(:commit) { create(:commit, project: project) }
  let(:current_user) { developer }
  let(:container) { project }

  subject(:service) { described_class.new(container: container, current_user: current_user) }

  before do
    stub_licensed_features(
      multiple_issue_assignees: false,
      multiple_merge_request_reviewers: false,
      multiple_merge_request_assignees: false
    )
    project.add_developer(current_user)
  end

  before_all { Users::Internal.support_bot_id }

  describe '#execute' do
    let_it_be(:work_item) { create(:work_item, :task, project: project) }
    let(:merge_request) { create(:merge_request, source_project: project) }

    shared_examples 'reopen command' do
      it 'returns state_event: "reopen" if content contains /reopen' do
        issuable.close!
        _, updates, _ = service.execute(content, issuable)

        expect(updates).to eq(state_event: 'reopen')
      end

      it 'returns the reopen message' do
        issuable.close!
        _, _, message = service.execute(content, issuable)
        translated_string = _("Reopened this %{issuable_to_ability_name_humanize}.")
        formatted_message = format(translated_string, issuable_to_ability_name_humanize: issuable.to_ability_name.humanize(capitalize: false).to_s)

        expect(message).to eq(formatted_message)
      end
    end

    shared_examples 'close command' do
      it 'returns state_event: "close" if content contains /close' do
        _, updates, _ = service.execute(content, issuable)

        expect(updates).to eq(state_event: 'close')
      end

      it 'returns the close message' do
        _, _, message = service.execute(content, issuable)
        translated_string = _("Closed this %{issuable_to_ability_name_humanize}.")
        formatted_message = format(translated_string, issuable_to_ability_name_humanize: issuable.to_ability_name.humanize(capitalize: false).to_s)

        expect(message).to eq(formatted_message)
      end
    end

    shared_examples 'title command' do
      it 'populates title: "A brand new title" if content contains /title A brand new title' do
        _, updates, _ = service.execute(content, issuable)

        expect(updates).to eq(title: 'A brand new title')
      end

      it 'returns the title message' do
        _, _, message = service.execute(content, issuable)

        expect(message).to eq(_(%(Changed the title to "A brand new title".)))
      end
    end

    shared_examples 'milestone command' do
      it 'fetches milestone and populates milestone_id if content contains /milestone' do
        milestone # populate the milestone
        _, updates, _ = service.execute(content, issuable)

        expect(updates).to eq(milestone_id: milestone.id)
      end

      it 'returns the milestone message' do
        milestone # populate the milestone
        _, _, message = service.execute(content, issuable)
        translated_string = _("Set the milestone to %{milestone_to_reference}.")
        formatted_message = format(translated_string, milestone_to_reference: milestone.to_reference.to_s)

        expect(message).to eq(formatted_message)
      end

      it 'returns empty milestone message when milestone is wrong' do
        _, _, message = service.execute('/milestone %wrong-milestone', issuable)

        expect(message).to be_empty
      end
    end

    shared_examples 'remove_milestone command' do
      it 'populates milestone_id: nil if content contains /remove_milestone' do
        issuable.update!(milestone_id: milestone.id)
        _, updates, _ = service.execute(content, issuable)

        expect(updates).to eq(milestone_id: nil)
      end

      it 'returns removed milestone message' do
        issuable.update!(milestone_id: milestone.id)
        _, _, message = service.execute(content, issuable)
        translated_string = _("Removed %{milestone_to_reference} milestone.")
        formatted_message = format(translated_string, milestone_to_reference: milestone.to_reference.to_s)

        expect(message).to eq(formatted_message)
      end
    end

    shared_examples 'label command' do
      it 'fetches label ids and populates add_label_ids if content contains /label' do
        bug # populate the label
        inprogress # populate the label
        _, updates, _ = service.execute(content, issuable)

        expect(updates).to match(add_label_ids: contain_exactly(bug.id, inprogress.id))
      end

      it 'returns the label message' do
        bug # populate the label
        inprogress # populate the label
        _, _, message = service.execute(content, issuable)

        # Compare message without making assumptions about ordering.
        expect(message).to match %r{Added ~".*" ~".*" labels.}
        expect(message).to include(bug.to_reference(format: :name))
        expect(message).to include(inprogress.to_reference(format: :name))
      end
    end

    shared_examples 'multiple label command' do
      it 'fetches label ids and populates add_label_ids if content contains multiple /label' do
        bug # populate the label
        inprogress # populate the label
        _, updates, _ = service.execute(content, issuable)

        expect(updates).to eq(add_label_ids: [inprogress.id, bug.id])
      end
    end

    shared_examples 'multiple label with same argument' do
      it 'prevents duplicate label ids and populates add_label_ids if content contains multiple /label' do
        inprogress # populate the label
        _, updates, _ = service.execute(content, issuable)

        expect(updates).to eq(add_label_ids: [inprogress.id])
      end
    end

    shared_examples 'multiword label name starting without ~' do
      it 'fetches label ids and populates add_label_ids if content contains /label' do
        _, updates = service.execute(content, issuable)

        expect(updates).to eq(add_label_ids: [helmchart.id])
      end
    end

    shared_examples 'label name is included in the middle of another label name' do
      it 'ignores the sublabel when the content contains the includer label name' do
        create(:label, project: project, title: 'Chart')

        _, updates = service.execute(content, issuable)

        expect(updates).to eq(add_label_ids: [helmchart.id])
      end
    end

    shared_examples 'unlabel command' do
      it 'fetches label ids and populates remove_label_ids if content contains /unlabel' do
        issuable.update!(label_ids: [inprogress.id]) # populate the label
        _, updates, _ = service.execute(content, issuable)

        expect(updates).to eq(remove_label_ids: [inprogress.id])
      end

      it 'returns the unlabel message' do
        issuable.update!(label_ids: [inprogress.id]) # populate the label
        _, _, message = service.execute(content, issuable)
        translated_string = _("Removed %{inprogress_to_reference} label.")
        formatted_message = format(translated_string, inprogress_to_reference: inprogress.to_reference(format: :name).to_s)

        expect(message).to eq(formatted_message)
      end
    end

    shared_examples 'multiple unlabel command' do
      it 'fetches label ids and populates remove_label_ids if content contains  mutiple /unlabel' do
        issuable.update!(label_ids: [inprogress.id, bug.id]) # populate the label
        _, updates, _ = service.execute(content, issuable)

        expect(updates).to eq(remove_label_ids: [inprogress.id, bug.id])
      end
    end

    shared_examples 'unlabel command with no argument' do
      it 'populates label_ids: [] if content contains /unlabel with no arguments' do
        issuable.update!(label_ids: [inprogress.id]) # populate the label
        _, updates, _ = service.execute(content, issuable)

        expect(updates).to eq(label_ids: [])
      end
    end

    shared_examples 'relabel command' do
      it 'populates label_ids: [] if content contains /relabel' do
        issuable.update!(label_ids: [bug.id]) # populate the label
        inprogress # populate the label
        _, updates, _ = service.execute(content, issuable)

        expect(updates).to eq(label_ids: [inprogress.id])
      end

      it 'returns the relabel message' do
        issuable.update!(label_ids: [bug.id]) # populate the label
        inprogress # populate the label
        _, _, message = service.execute(content, issuable)
        translated_string = _("Replaced all labels with %{inprogress_to_reference} label.")
        formatted_message = format(translated_string, inprogress_to_reference: inprogress.to_reference(format: :name).to_s)

        expect(message).to eq(formatted_message)
      end
    end

    shared_examples 'todo command' do
      it 'populates todo_event: "add" if content contains /todo' do
        _, updates, _ = service.execute(content, issuable)

        expect(updates).to eq(todo_event: 'add')
      end

      it 'returns the todo message' do
        _, _, message = service.execute(content, issuable)

        expect(message).to eq(_('Added a to-do item.'))
      end
    end

    shared_examples 'done command' do
      it 'populates todo_event: "done" if content contains /done' do
        TodoService.new.mark_todo(issuable, developer)
        _, updates, _ = service.execute(content, issuable)

        expect(updates).to eq(todo_event: 'done')
      end

      it 'returns the done message' do
        TodoService.new.mark_todo(issuable, developer)
        _, _, message = service.execute(content, issuable)

        expect(message).to eq(_('Marked to-do item as done.'))
      end
    end

    shared_examples 'subscribe command' do
      it 'populates subscription_event: "subscribe" if content contains /subscribe' do
        _, updates, _ = service.execute(content, issuable)

        expect(updates).to eq(subscription_event: 'subscribe')
      end

      it 'returns the subscribe message' do
        _, _, message = service.execute(content, issuable)
        expect(message).to eq(_("Subscribed to notifications."))
      end
    end

    shared_examples 'unsubscribe command' do
      it 'populates subscription_event: "unsubscribe" if content contains /unsubscribe' do
        issuable.subscribe(developer, project)
        _, updates, _ = service.execute(content, issuable)

        expect(updates).to eq(subscription_event: 'unsubscribe')
      end

      it 'returns the unsubscribe message' do
        issuable.subscribe(developer, project)
        _, _, message = service.execute(content, issuable)
        expect(message).to eq(_("Unsubscribed from notifications."))
      end
    end

    shared_examples 'due command' do
      let(:expected_date) { Date.new(2016, 8, 28) }

      it 'populates due_date: Date.new(2016, 8, 28) if content contains /due 2016-08-28' do
        _, updates, _ = service.execute(content, issuable)

        expect(updates).to eq(due_date: expected_date)
      end

      it 'returns due_date message: Date.new(2016, 8, 28) if content contains /due 2016-08-28' do
        _, _, message = service.execute(content, issuable)
        translated_string = _("Set the due date to %{expected_date_to_fs}.")
        formatted_message = format(translated_string, expected_date_to_fs: expected_date.to_fs(:medium).to_s)

        expect(message).to eq(formatted_message)
      end
    end

    shared_examples 'remove_due_date command' do
      before do
        issuable.update!(due_date: Date.today)
      end

      it 'populates due_date: nil if content contains /remove_due_date' do
        _, updates, _ = service.execute(content, issuable)

        expect(updates).to eq(due_date: nil)
      end

      it 'returns Removed the due date' do
        _, _, message = service.execute(content, issuable)

        expect(message).to eq(_('Removed the due date.'))
      end
    end

    shared_examples 'draft command' do
      it 'returns wip_event: "draft"' do
        _, updates, _ = service.execute(content, issuable)

        expect(updates).to eq(wip_event: 'draft')
      end

      it 'returns the draft message' do
        _, _, message = service.execute(content, issuable)
        translated_string = _("Marked this %{issuable_to_ability_name_humanize} as a draft.")
        formatted_message = format(translated_string, issuable_to_ability_name_humanize: issuable.to_ability_name.humanize(capitalize: false).to_s)

        expect(message).to eq(formatted_message)
      end
    end

    shared_examples 'draft/ready command no action' do
      it 'returns the no action message if there is no change to the status' do
        _, _, message = service.execute(content, issuable)
        translated_string = _("No change to this %{issuable_to_ability_name_humanize}'s draft status.")
        formatted_message = format(translated_string, issuable_to_ability_name_humanize: issuable.to_ability_name.humanize(capitalize: false).to_s)

        expect(message).to eq(formatted_message)
      end
    end

    shared_examples 'ready command' do
      it 'returns wip_event: "ready"' do
        issuable.update!(title: issuable.draft_title)
        _, updates, _ = service.execute(content, issuable)

        expect(updates).to eq(wip_event: 'ready')
      end

      it 'returns the ready message' do
        issuable.update!(title: issuable.draft_title)
        _, _, message = service.execute(content, issuable)
        translated_string = _("Marked this %{issuable_to_ability_name_humanize} as ready.")
        formatted_message = format(translated_string, issuable_to_ability_name_humanize: issuable.to_ability_name.humanize(capitalize: false).to_s)

        expect(message).to eq(formatted_message)
      end
    end

    shared_examples 'estimate command' do
      it 'populates time_estimate: 3600 if content contains /estimate 1h' do
        _, updates, _ = service.execute(content, issuable)

        expect(updates).to eq(time_estimate: 3600)
      end

      it 'returns the time_estimate formatted message' do
        _, _, message = service.execute('/estimate 79d', issuable)

        expect(message).to eq(_('Set time estimate to 3mo 3w 4d.'))
      end
    end

    shared_examples 'spend command' do
      it 'populates spend_time: 3600 if content contains /spend 1h' do
        freeze_time do
          _, updates, _ = service.execute(content, issuable)

          expect(updates).to eq(spend_time: {
                                  category: nil,
                                  duration: 3600,
                                  user_id: developer.id,
                                  spent_at: DateTime.current
                                })
        end
      end
    end

    shared_examples 'spend command with negative time' do
      it 'populates spend_time: -7200 if content contains -120m' do
        freeze_time do
          _, updates, _ = service.execute(content, issuable)

          expect(updates).to eq(spend_time: {
                                  category: nil,
                                  duration: -7200,
                                  user_id: developer.id,
                                  spent_at: DateTime.current
                                })
        end
      end

      it 'returns the spend_time message including the formatted duration and verb' do
        _, _, message = service.execute(content, issuable)

        expect(message).to eq(_('Subtracted 2h spent time.'))
      end
    end

    shared_examples 'spend command with valid date' do
      it 'populates spend time: 1800 with date in date type format' do
        _, updates, _ = service.execute(content, issuable)

        expect(updates).to eq(spend_time: {
                                category: nil,
                                duration: 1800,
                                user_id: developer.id,
                                spent_at: Date.parse(date)
                              })
      end
    end

    shared_examples 'spend command with invalid date' do
      it 'will not create any note and timelog' do
        _, updates, _ = service.execute(content, issuable)

        expect(updates).to eq({})
      end
    end

    shared_examples 'spend command with future date' do
      it 'will not create any note and timelog' do
        _, updates, _ = service.execute(content, issuable)

        expect(updates).to eq({})
      end
    end

    shared_examples 'spend command with category' do
      it 'populates spend_time with expected attributes' do
        _, updates, _ = service.execute(content, issuable)

        expect(updates).to match(spend_time: a_hash_including(category: 'pm'))
      end
    end

    shared_examples 'remove_estimate command' do
      it 'populates time_estimate: 0 if content contains /remove_estimate' do
        _, updates, _ = service.execute(content, issuable)

        expect(updates).to eq(time_estimate: 0)
      end

      it 'returns the remove_estimate message' do
        _, _, message = service.execute(content, issuable)

        expect(message).to eq(_('Removed time estimate.'))
      end
    end

    shared_examples 'remove_time_spent command' do
      it 'populates spend_time: :reset if content contains /remove_time_spent' do
        _, updates, _ = service.execute(content, issuable)

        expect(updates).to eq(spend_time: { duration: :reset, user_id: developer.id })
      end

      it 'returns the remove_time_spent message' do
        _, _, message = service.execute(content, issuable)

        expect(message).to eq(_('Removed spent time.'))
      end
    end

    shared_examples 'lock command' do
      let(:issue) { create(:issue, project: project, discussion_locked: false) }
      let(:merge_request) { create(:merge_request, source_project: project, discussion_locked: false) }

      it 'returns discussion_locked: true if content contains /lock' do
        _, updates, _ = service.execute(content, issuable)

        expect(updates).to eq(discussion_locked: true)
      end

      it 'returns the lock discussion message' do
        _, _, message = service.execute(content, issuable)

        expect(message).to eq(_('Locked the discussion.'))
      end
    end

    shared_examples 'unlock command' do
      let(:issue) { create(:issue, project: project, discussion_locked: true) }
      let(:merge_request) { create(:merge_request, source_project: project, discussion_locked: true) }

      it 'returns discussion_locked: true if content contains /unlock' do
        _, updates, _ = service.execute(content, issuable)

        expect(updates).to eq(discussion_locked: false)
      end

      it 'returns the unlock discussion message' do
        _, _, message = service.execute(content, issuable)

        expect(message).to eq(_('Unlocked the discussion.'))
      end
    end

    shared_examples 'failed command' do |error_msg|
      let(:msg) { error_msg || try(:output_msg) }
      let(:match_msg) { msg ? eq(msg) : be_empty }

      it 'populates {} if content contains an unsupported command' do
        _, updates, _ = service.execute(content, issuable)

        expect(updates).to be_empty
      end

      it "returns #{error_msg || 'an empty'} message" do
        _, _, message = service.execute(content, issuable)

        expect(message).to match_msg
      end
    end

    shared_examples 'explain message' do |error_msg|
      let(:msg) { error_msg || try(:output_msg) }
      let(:match_msg) { msg ? include(msg) : be_empty }

      it "returns #{error_msg || 'an empty'} message" do
        _, message = service.explain(content, issuable)

        expect(message).to match_msg
      end
    end

    shared_examples 'merge immediately command' do
      let(:project) { repository_project }

      it 'runs merge command if content contains /merge' do
        _, updates, _ = service.execute(content, issuable)

        expect(updates).to eq(merge: merge_request.diff_head_sha)
      end

      it 'returns them merge message' do
        _, _, message = service.execute(content, issuable)

        expect(message).to eq(_('Merged this merge request.'))
      end
    end

    shared_examples 'merge automatically command' do
      let(:project) { repository_project }

      before do
        stub_licensed_features(merge_request_approvers: true) if Gitlab.ee?
      end

      it 'runs merge command if content contains /merge and returns merge message' do
        _, updates, message = service.execute(content, issuable)

        expect(updates).to eq(merge: merge_request.diff_head_sha)

        expect(message).to eq(_('Scheduled to merge this merge request (Merge when checks pass).'))
      end
    end

    shared_examples 'react command' do |command|
      it "toggle award 100 emoji if content contains #{command} :100:" do
        _, updates, _ = service.execute(content, issuable)

        expect(updates).to eq(emoji_award: "100")
      end

      it 'returns the reaction message' do
        _, _, message = service.execute(content, issuable)

        expect(message).to eq(_('Toggled :100: emoji reaction.'))
      end
    end

    shared_examples 'copy_metadata command' do
      it 'fetches issue or merge request and copies labels and milestone if content contains /copy_metadata reference' do
        source_issuable # populate the issue
        todo_label # populate this label
        inreview_label # populate this label
        _, updates, _ = service.execute(content, issuable)

        expect(updates[:add_label_ids]).to match_array([inreview_label.id, todo_label.id])

        if source_issuable.milestone
          expect(updates[:milestone_id]).to eq(source_issuable.milestone.id)
        else
          expect(updates).not_to have_key(:milestone_id)
        end
      end

      it 'returns the copy metadata message' do
        _, _, message = service.execute("/copy_metadata #{source_issuable.to_reference}", issuable)
        translated_string = _("Copied labels and milestone from %{source_issuable_to_reference}.")
        formatted_message = format(translated_string, source_issuable_to_reference: source_issuable.to_reference.to_s)

        expect(message).to eq(formatted_message)
      end
    end

    describe 'move issue command' do
      it 'returns the move issue message' do
        _, _, message = service.execute("/move #{project.full_path}", issue)
        translated_string = _("Moved this issue to %{project_full_path}.")
        formatted_message = format(translated_string, project_full_path: project.full_path.to_s)

        expect(message).to eq(formatted_message)
      end

      it 'returns move issue failure message when the referenced issue is not found' do
        _, _, message = service.execute('/move invalid', issue)

        expect(message).to eq(_("Failed to move this issue because target project doesn't exist."))
      end

      context "when we pass a work_item" do
        let(:work_item) { create(:work_item, :issue, project: project) }
        let(:move_command) { "/move #{project.full_path}" }

        it '/move execution method message' do
          _, _, message = service.execute(move_command, work_item)

          expect(message).to eq("Moved this issue to #{project.full_path}.")
        end
      end
    end

    describe 'clone issue command' do
      it 'returns the clone issue message' do
        _, _, message = service.execute("/clone #{project.full_path}", issue)
        translated_string = _("Cloned this issue to %{project_full_path}.")
        formatted_message = format(translated_string, project_full_path: project.full_path.to_s)

        expect(message).to eq(formatted_message)
      end

      it 'returns clone issue failure message when the referenced issue is not found' do
        _, _, message = service.execute('/clone invalid', issue)

        expect(message).to eq(_("Failed to clone this issue because target project doesn't exist."))
      end

      context "when we pass a work_item" do
        let(:work_item) { create(:work_item, :issue, project: project) }

        it '/clone execution method message' do
          _, _, message = service.execute("/clone #{project.full_path}", work_item)

          expect(message).to eq("Cloned this issue to #{project.full_path}.")
        end
      end
    end

    shared_examples 'confidential command' do
      it 'marks issue as confidential if content contains /confidential' do
        _, updates, _ = service.execute(content, issuable)

        expect(updates).to eq(confidential: true)
      end

      it 'returns the confidential message' do
        _, _, message = service.execute(content, issuable)
        translated_string = _("Made this %{issuable_type} confidential.")
        issuable_type = if issuable.to_ability_name == "work_item"
                          'item'
                        else
                          issuable.to_ability_name.humanize(capitalize: false)
                        end

        formatted_message = format(translated_string, issuable_type: issuable_type.to_s)

        expect(message).to eq(formatted_message)
      end

      context 'when issuable is already confidential' do
        before do
          issuable.update!(confidential: true)
        end

        it 'returns an error message' do
          _, _, message = service.execute(content, issuable)

          expect(message).to eq(_('Could not apply confidential command.'))
        end

        it 'is not part of the available commands' do
          expect(service.available_commands(issuable)).not_to include(a_hash_including(name: :confidential))
        end
      end
    end

    shared_examples 'approve command unavailable' do
      it 'is not part of the available commands' do
        expect(service.available_commands(issuable)).not_to include(a_hash_including(name: :approve))
      end
    end

    shared_examples 'unapprove command unavailable' do
      it 'is not part of the available commands' do
        expect(service.available_commands(issuable)).not_to include(a_hash_including(name: :unapprove))
      end
    end

    shared_examples 'shrug command' do
      it 'adds ¯\_(ツ)_/¯' do
        new_content, _, _ = service.execute(content, issuable)

        expect(new_content).to eq(described_class::SHRUG)
      end
    end

    shared_examples 'tableflip command' do
      it 'adds (╯°□°)╯︵ ┻━┻' do
        new_content, _, _ = service.execute(content, issuable)

        expect(new_content).to eq(described_class::TABLEFLIP)
      end
    end

    shared_examples 'tag command' do
      it 'tags a commit' do
        _, updates, _ = service.execute(content, issuable)

        expect(updates).to eq(tag_name: tag_name, tag_message: tag_message)
      end

      it 'returns the tag message' do
        _, _, message = service.execute(content, issuable)

        if tag_message.present?
          translated_string = _(%(Tagged this commit to %{tag_name} with "%{tag_message}".))
          formatted_message = format(translated_string, tag_name: tag_name.to_s, tag_message: tag_message)
        else
          translated_string = _("Tagged this commit to %{tag_name}.")
          formatted_message = format(translated_string, tag_name: tag_name.to_s)
        end

        expect(message).to eq(formatted_message)
      end
    end

    shared_examples 'assign command' do
      it 'assigns to me' do
        cmd = '/assign me'

        _, updates, _ = service.execute(cmd, issuable)

        expect(updates).to eq(assignee_ids: [current_user.id])
      end

      it 'does not assign to group members' do
        grp = create(:group)
        grp.add_developer(developer)
        grp.add_developer(developer2)

        cmd = "/assign #{grp.to_reference}"

        _, updates, message = service.execute(cmd, issuable)

        expect(updates).to be_blank
        expect(message).to include(_('Failed to find users'))
      end

      context 'when there are too many references' do
        before do
          stub_const('Gitlab::QuickActions::UsersExtractor::MAX_QUICK_ACTION_USERS', 2)
        end

        it 'says what went wrong' do
          cmd = '/assign her and you, me and them'

          _, updates, message = service.execute(cmd, issuable)

          expect(updates).to be_blank
          expect(message).to include(_('Too many references. Quick actions are limited to at most 2 user references'))
        end
      end

      context 'when the user extractor raises an uninticipated error' do
        before do
          allow_next(Gitlab::QuickActions::UsersExtractor)
            .to receive(:execute).and_raise(Gitlab::QuickActions::UsersExtractor::Error)
        end

        it 'tracks the exception in dev, and reports a generic message in production' do
          expect(Gitlab::ErrorTracking).to receive(:track_and_raise_for_dev_exception).twice

          _, updates, message = service.execute('/assign some text', issuable)

          expect(updates).to be_blank
          expect(message).to include(_('Something went wrong'))
        end
      end

      it 'assigns to users with escaped underscores' do
        user = create(:user)
        base = user.username
        user.update!(username: "#{base}_new")
        issuable.project.add_developer(user)

        cmd = "/assign @#{base}\\_new"

        _, updates, _ = service.execute(cmd, issuable)

        expect(updates).to eq(assignee_ids: [user.id])
      end

      it 'assigns to a single user' do
        _, updates, _ = service.execute(content, issuable)

        expect(updates).to eq(assignee_ids: [developer.id])
      end

      it 'returns the assign message' do
        _, _, message = service.execute(content, issuable)
        translated_string = _("Assigned %{developer_to_reference}.")
        formatted_message = format(translated_string, developer_to_reference: developer.to_reference.to_s)

        expect(message).to eq(formatted_message)
      end

      context 'when the reference does not match the exact case' do
        let(:user) { create(:user) }
        let(:content) { "/assign #{user.to_reference.upcase}" }

        it 'assigns to the user' do
          issuable.project.add_developer(user)

          _, updates, message = service.execute(content, issuable)
          translated_string = _("Assigned %{user_to_reference}.")
          formatted_message = format(translated_string, user_to_reference: user.to_reference.to_s)

          expect(content).not_to include(user.to_reference)
          expect(updates).to eq(assignee_ids: [user.id])
          expect(message).to eq(formatted_message)
        end
      end

      context 'when the user has a private profile' do
        let(:user) { create(:user, :private_profile) }
        let(:content) { "/assign #{user.to_reference}" }

        it 'assigns to the user' do
          issuable.project.add_developer(user)

          _, updates, message = service.execute(content, issuable)
          translated_string = _("Assigned %{user_to_reference}.")
          formatted_message = format(translated_string, user_to_reference: user.to_reference.to_s)

          expect(updates).to eq(assignee_ids: [user.id])
          expect(message).to eq(formatted_message)
        end
      end
    end

    shared_examples 'assign_reviewer command' do
      it 'assigns a reviewer to a single user' do
        _, updates, message = service.execute(content, issuable)
        translated_string = _("Assigned %{developer_to_reference} as reviewer.")
        formatted_message = format(translated_string, developer_to_reference: developer.to_reference.to_s)

        expect(updates).to eq(reviewer_ids: [developer.id])
        expect(message).to eq(formatted_message)
      end
    end

    shared_examples 'unassign_reviewer command' do
      it 'removes a single reviewer' do
        _, updates, message = service.execute(content, issuable)
        translated_string = _("Removed reviewer %{developer_to_reference}.")
        formatted_message = format(translated_string, developer_to_reference: developer.to_reference.to_s)

        expect(updates).to eq(reviewer_ids: [])
        expect(message).to eq(formatted_message)
      end
    end

    it_behaves_like 'reopen command' do
      let(:content) { '/reopen' }
      let(:issuable) { issue }
    end

    it_behaves_like 'reopen command' do
      let(:content) { '/reopen' }
      let(:issuable) { merge_request }
    end

    it_behaves_like 'close command' do
      let(:content) { '/close' }
      let(:issuable) { issue }
    end

    it_behaves_like 'close command' do
      let(:content) { '/close' }
      let(:issuable) { merge_request }
    end

    context 'merge command' do
      let(:merge_request) { create(:merge_request, source_project: repository_project) }
      let(:service) do
        described_class.new(
          container: project,
          current_user: developer,
          params: { merge_request_diff_head_sha: merge_request.diff_head_sha }
        )
      end

      it_behaves_like 'merge immediately command' do
        let(:content) { '/merge' }
        let(:issuable) { merge_request }
      end

      context 'when the head pipeline of merge request is running' do
        before do
          create(:ci_pipeline, :detached_merge_request_pipeline, merge_request: merge_request)
          merge_request.update_head_pipeline
        end

        it_behaves_like 'merge automatically command' do
          let(:content) { '/merge' }
          let(:issuable) { merge_request }
        end
      end

      context 'can not be merged when logged user does not have permissions' do
        let(:service) { described_class.new(container: project, current_user: create(:user)) }

        it_behaves_like 'failed command', 'Could not apply merge command.' do
          let(:content) { "/merge" }
          let(:issuable) { merge_request }
        end
      end

      context 'can not be merged when sha does not match' do
        let(:service) do
          described_class.new(
            container: project,
            current_user: developer,
            params: { merge_request_diff_head_sha: 'othersha' }
          )
        end

        it_behaves_like 'failed command', 'Branch has been updated since the merge was requested.' do
          let(:content) { "/merge" }
          let(:issuable) { merge_request }
        end
      end

      context 'when sha is missing' do
        let(:project) { repository_project }
        let(:service) { described_class.new(container: project, current_user: developer) }

        it_behaves_like 'failed command', 'The `/merge` quick action requires the SHA of the head of the branch.' do
          let(:content) { "/merge" }
          let(:issuable) { merge_request }
        end
      end

      context 'issue can not be merged' do
        it_behaves_like 'failed command', 'Could not apply merge command.' do
          let(:content) { "/merge" }
          let(:issuable) { issue }
        end
      end

      context 'non persisted merge request  cant be merged' do
        it_behaves_like 'failed command', 'Could not apply merge command.' do
          let(:content) { "/merge" }
          let(:issuable) { build(:merge_request) }
        end
      end

      context 'not persisted merge request can not be merged' do
        it_behaves_like 'failed command', 'Could not apply merge command.' do
          let(:content) { "/merge" }
          let(:issuable) { build(:merge_request, source_project: project) }
        end
      end
    end

    it_behaves_like 'title command' do
      let(:content) { '/title A brand new title' }
      let(:issuable) { issue }
    end

    it_behaves_like 'title command' do
      let(:content) { '/title A brand new title' }
      let(:issuable) { merge_request }
    end

    it_behaves_like 'failed command' do
      let(:content) { '/title' }
      let(:issuable) { issue }
    end

    context 'assign command with one user' do
      it_behaves_like 'assign command' do
        let(:content) { "/assign @#{developer.username}" }
        let(:issuable) { issue }
      end

      it_behaves_like 'assign command' do
        let(:content) { "/assign @#{developer.username}" }
        let(:issuable) { create(:incident, project: project) }
      end

      it_behaves_like 'assign command' do
        let(:content) { "/assign @#{developer.username}" }
        let(:issuable) { merge_request }
      end
    end

    # CE does not have multiple assignees
    context 'assign command with multiple assignees' do
      before do
        project.add_developer(developer2)
      end

      # There's no guarantee that the reference extractor will preserve
      # the order of the mentioned users since this is dependent on the
      # order in which rows are returned. We just ensure that at least
      # one of the mentioned users is assigned.
      shared_examples 'assigns to one of the two users' do
        let(:content) { "/assign @#{developer.username} @#{developer2.username}" }

        it 'assigns to a single user' do
          _, updates, message = service.execute(content, issuable)

          expect(updates[:assignee_ids].count).to eq(1)
          assignee = updates[:assignee_ids].first
          expect([developer.id, developer2.id]).to include(assignee)

          user = assignee == developer.id ? developer : developer2

          expect(message).to match("Assigned #{user.to_reference}.")
        end
      end

      it_behaves_like 'assigns to one of the two users' do
        let(:content) { "/assign @#{developer.username} @#{developer2.username}" }
        let(:issuable) { issue }
      end

      it_behaves_like 'assigns to one of the two users' do
        let(:content) { "/assign @#{developer.username} @#{developer2.username}" }
        let(:issuable) { merge_request }
      end
    end

    context 'assign command with me alias' do
      it_behaves_like 'assign command' do
        let(:content) { '/assign me' }
        let(:issuable) { issue }
      end

      it_behaves_like 'assign command' do
        let(:content) { '/assign me' }
        let(:issuable) { merge_request }
      end
    end

    context 'assign command with me alias and whitespace' do
      it_behaves_like 'assign command' do
        let(:content) { '/assign  me ' }
        let(:issuable) { issue }
      end

      it_behaves_like 'assign command' do
        let(:content) { '/assign  me ' }
        let(:issuable) { merge_request }
      end
    end

    it_behaves_like 'failed command', 'a parse error' do
      let(:content) { '/assign @abcd1234' }
      let(:issuable) { issue }
      let(:match_msg) { eq _("Could not apply assign command. Failed to find users for '@abcd1234'.") }
    end

    it_behaves_like 'failed command', "Failed to assign a user because no user was found." do
      let(:content) { '/assign' }
      let(:issuable) { issue }
    end

    describe 'assign_reviewer command' do
      let(:content) { "/assign_reviewer @#{developer.username}" }
      let(:issuable) { merge_request }

      context 'with one user' do
        it_behaves_like 'assign_reviewer command'
      end

      context 'with an issue instead of a merge request' do
        let(:issuable) { issue }

        it_behaves_like 'failed command', 'Could not apply assign_reviewer command.'
      end

      # CE does not have multiple reviewers
      context 'assign command with multiple assignees' do
        before do
          project.add_developer(developer2)
        end

        # There's no guarantee that the reference extractor will preserve
        # the order of the mentioned users since this is dependent on the
        # order in which rows are returned. We just ensure that at least
        # one of the mentioned users is assigned.
        context 'assigns to one of the two users' do
          let(:content) { "/assign_reviewer @#{developer.username} @#{developer2.username}" }

          it 'assigns to a single reviewer' do
            _, updates, message = service.execute(content, issuable)

            expect(updates[:reviewer_ids].count).to eq(1)
            reviewer = updates[:reviewer_ids].first
            expect([developer.id, developer2.id]).to include(reviewer)

            user = reviewer == developer.id ? developer : developer2

            expect(message).to match("Assigned #{user.to_reference} as reviewer.")
          end
        end
      end

      context 'with "me" alias' do
        let(:content) { '/assign_reviewer me' }

        it_behaves_like 'assign_reviewer command'
      end

      context 'with an alias and whitespace' do
        let(:content) { '/assign_reviewer  me ' }

        it_behaves_like 'assign_reviewer command'
      end

      context 'with @all' do
        let(:content) { "/assign_reviewer @all" }

        it_behaves_like 'failed command', 'a parse error' do
          let(:match_msg) { eq _("Could not apply assign_reviewer command. Failed to find users for '@all'.") }
        end
      end

      context 'with an incorrect user' do
        let(:content) { '/assign_reviewer @abcd1234' }

        it_behaves_like 'failed command', 'a parse error' do
          let(:match_msg) { eq _("Could not apply assign_reviewer command. Failed to find users for '@abcd1234'.") }
        end
      end

      context 'with the "reviewer" alias' do
        let(:content) { "/reviewer @#{developer.username}" }

        it_behaves_like 'assign_reviewer command'
      end

      context 'with no user' do
        let(:content) { '/assign_reviewer' }

        it_behaves_like 'failed command', "Failed to assign a reviewer because no user was specified."
      end

      context 'with extra text' do
        let(:content) { "/assign_reviewer #{developer.to_reference} do it!" }

        it_behaves_like 'failed command', 'a parse error' do
          let(:match_msg) { eq _("Could not apply assign_reviewer command. Failed to find users for 'do' and 'it!'.") }
        end
      end
    end

    describe 'request_review command' do
      let(:content) { "/request_review @#{developer.username}" }
      let(:issuable) { merge_request }

      context 'with one user' do
        it 'assigns a reviewer to a single user' do
          _, updates, message = service.execute(content, issuable)
          translated_string = _("Requested a review from %{developer_to_reference}.")
          formatted_message = format(translated_string, developer_to_reference: developer.to_reference.to_s)

          expect(updates).to eq(reviewer_ids: [developer.id])
          expect(message).to eq(formatted_message)
        end

        it 'explains command' do
          _, explanations = service.explain(content, issuable)

          expect(explanations).to eq(["Requests a review from #{developer.to_reference}."])
        end
      end

      context 'when user is already assigned' do
        let(:merge_request) { create(:merge_request, source_project: project, reviewers: [developer]) }

        it 'requests a review' do
          expect_next_instance_of(::MergeRequests::RequestReviewService) do |service|
            expect(service).to receive(:execute).with(merge_request, developer)
          end

          _, _, message = service.execute(content, issuable)

          translated_string = _("Requested a review from %{developer_to_reference}.")
          formatted_message = format(translated_string, developer_to_reference: developer.to_reference.to_s)

          expect(message).to eq(formatted_message)
        end
      end

      # CE does not have multiple reviewers
      context 'assign command with multiple reviewers' do
        before do
          project.add_developer(developer2)
        end

        # There's no guarantee that the reference extractor will preserve
        # the order of the mentioned users since this is dependent on the
        # order in which rows are returned. We just ensure that at least
        # one of the mentioned users is assigned.
        context 'assigns to one of the two users' do
          let(:content) { "/request_review @#{developer.username} @#{developer2.username}" }

          it 'assigns to a single reviewer' do
            _, updates, message = service.execute(content, issuable)

            expect(updates[:reviewer_ids].count).to eq(1)
            reviewer = updates[:reviewer_ids].first
            expect([developer.id, developer2.id]).to include(reviewer)

            user = reviewer == developer.id ? developer : developer2

            expect(message).to match("Requested a review from #{user.to_reference}.")
          end
        end
      end

      context 'when users are not set' do
        let(:content) { "/request_review , " }

        it 'returns an error message' do
          _, explanations = service.explain(content, issuable)

          expect(explanations).to eq(['Failed to request a review because no user was specified.'])
        end
      end

      context 'with "me" alias' do
        let(:content) { '/request_review me' }

        it 'assigns a reviewer to a single user' do
          _, updates, message = service.execute(content, issuable)
          translated_string = _("Requested a review from %{developer_to_reference}.")
          formatted_message = format(translated_string, developer_to_reference: developer.to_reference.to_s)

          expect(updates).to eq(reviewer_ids: [developer.id])
          expect(message).to eq(formatted_message)
        end
      end

      context 'with no user' do
        let(:content) { '/request_review' }

        it_behaves_like 'failed command', "Failed to request a review because no user was specified."
      end
    end

    describe 'unassign_reviewer command' do
      # CE does not have multiple reviewers, so basically anything
      # after /unassign_reviewer (including whitespace) will remove
      # all the current reviewers.
      let(:issuable) { create(:merge_request, reviewers: [developer]) }
      let(:content) { "/unassign_reviewer @#{developer.username}" }

      context 'with one user' do
        it_behaves_like 'unassign_reviewer command'
      end

      context 'with an issue instead of a merge request' do
        let(:issuable) { issue }

        it_behaves_like 'failed command', 'Could not apply unassign_reviewer command.'
      end

      context 'with a not-yet-persisted merge request and a preceding assign_reviewer command' do
        let(:content) do
          <<-QUICKACTION
/assign_reviewer #{developer.to_reference}
/unassign_reviewer #{developer.to_reference}
          QUICKACTION
        end

        let(:issuable) { build(:merge_request) }

        it 'adds and then removes a single reviewer in a single step' do
          _, updates, message = service.execute(content, issuable)
          translated_string = _("Assigned %{developer_to_reference} as reviewer. Removed reviewer %{developer_to_reference}.")
          formatted_message = format(translated_string, developer_to_reference: developer.to_reference.to_s)

          expect(updates).to eq(reviewer_ids: [])
          expect(message).to eq(formatted_message)
        end
      end

      context 'with anything after the command' do
        let(:content) { '/unassign_reviewer supercalifragilisticexpialidocious' }

        it_behaves_like 'unassign_reviewer command'
      end

      context 'with the "remove_reviewer" alias' do
        let(:content) { "/remove_reviewer @#{developer.username}" }

        it_behaves_like 'unassign_reviewer command'
      end

      context 'with no user' do
        let(:content) { '/unassign_reviewer' }

        it_behaves_like 'unassign_reviewer command'
      end
    end

    context 'unassign command' do
      let(:content) { '/unassign' }

      context 'Issue' do
        it 'populates assignee_ids: [] if content contains /unassign' do
          issue.update!(assignee_ids: [developer.id])
          _, updates, _ = service.execute(content, issue)

          expect(updates).to eq(assignee_ids: [])
        end

        it 'returns the unassign message for all the assignee if content contains /unassign' do
          issue.update!(assignee_ids: [developer.id, developer2.id])
          _, _, message = service.execute(content, issue)
          translated_string = _("Removed assignees %{developer_to_reference} and %{developer2_to_reference}.")
          formatted_message = format(translated_string, developer_to_reference: developer.to_reference.to_s, developer2_to_reference: developer2.to_reference.to_s)

          expect(message).to eq(formatted_message)
        end
      end

      context 'Merge Request' do
        it 'populates assignee_ids: [] if content contains /unassign' do
          merge_request.update!(assignee_ids: [developer.id])
          _, updates, _ = service.execute(content, merge_request)

          expect(updates).to eq(assignee_ids: [])
        end

        it 'returns the unassign message for all the assignee if content contains /unassign' do
          merge_request.update!(assignee_ids: [developer.id, developer2.id])
          _, _, message = service.execute(content, merge_request)
          translated_string = _("Removed assignees %{developer_to_reference} and %{developer2_to_reference}.")
          formatted_message = format(translated_string, developer_to_reference: developer.to_reference.to_s, developer2_to_reference: developer2.to_reference.to_s)

          expect(message).to eq(formatted_message)
        end
      end
    end

    context 'project milestones' do
      before do
        milestone
      end

      it_behaves_like 'milestone command' do
        let(:content) { "/milestone %#{milestone.title}" }
        let(:issuable) { issue }
      end

      it_behaves_like 'milestone command' do
        let(:content) { "/milestone %#{milestone.title}" }
        let(:issuable) { merge_request }
      end
    end

    context 'only group milestones available' do
      let_it_be(:ancestor_group) { create(:group) }
      let_it_be(:group) { create(:group, parent: ancestor_group) }
      let_it_be(:project) { create(:project, :public, namespace: group) }
      let_it_be(:milestone) { create(:milestone, group: ancestor_group, title: '10.0') }

      before_all do
        project.add_developer(developer)
      end

      it_behaves_like 'milestone command' do
        let(:content) { "/milestone %#{milestone.title}" }
        let(:issuable) { issue }
      end

      it_behaves_like 'milestone command' do
        let(:content) { "/milestone %#{milestone.title}" }
        let(:issuable) { merge_request }
      end
    end

    it_behaves_like 'remove_milestone command' do
      let(:content) { '/remove_milestone' }
      let(:issuable) { issue }
    end

    it_behaves_like 'remove_milestone command' do
      let(:content) { '/remove_milestone' }
      let(:issuable) { merge_request }
    end

    it_behaves_like 'label command' do
      let(:content) { %(/label ~"#{inprogress.title}" ~#{bug.title} ~unknown) }
      let(:issuable) { issue }
    end

    it_behaves_like 'label command' do
      let(:content) { %(/label ~"#{inprogress.title}" ~#{bug.title} ~unknown) }
      let(:issuable) { merge_request }
    end

    context 'with a colon label' do
      let(:bug) { create(:label, project: project, title: 'Category:Bug') }
      let(:inprogress) { create(:label, project: project, title: 'status:in:progress') }

      context 'when quoted' do
        let(:content) { %(/label ~"#{inprogress.title}" ~"#{bug.title}" ~unknown) }

        it_behaves_like 'label command' do
          let(:issuable) { merge_request }
        end

        it_behaves_like 'label command' do
          let(:issuable) { issue }
        end
      end

      context 'when unquoted' do
        let(:content) { %(/label ~#{inprogress.title} ~#{bug.title} ~unknown) }

        it_behaves_like 'label command' do
          let(:issuable) { merge_request }
        end

        it_behaves_like 'label command' do
          let(:issuable) { issue }
        end
      end
    end

    context 'with a scoped label' do
      let(:bug) { create(:label, :scoped, project: project) }
      let(:inprogress) { create(:label, project: project, title: 'three::part::label') }

      context 'when quoted' do
        let(:content) { %(/label ~"#{inprogress.title}" ~"#{bug.title}" ~unknown) }

        it_behaves_like 'label command' do
          let(:issuable) { merge_request }
        end

        it_behaves_like 'label command' do
          let(:issuable) { issue }
        end
      end

      context 'when unquoted' do
        let(:content) { %(/label ~#{inprogress.title} ~#{bug.title} ~unknown) }

        it_behaves_like 'label command' do
          let(:issuable) { merge_request }
        end

        it_behaves_like 'label command' do
          let(:issuable) { issue }
        end
      end
    end

    it_behaves_like 'multiple label command' do
      let(:content) { %(/label ~"#{inprogress.title}" \n/label ~#{bug.title}) }
      let(:issuable) { issue }
    end

    it_behaves_like 'multiple label with same argument' do
      let(:content) { %(/label ~"#{inprogress.title}" \n/label ~#{inprogress.title}) }
      let(:issuable) { issue }
    end

    it_behaves_like 'multiword label name starting without ~' do
      let(:content) { %(/label "#{helmchart.title}") }
      let(:issuable) { issue }
    end

    it_behaves_like 'multiword label name starting without ~' do
      let(:content) { %(/label "#{helmchart.title}") }
      let(:issuable) { merge_request }
    end

    it_behaves_like 'label name is included in the middle of another label name' do
      let(:content) { %(/label ~"#{helmchart.title}") }
      let(:issuable) { issue }
    end

    it_behaves_like 'label name is included in the middle of another label name' do
      let(:content) { %(/label ~"#{helmchart.title}") }
      let(:issuable) { merge_request }
    end

    it_behaves_like 'unlabel command' do
      let(:content) { %(/unlabel ~"#{inprogress.title}") }
      let(:issuable) { issue }
    end

    it_behaves_like 'unlabel command' do
      let(:content) { %(/unlabel ~"#{inprogress.title}") }
      let(:issuable) { merge_request }
    end

    it_behaves_like 'multiple unlabel command' do
      let(:content) { %(/unlabel ~"#{inprogress.title}" \n/unlabel ~#{bug.title}) }
      let(:issuable) { issue }
    end

    it_behaves_like 'unlabel command with no argument' do
      let(:content) { %(/unlabel) }
      let(:issuable) { issue }
    end

    it_behaves_like 'unlabel command with no argument' do
      let(:content) { %(/unlabel) }
      let(:issuable) { merge_request }
    end

    it_behaves_like 'relabel command' do
      let(:content) { %(/relabel ~"#{inprogress.title}") }
      let(:issuable) { issue }
    end

    it_behaves_like 'relabel command' do
      let(:content) { %(/relabel ~"#{inprogress.title}") }
      let(:issuable) { merge_request }
    end

    it_behaves_like 'done command' do
      let(:content) { '/done' }
      let(:issuable) { issue }
    end

    it_behaves_like 'done command' do
      let(:content) { '/done' }
      let(:issuable) { merge_request }
    end

    it_behaves_like 'done command' do
      let(:content) { '/done' }
      let(:issuable) { work_item }
    end

    it_behaves_like 'subscribe command' do
      let(:content) { '/subscribe' }
      let(:issuable) { issue }
    end

    it_behaves_like 'subscribe command' do
      let(:content) { '/subscribe' }
      let(:issuable) { merge_request }
    end

    it_behaves_like 'subscribe command' do
      let(:content) { '/subscribe' }
      let(:issuable) { work_item }
    end

    it_behaves_like 'unsubscribe command' do
      let(:content) { '/unsubscribe' }
      let(:issuable) { issue }
    end

    it_behaves_like 'unsubscribe command' do
      let(:content) { '/unsubscribe' }
      let(:issuable) { merge_request }
    end

    it_behaves_like 'unsubscribe command' do
      let(:content) { '/unsubscribe' }
      let(:issuable) { work_item }
    end

    it_behaves_like 'failed command', 'Could not apply due command.' do
      let(:content) { '/due 2016-08-28' }
      let(:issuable) { merge_request }
    end

    it_behaves_like 'remove_due_date command' do
      let(:content) { '/remove_due_date' }
      let(:issuable) { issue }
    end

    it_behaves_like 'draft command' do
      let(:content) { '/draft' }
      let(:issuable) { merge_request }
    end

    it_behaves_like 'draft/ready command no action' do
      let(:content) { '/draft' }
      let(:issuable) { merge_request }

      before do
        issuable.update!(title: issuable.draft_title)
      end
    end

    it_behaves_like 'draft/ready command no action' do
      let(:content) { '/ready' }
      let(:issuable) { merge_request }
    end

    it_behaves_like 'ready command' do
      let(:content) { '/ready' }
      let(:issuable) { merge_request }
    end

    it_behaves_like 'failed command', 'Could not apply remove_due_date command.' do
      let(:content) { '/remove_due_date' }
      let(:issuable) { merge_request }
    end

    it_behaves_like 'estimate command' do
      let(:content) { '/estimate 1h' }
      let(:issuable) { issue }
    end

    it_behaves_like 'estimate command' do
      let(:content) { '/estimate_time 1h' }
      let(:issuable) { issue }
    end

    it_behaves_like 'failed command' do
      let(:content) { '/estimate' }
      let(:issuable) { issue }
    end

    context 'when provided an invalid estimate' do
      let(:content) { '/estimate abc' }
      let(:issuable) { issue }

      it 'populates {} if content contains an unsupported command' do
        _, updates, _ = service.execute(content, issuable)

        expect(updates[:time_estimate]).to be_nil
      end

      it "returns empty message" do
        _, _, message = service.execute(content, issuable)

        expect(message).to be_empty
      end
    end

    it_behaves_like 'spend command' do
      let(:content) { '/spend 1h' }
      let(:issuable) { issue }
    end

    it_behaves_like 'spend command' do
      let(:content) { '/spent 1h' }
      let(:issuable) { issue }
    end

    it_behaves_like 'spend command' do
      let(:content) { '/spend_time 1h' }
      let(:issuable) { issue }
    end

    it_behaves_like 'spend command with negative time' do
      let(:content) { '/spend -120m' }
      let(:issuable) { issue }
    end

    it_behaves_like 'spend command with negative time' do
      let(:content) { '/spent -120m' }
      let(:issuable) { issue }
    end

    it_behaves_like 'spend command with valid date' do
      let(:date) { '2016-02-02' }
      let(:content) { "/spend 30m #{date}" }
      let(:issuable) { issue }
    end

    it_behaves_like 'spend command with valid date' do
      let(:date) { '2016-02-02' }
      let(:content) { "/spent 30m #{date}" }
      let(:issuable) { issue }
    end

    it_behaves_like 'spend command with invalid date' do
      let(:content) { '/spend 30m 17-99-99' }
      let(:issuable) { issue }
    end

    it_behaves_like 'spend command with invalid date' do
      let(:content) { '/spent 30m 17-99-99' }
      let(:issuable) { issue }
    end

    it_behaves_like 'spend command with future date' do
      let(:content) { '/spend 30m 6017-10-10' }
      let(:issuable) { issue }
    end

    it_behaves_like 'spend command with future date' do
      let(:content) { '/spent 30m 6017-10-10' }
      let(:issuable) { issue }
    end

    it_behaves_like 'spend command with category' do
      let(:content) { '/spent 30m [timecategory:pm]' }
      let(:issuable) { issue }
    end

    it_behaves_like 'failed command' do
      let(:content) { '/spend' }
      let(:issuable) { issue }
    end

    it_behaves_like 'failed command' do
      let(:content) { '/spent' }
      let(:issuable) { issue }
    end

    it_behaves_like 'failed command' do
      let(:content) { '/spend abc' }
      let(:issuable) { issue }
    end

    it_behaves_like 'failed command' do
      let(:content) { '/spent abc' }
      let(:issuable) { issue }
    end

    it_behaves_like 'remove_estimate command' do
      let(:content) { '/remove_estimate' }
      let(:issuable) { issue }
    end

    it_behaves_like 'remove_estimate command' do
      let(:content) { '/remove_time_estimate' }
      let(:issuable) { issue }
    end

    it_behaves_like 'remove_time_spent command' do
      let(:content) { '/remove_time_spent' }
      let(:issuable) { issue }
    end

    context '/confidential' do
      it_behaves_like 'confidential command' do
        let(:content) { '/confidential' }
        let(:issuable) { issue }
      end

      it_behaves_like 'confidential command' do
        let_it_be(:work_item) { create(:work_item, :task, project: project) }
        let(:content) { '/confidential' }
        let(:issuable) { work_item }
      end

      it_behaves_like 'confidential command' do
        let(:content) { '/confidential' }
        let(:issuable) { create(:incident, project: project) }
      end

      context 'when non-member is creating a new issue' do
        let(:service) { described_class.new(container: project, current_user: create(:user)) }

        it_behaves_like 'confidential command' do
          let(:content) { '/confidential' }
          let(:issuable) { build(:issue, project: project) }
        end
      end
    end

    it_behaves_like 'lock command' do
      let(:content) { '/lock' }
      let(:issuable) { issue }
    end

    it_behaves_like 'lock command' do
      let(:content) { '/lock' }
      let(:issuable) { merge_request }
    end

    it_behaves_like 'unlock command' do
      let(:content) { '/unlock' }
      let(:issuable) { issue }
    end

    it_behaves_like 'unlock command' do
      let(:content) { '/unlock' }
      let(:issuable) { merge_request }
    end

    context '/todo' do
      let(:content) { '/todo' }

      context 'if issuable is an Issue' do
        it_behaves_like 'todo command' do
          let(:issuable) { issue }
        end
      end

      context 'if issuable is a work item' do
        it_behaves_like 'todo command' do
          let(:issuable) { work_item }
        end
      end

      context 'if issuable is a MergeRequest' do
        it_behaves_like 'todo command' do
          let(:issuable) { merge_request }
        end
      end

      context 'if issuable is a Commit' do
        it_behaves_like 'failed command', 'Could not apply todo command.' do
          let(:issuable) { commit }
        end
      end
    end

    context '/due command' do
      it 'returns invalid date format message when the due date is invalid' do
        issue = build(:issue, project: project)

        _, _, message = service.execute('/due invalid date', issue)

        expect(message).to eq(_('Failed to set due date because the date format is invalid.'))
      end

      it_behaves_like 'due command' do
        let(:content) { '/due 2016-08-28' }
        let(:issuable) { issue }
      end

      it_behaves_like 'due command' do
        let(:content) { '/due tomorrow' }
        let(:issuable) { issue }
        let(:expected_date) { Date.tomorrow }
      end

      it_behaves_like 'due command' do
        let(:content) { '/due 5 days from now' }
        let(:issuable) { issue }
        let(:expected_date) { 5.days.from_now.to_date }
      end

      it_behaves_like 'due command' do
        let(:content) { '/due in 2 days' }
        let(:issuable) { issue }
        let(:expected_date) { 2.days.from_now.to_date }
      end
    end

    context '/copy_metadata command' do
      let(:todo_label) { create(:label, project: project, title: 'To Do') }
      let(:inreview_label) { create(:label, project: project, title: 'In Review') }

      it 'is available when the user is a developer' do
        expect(service.available_commands(issue)).to include(a_hash_including(name: :copy_metadata))
      end

      context 'when the user does not have permission' do
        let(:guest) { create(:user) }
        let(:service) { described_class.new(container: project, current_user: guest) }

        it 'is not available' do
          expect(service.available_commands(issue)).not_to include(a_hash_including(name: :copy_metadata))
        end
      end

      it_behaves_like 'failed command' do
        let(:content) { '/copy_metadata' }
        let(:issuable) { issue }
      end

      it_behaves_like 'copy_metadata command' do
        let(:source_issuable) { create(:labeled_issue, project: project, labels: [inreview_label, todo_label]) }

        let(:content) { "/copy_metadata #{source_issuable.to_reference}" }
        let(:issuable) { build(:issue, project: project) }
      end

      it_behaves_like 'copy_metadata command' do
        let(:source_issuable) { create(:labeled_issue, project: project, labels: [inreview_label, todo_label]) }

        let(:content) { "/copy_metadata #{source_issuable.to_reference}" }
        let(:issuable) { issue }
      end

      context "when a work item type issue is passed" do
        let(:content) { "/copy_metadata #{source_issuable.to_reference(project)}" }
        let(:issuable) { create(:work_item, project: project) }

        it_behaves_like 'copy_metadata command' do
          let(:source_issuable) do
            create(:work_item, project: project, milestone: milestone).tap do |wi|
              wi.labels << [todo_label, inreview_label]
            end
          end
        end

        it_behaves_like 'failed command' do
          let(:other_project) { build(:project, :public) }
          let(:source_issuable) do
            create(:work_item, project: other_project).tap do |wi|
              wi.labels << [todo_label, inreview_label]
            end
          end
        end
      end

      context 'when the parent issuable has a milestone' do
        it_behaves_like 'copy_metadata command' do
          let(:source_issuable) { create(:labeled_issue, project: project, labels: [todo_label, inreview_label], milestone: milestone) }

          let(:content) { "/copy_metadata #{source_issuable.to_reference(project)}" }
          let(:issuable) { issue }
        end
      end

      context 'when more than one issuable is passed' do
        it_behaves_like 'copy_metadata command' do
          let(:source_issuable) { create(:labeled_issue, project: project, labels: [inreview_label, todo_label]) }
          let(:other_label) { create(:label, project: project, title: 'Other') }
          let(:other_source_issuable) { create(:labeled_issue, project: project, labels: [other_label]) }

          let(:content) { "/copy_metadata #{source_issuable.to_reference} #{other_source_issuable.to_reference}" }
          let(:issuable) { issue }
        end
      end

      context 'cross project references' do
        it_behaves_like 'failed command' do
          let(:other_project) { create(:project, :public) }
          let(:source_issuable) { create(:labeled_issue, project: other_project, labels: [todo_label, inreview_label]) }
          let(:content) { "/copy_metadata #{source_issuable.to_reference(project)}" }
          let(:issuable) { issue }
        end

        it_behaves_like 'failed command' do
          let(:content) { "/copy_metadata imaginary##{non_existing_record_iid}" }
          let(:issuable) { issue }
        end

        it_behaves_like 'failed command' do
          let(:other_project) { create(:project, :private) }
          let(:source_issuable) { create(:issue, project: other_project) }

          let(:content) { "/copy_metadata #{source_issuable.to_reference(project)}" }
          let(:issuable) { issue }
        end
      end
    end

    context '/duplicate command' do
      let_it_be(:other_public_project) { create(:project, :public) }
      let_it_be(:other_private_project) { create(:project, :private) }

      context 'when duplicating an issue' do
        let(:duplicate_item) { create(:issue, project: project) }

        context 'with reference' do
          it_behaves_like 'duplicate command' do
            let(:content) { "/duplicate #{duplicate_item.to_reference}" }
            let(:issuable) { issue }
          end
        end

        context 'with url' do
          it_behaves_like 'duplicate command' do
            let(:content) { "/duplicate #{Gitlab::UrlBuilder.build(duplicate_item)}" }
            let(:issuable) { issue }
          end
        end
      end

      context 'when duplicating a work item' do
        let(:duplicate_item) { create(:work_item, project: project) }

        context 'with reference' do
          it_behaves_like 'duplicate command' do
            let(:content) { "/duplicate #{duplicate_item.to_reference}" }
            let(:issuable) { issue }
          end
        end

        context 'with url' do
          it_behaves_like 'duplicate command' do
            let(:content) { "/duplicate #{Gitlab::UrlBuilder.build(duplicate_item)}" }
            let(:issuable) { issue }
          end
        end
      end

      it_behaves_like 'failed command' do
        let(:content) { '/duplicate' }
        let(:issuable) { issue }
      end

      context 'cross project references' do
        it_behaves_like 'duplicate command' do
          let(:duplicate_item) { create(:issue, project: other_public_project) }
          let(:content) { "/duplicate #{duplicate_item.to_reference(project)}" }
          let(:issuable) { issue }
        end

        context 'when executing command' do
          context 'when item not found' do
            let(:output_msg) do
              _('Failed to mark this Issue as a duplicate because referenced item was not found.')
            end

            context 'when referencing an non-existent item' do
              let(:content) { "/duplicate imaginary##{non_existing_record_iid}" }
              let(:issuable) { issue }

              it_behaves_like 'failed command'
            end

            context 'when referencing an inaccessible item' do
              let(:duplicate_item) { create(:issue, project: other_private_project) }
              let(:content) { "/duplicate #{duplicate_item.to_reference(project)}" }
              let(:issuable) { issue }

              it_behaves_like 'failed command'
            end
          end

          context 'when trying to mark item duplicate of itself' do
            let(:output_msg) { _('Failed to mark the Issue as duplicate of itself.') }
            let(:issuable) { issue }
            let(:content) { "/duplicate #{issuable.to_reference(project)}" }

            it_behaves_like 'failed command'
          end

          context 'with insufficient permissions' do
            let(:output_msg) { _('Failed to mark this Issue as duplicate due to insufficient permissions.') }
            let(:duplicate_item) { create(:issue, project: project) }
            let(:issuable) { issue }
            let(:content) { "/duplicate #{duplicate_item.to_reference(project)}" }

            before do
              allow(service).to receive(:can_mark_as_duplicate?).and_return(false)
            end

            it_behaves_like 'failed command'
          end
        end

        context 'when explaining the command' do
          let(:output_msg) { _('Cannot mark this Issue as a duplicate because referenced item was not found.') }

          context 'when referencing an non-existent item' do
            let(:content) { "/duplicate imaginary##{non_existing_record_iid}" }
            let(:issuable) { issue }

            it_behaves_like 'explain message'
          end

          context 'when referencing an inaccessible item' do
            let(:duplicate_item) { create(:issue, project: other_private_project) }
            let(:content) { "/duplicate #{duplicate_item.to_reference(project)}" }
            let(:issuable) { issue }

            it_behaves_like 'explain message'
          end

          context 'when trying to mark item duplicate of itself' do
            let(:output_msg) { _('Cannot mark the Issue as duplicate of itself.') }
            let(:issuable) { issue }
            let(:content) { "/duplicate #{issuable.to_reference(project)}" }

            it_behaves_like 'explain message'
          end

          context 'with insufficient permissions' do
            let(:output_msg) { _('Cannot mark this Issue as duplicate due to insufficient permissions.') }
            let(:duplicate_item) { create(:issue, project: project) }
            let(:issuable) { issue }
            let(:content) { "/duplicate #{duplicate_item.to_reference(project)}" }

            before do
              allow(service).to receive(:can_mark_as_duplicate?).and_return(false)
            end

            it_behaves_like 'explain message'
          end
        end
      end
    end

    context 'when current_user cannot :admin_issue' do
      let(:visitor) { create(:user) }
      let(:issue) { create(:issue, project: project, author: visitor) }
      let(:service) { described_class.new(container: project, current_user: visitor) }

      it_behaves_like 'failed command', 'Could not apply assign command.' do
        let(:content) { "/assign @#{developer.username}" }
        let(:issuable) { issue }
      end

      it_behaves_like 'failed command', 'Could not apply unassign command.' do
        let(:content) { '/unassign' }
        let(:issuable) { issue }
      end

      it_behaves_like 'failed command', 'Could not apply milestone command.' do
        let(:content) { "/milestone %#{milestone.title}" }
        let(:issuable) { issue }
      end

      it_behaves_like 'failed command', 'Could not apply remove_milestone command.' do
        let(:content) { '/remove_milestone' }
        let(:issuable) { issue }
      end

      it_behaves_like 'failed command', 'Could not apply label command.' do
        let(:content) { %(/label ~"#{inprogress.title}" ~#{bug.title} ~unknown) }
        let(:issuable) { issue }
      end

      it_behaves_like 'failed command', 'Could not apply unlabel command.' do
        let(:content) { %(/unlabel ~"#{inprogress.title}") }
        let(:issuable) { issue }
      end

      it_behaves_like 'failed command', 'Could not apply relabel command.' do
        let(:content) { %(/relabel ~"#{inprogress.title}") }
        let(:issuable) { issue }
      end

      it_behaves_like 'failed command', 'Could not apply due command.' do
        let(:content) { '/due tomorrow' }
        let(:issuable) { issue }
      end

      it_behaves_like 'failed command', 'Could not apply remove_due_date command.' do
        let(:content) { '/remove_due_date' }
        let(:issuable) { issue }
      end

      it_behaves_like 'failed command', 'Could not apply confidential command.' do
        let(:content) { '/confidential' }
        let(:issuable) { issue }
      end

      it_behaves_like 'failed command', 'Could not apply lock command.' do
        let(:content) { '/lock' }
        let(:issuable) { issue }
      end

      it_behaves_like 'failed command', 'Could not apply unlock command.' do
        let(:content) { '/unlock' }
        let(:issuable) { issue }
      end
    end

    %w[/react /award].each do |command|
      context "#{command} command" do
        it_behaves_like 'react command', command do
          let(:content) { "#{command} :100:" }
          let(:issuable) { issue }
        end

        it_behaves_like 'react command', command do
          let(:content) { "#{command} :100:" }
          let(:issuable) { merge_request }
        end

        it_behaves_like 'react command', command do
          let(:content) { "#{command} :100:" }
          let(:issuable) { work_item }
        end

        context 'ignores command with no argument' do
          it_behaves_like 'failed command' do
            let(:content) { command }
            let(:issuable) { issue }
          end

          it_behaves_like 'failed command' do
            let(:content) { command }
            let(:issuable) { work_item }
          end
        end

        context 'ignores non-existing / invalid  emojis' do
          it_behaves_like 'failed command' do
            let(:content) { "#{command} noop" }
            let(:issuable) { issue }
          end

          it_behaves_like 'failed command' do
            let(:content) { "#{command} :lorem_ipsum:" }
            let(:issuable) { issue }
          end

          it_behaves_like 'failed command' do
            let(:content) { "#{command} :lorem_ipsum:" }
            let(:issuable) { work_item }
          end
        end

        context 'if issuable is a Commit' do
          let(:content) { "#{command} :100:" }
          let(:issuable) { commit }

          it_behaves_like 'failed command', "Could not apply react command."
        end
      end
    end

    context '/shrug command' do
      it_behaves_like 'shrug command' do
        let(:content) { '/shrug people are people' }
        let(:issuable) { issue }
      end

      it_behaves_like 'shrug command' do
        let(:content) { '/shrug' }
        let(:issuable) { issue }
      end
    end

    context '/tableflip command' do
      it_behaves_like 'tableflip command' do
        let(:content) { '/tableflip curse your sudden but enviable betrayal' }
        let(:issuable) { issue }
      end

      it_behaves_like 'tableflip command' do
        let(:content) { '/tableflip' }
        let(:issuable) { issue }
      end
    end

    context '/target_branch command' do
      let(:non_empty_project) { create(:project, :repository) }
      let(:another_merge_request) { create(:merge_request, author: developer, source_project: non_empty_project) }
      let(:service) { described_class.new(container: non_empty_project, current_user: developer) }

      it 'updates target_branch if /target_branch command is executed' do
        _, updates, _ = service.execute('/target_branch merge-test', merge_request)

        expect(updates).to eq(target_branch: 'merge-test')
      end

      it 'handles blanks around param' do
        _, updates, _ = service.execute('/target_branch  merge-test     ', merge_request)

        expect(updates).to eq(target_branch: 'merge-test')
      end

      context 'ignores command with no argument' do
        it_behaves_like 'failed command', 'Could not apply target_branch command.' do
          let(:content) { '/target_branch' }
          let(:issuable) { another_merge_request }
        end
      end

      context 'ignores non-existing target branch' do
        it_behaves_like 'failed command', 'Could not apply target_branch command.' do
          let(:content) { '/target_branch totally_non_existing_branch' }
          let(:issuable) { another_merge_request }
        end
      end

      it 'returns the target_branch message' do
        _, _, message = service.execute('/target_branch merge-test', merge_request)

        expect(message).to eq(_('Set target branch to merge-test.'))
      end
    end

    # rubocop:disable RSpec/MultipleMemoizedHelpers -- we need a few extra helpers for these examples
    context '/board_move command' do
      let_it_be(:todo) { create(:label, project: project, title: 'To Do') }
      let_it_be(:inreview) { create(:label, project: project, title: 'In Review') }
      let(:content) { %(/board_move ~"#{inreview.title}") }

      let_it_be(:board) { create(:board, project: project) }
      let_it_be(:todo_list) { create(:list, board: board, label: todo) }
      let_it_be(:inreview_list) { create(:list, board: board, label: inreview) }
      let_it_be(:inprogress_list) { create(:list, board: board, label: inprogress) }

      it 'populates remove_label_ids for all current board columns' do
        issue.update!(label_ids: [todo.id, inprogress.id])

        _, updates, _ = service.execute(content, issue)

        expect(updates[:remove_label_ids]).to match_array([todo.id, inprogress.id])
      end

      it 'populates add_label_ids with the id of the given label' do
        _, updates, _ = service.execute(content, issue)

        expect(updates[:add_label_ids]).to eq([inreview.id])
      end

      it 'does not include the given label id in remove_label_ids' do
        issue.update!(label_ids: [todo.id, inreview.id])

        _, updates, _ = service.execute(content, issue)

        expect(updates[:remove_label_ids]).to match_array([todo.id])
      end

      it 'does not remove label ids that are not lists on the board' do
        issue.update!(label_ids: [todo.id, bug.id])

        _, updates, _ = service.execute(content, issue)

        expect(updates[:remove_label_ids]).to match_array([todo.id])
      end

      it 'returns board_move message' do
        issue.update!(label_ids: [todo.id, inprogress.id])

        _, _, message = service.execute(content, issue)
        translated_string = _("Moved issue to ~%{inreview_id} column in the board.")
        formatted_message = format(translated_string, inreview_id: inreview.id.to_s)

        expect(message).to eq(formatted_message)
      end

      context 'if the project has multiple boards' do
        let(:issuable) { issue }

        before do
          create(:board, project: project)
        end

        it_behaves_like 'failed command', 'Could not apply board_move command.'
      end

      context 'if the given label does not exist' do
        let(:issuable) { issue }
        let(:content) { '/board_move ~"Fake Label"' }

        it_behaves_like 'failed command', 'Failed to move this issue because label was not found.'
      end

      context 'if multiple labels are given' do
        let(:issuable) { issue }
        let(:content) { %(/board_move ~"#{inreview.title}" ~"#{todo.title}") }

        it_behaves_like 'failed command', 'Failed to move this issue because only a single label can be provided.'
      end

      context 'if the given label is not a list on the board' do
        let(:issuable) { issue }
        let(:content) { %(/board_move ~"#{bug.title}") }

        it_behaves_like 'failed command', 'Failed to move this issue because label was not found.'
      end

      context 'if issuable is not an Issue' do
        let(:issuable) { merge_request }

        it_behaves_like 'failed command', 'Could not apply board_move command.'
      end
    end
    # rubocop:enable RSpec/MultipleMemoizedHelpers

    context '/tag command' do
      let(:issuable) { commit }

      context 'ignores command with no argument' do
        it_behaves_like 'failed command' do
          let(:content) { '/tag' }
        end
      end

      context 'tags a commit with a tag name' do
        it_behaves_like 'tag command' do
          let(:tag_name) { 'v1.2.3' }
          let(:tag_message) { nil }
          let(:content) { "/tag #{tag_name}" }
        end
      end

      context 'tags a commit with a tag name and message' do
        it_behaves_like 'tag command' do
          let(:tag_name) { 'v1.2.3' }
          let(:tag_message) { 'Stable release' }
          let(:content) { "/tag #{tag_name} #{tag_message}" }
        end
      end
    end

    it 'limits to commands passed' do
      content = "/shrug test\n/close"

      text, commands = service.execute(content, issue, only: [:shrug])

      expect(commands).to be_empty
      expect(text).to eq("#{described_class::SHRUG}\n/close")
    end

    it 'preserves leading whitespace' do
      content = " - list\n\n/close\n\ntest\n\n"

      text, _ = service.execute(content, issue)

      expect(text).to eq(" - list\n\ntest")
    end

    it 'tracks MAU for commands' do
      content = "/shrug test\n/assign me\n/milestone %4"

      expect(Gitlab::UsageDataCounters::QuickActionActivityUniqueCounter)
        .to receive(:track_unique_action)
        .with('shrug', args: 'test', user: developer, project: project)

      expect(Gitlab::UsageDataCounters::QuickActionActivityUniqueCounter)
        .to receive(:track_unique_action)
        .with('assign', args: 'me', user: developer, project: project)

      expect(Gitlab::UsageDataCounters::QuickActionActivityUniqueCounter)
        .to receive(:track_unique_action)
        .with('milestone', args: '%4', user: developer, project: project)

      service.execute(content, issue)
    end

    context '/create_merge_request command' do
      let(:branch_name) { '1-feature' }
      let(:content) { "/create_merge_request #{branch_name}" }
      let(:issuable) { issue }

      context 'if issuable is not an Issue' do
        let(:issuable) { merge_request }

        it_behaves_like 'failed command', 'Could not apply create_merge_request command.'
      end

      context "when logged user cannot create_merge_requests in the project" do
        let(:project) { create(:project, :archived) }

        before do
          project.add_developer(developer)
        end

        it_behaves_like 'failed command', 'Could not apply create_merge_request command.'
      end

      context 'when logged user cannot push code to the project' do
        let(:project) { create(:project, :private) }
        let(:service) { described_class.new(container: project, current_user: create(:user)) }

        it_behaves_like 'failed command', 'Could not apply create_merge_request command.'
      end

      it 'populates create_merge_request with branch_name and issue iid' do
        _, updates, _ = service.execute(content, issuable)

        expect(updates).to eq(create_merge_request: { branch_name: branch_name, issue_iid: issuable.iid })
      end

      it 'returns the create_merge_request message' do
        _, _, message = service.execute(content, issuable)
        translated_string = _("Created branch '%{branch_name}' and a merge request to resolve this issue.")
        formatted_message = format(translated_string, branch_name: branch_name.to_s)

        expect(message).to eq(formatted_message)
      end
    end

    context 'submit_review command' do
      using RSpec::Parameterized::TableSyntax

      where(:note) do
        [
          'I like it',
          '/submit_review'
        ]
      end

      with_them do
        let(:content) { '/submit_review' }
        let!(:draft_note) { create(:draft_note, note: note, merge_request: merge_request, author: developer) }

        it 'submits the users current review' do
          _, _, message = service.execute(content, merge_request)

          expect { draft_note.reload }.to raise_error(ActiveRecord::RecordNotFound)
          expect(message).to eq(_('Submitted the current review.'))
        end
      end

      context 'when parameters are passed' do
        context 'with approve parameter' do
          it 'calls MergeRequests::ApprovalService service' do
            expect_next_instance_of(
              MergeRequests::ApprovalService, project: merge_request.project, current_user: current_user
            ) do |service|
              expect(service).to receive(:execute).with(merge_request).and_return(true)
            end

            _, _, message = service.execute('/submit_review approve', merge_request)

            expect(message).to eq(_('Submitted the current review. Approved the current merge request.'))
          end

          it 'adds error message when approval service fails' do
            expect_next_instance_of(
              MergeRequests::ApprovalService, project: merge_request.project, current_user: current_user
            ) do |service|
              expect(service).to receive(:execute).with(merge_request).and_return(false)
            end

            _, _, message = service.execute('/submit_review approve', merge_request)

            expect(message).to eq(_('Submitted the current review. Failed to approve the current merge request.'))
          end
        end

        context 'with review state parameter' do
          it 'calls MergeRequests::UpdateReviewerStateService service' do
            expect_next_instance_of(
              MergeRequests::UpdateReviewerStateService, project: merge_request.project, current_user: current_user
            ) do |service|
              expect(service).to receive(:execute).with(merge_request, 'requested_changes')
            end

            _, _, message = service.execute('/submit_review requested_changes', merge_request)

            expect(message).to eq(_('Submitted the current review.'))
          end
        end
      end
    end

    context 'request_changes command' do
      let(:merge_request) { create(:merge_request, source_project: project) }
      let(:content) { '/request_changes' }

      context "when the user is a reviewer" do
        before do
          create(:merge_request_reviewer, merge_request: merge_request, reviewer: current_user)
        end

        it 'calls MergeRequests::UpdateReviewerStateService with requested_changes' do
          expect_next_instance_of(
            MergeRequests::UpdateReviewerStateService,
            project: project, current_user: current_user
          ) do |service|
            expect(service).to receive(:execute).with(merge_request, "requested_changes").and_return({ status: :success })
          end

          _, _, message = service.execute(content, merge_request)

          expect(message).to eq(_('Changes requested to the current merge request.'))
        end

        it 'returns error message from MergeRequests::UpdateReviewerStateService' do
          expect_next_instance_of(
            MergeRequests::UpdateReviewerStateService,
            project: project, current_user: current_user
          ) do |service|
            expect(service).to receive(:execute).with(merge_request, "requested_changes").and_return({ status: :error, message: 'Error' })
          end

          _, _, message = service.execute(content, merge_request)

          expect(message).to eq(_('Error'))
        end
      end

      context "when the user is not a reviewer" do
        it 'does not call MergeRequests::UpdateReviewerStateService' do
          expect(MergeRequests::UpdateReviewerStateService).not_to receive(:new)

          service.execute(content, merge_request)
        end
      end

      it_behaves_like 'approve command unavailable' do
        let(:issuable) { issue }
      end
    end

    it_behaves_like 'issues link quick action', :relate do
      let(:user) { developer }
    end

    context 'unlink command' do
      let_it_be(:private_issue) { create(:issue, project: create(:project, :private)) }
      let_it_be(:other_issue) { create(:issue, project: project) }
      let(:content) { "/unlink #{other_issue.to_reference(issue)}" }

      subject(:unlink_issues) { service.execute(content, issue) }

      shared_examples 'command with failure' do
        it 'does not destroy issues relation' do
          expect { unlink_issues }.not_to change { IssueLink.count }
        end

        it 'return correct execution message' do
          expect(unlink_issues[2]).to eq('No linked issue matches the provided parameter.')
        end
      end

      context 'when command includes linked issue' do
        let_it_be(:link1) { create(:issue_link, source: issue, target: other_issue) }
        let_it_be(:link2) { create(:issue_link, source: issue, target: private_issue) }

        it 'executes command successfully' do
          expect { unlink_issues }.to change { IssueLink.count }.by(-1)
          expect(unlink_issues[2]).to eq("Removed linked item #{other_issue.to_reference(issue)}.")
          expect(issue.notes.last.note).to eq("removed the relation with #{other_issue.to_reference}")
          expect(other_issue.notes.last.note).to eq("removed the relation with #{issue.to_reference}")
        end

        context 'when user has no access' do
          let(:content) { "/unlink #{private_issue.to_reference(issue)}" }

          it_behaves_like 'command with failure'
        end
      end

      context 'when provided issue is not linked' do
        it_behaves_like 'command with failure'
      end
    end

    shared_examples 'only available when issue_or_work_item_feature_flag_enabled' do |command|
      context 'when issue' do
        it 'is available' do
          _, explanations = service.explain(command, issue)

          expect(explanations).not_to be_empty
        end
      end

      context 'when project work item' do
        let_it_be(:work_item) { create(:work_item, project: project) }

        it 'is available' do
          _, explanations = service.explain(command, work_item)

          expect(explanations).not_to be_empty
        end

        context 'when feature flag disabled' do
          before do
            stub_feature_flags(work_items_alpha: false)
          end

          it 'is not available' do
            _, explanations = service.explain(command, work_item)

            expect(explanations).to be_empty
          end
        end
      end

      context 'when group work item' do
        let_it_be(:work_item) { create(:work_item, :group_level) }

        it 'is not available' do
          _, explanations = service.explain(command, work_item)

          expect(explanations).to be_empty
        end
      end
    end

    describe 'add_email command' do
      let_it_be(:issuable) { issue }

      it_behaves_like 'failed command', "No email participants were added. Either none were provided, or they already exist." do
        let(:content) { '/add_email' }
      end

      context 'with existing email participant' do
        let(:content) { '/add_email a@gitlab.com' }

        before do
          issuable.issue_email_participants.create!(email: "a@gitlab.com")
        end

        it_behaves_like 'failed command', "No email participants were added. Either none were provided, or they already exist."
      end

      context 'with new email participants' do
        let(:content) { '/add_email a@gitlab.com b@gitlab.com' }

        subject(:add_emails) { service.execute(content, issuable) }

        it 'returns message' do
          _, _, message = add_emails

          expect(message).to eq(_('Added a@gitlab.com and b@gitlab.com.'))
        end

        it 'adds 2 participants' do
          expect { add_emails }.to change { issue.issue_email_participants.count }.by(2)
        end

        context 'with mixed case email' do
          let(:content) { '/add_email FirstLast@GitLab.com' }

          it 'returns correctly cased message' do
            _, _, message = add_emails

            expect(message).to eq(_('Added FirstLast@GitLab.com.'))
          end
        end

        context 'with invalid email' do
          let(:content) { '/add_email a@gitlab.com bad_email' }

          it 'only adds valid emails' do
            expect { add_emails }.to change { issue.issue_email_participants.count }.by(1)
          end
        end

        context 'with existing email' do
          let(:content) { '/add_email a@gitlab.com existing@gitlab.com' }

          it 'only adds new emails' do
            issue.issue_email_participants.create!(email: 'existing@gitlab.com')

            expect { add_emails }.to change { issue.issue_email_participants.count }.by(1)
          end

          it 'only adds new (case insensitive) emails' do
            issue.issue_email_participants.create!(email: 'EXISTING@gitlab.com')

            expect { add_emails }.to change { issue.issue_email_participants.count }.by(1)
          end
        end

        context 'with duplicate email' do
          let(:content) { '/add_email a@gitlab.com a@gitlab.com' }

          it 'only adds unique new emails' do
            expect { add_emails }.to change { issue.issue_email_participants.count }.by(1)
          end
        end

        context 'with more than 6 emails' do
          let(:content) { '/add_email a@gitlab.com b@gitlab.com c@gitlab.com d@gitlab.com e@gitlab.com f@gitlab.com g@gitlab.com' }

          it 'only adds 6 new emails' do
            expect { add_emails }.to change { issue.issue_email_participants.count }.by(6)
          end
        end

        context 'when participants limit on issue is reached' do
          before do
            issue.issue_email_participants.create!(email: 'user@example.com')
            stub_const("IssueEmailParticipants::CreateService::MAX_NUMBER_OF_RECORDS", 1)
          end

          let(:content) { '/add_email a@gitlab.com' }

          it_behaves_like 'failed command',
            "No email participants were added. Either none were provided, or they already exist."
        end

        context 'when only some emails can be added because of participants limit' do
          before do
            stub_const("IssueEmailParticipants::CreateService::MAX_NUMBER_OF_RECORDS", 1)
          end

          let(:content) { '/add_email a@gitlab.com b@gitlab.com' }

          it 'only adds one new email' do
            expect { add_emails }.to change { issue.issue_email_participants.count }.by(1)
          end
        end

        context 'with feature flag disabled' do
          before do
            stub_feature_flags(issue_email_participants: false)
          end

          it 'does not add any participants' do
            expect { add_emails }.not_to change { issue.issue_email_participants.count }
          end
        end
      end

      it 'is part of the available commands' do
        expect(service.available_commands(issuable)).to include(a_hash_including(name: :add_email))
      end

      context 'with non-persisted issue' do
        let(:issuable) { build(:issue) }

        it 'is not part of the available commands' do
          expect(service.available_commands(issuable)).not_to include(a_hash_including(name: :add_email))
        end
      end

      it_behaves_like 'only available when issue_or_work_item_feature_flag_enabled', '/add_email'
    end

    describe 'remove_email command' do
      let_it_be_with_reload(:issuable) { issue }

      it 'is not part of the available commands' do
        expect(service.available_commands(issuable)).not_to include(a_hash_including(name: :remove_email))
      end

      context 'with existing email participant' do
        let(:content) { '/remove_email user@example.com' }

        subject(:remove_email) { service.execute(content, issuable) }

        before do
          issuable.issue_email_participants.create!(email: "user@example.com")
        end

        it 'returns message' do
          _, _, message = service.execute(content, issuable)

          expect(message).to eq(_('Removed user@example.com.'))
        end

        it 'removes 1 participant' do
          expect { remove_email }.to change { issue.issue_email_participants.count }.by(-1)
        end

        context 'with mixed case email' do
          let(:content) { '/remove_email FirstLast@GitLab.com' }

          before do
            issuable.issue_email_participants.create!(email: "FirstLast@GitLab.com")
          end

          it 'returns correctly cased message' do
            _, _, message = service.execute(content, issuable)

            expect(message).to eq(_('Removed FirstLast@GitLab.com.'))
          end

          it 'removes 1 participant' do
            expect { remove_email }.to change { issue.issue_email_participants.count }.by(-1)
          end
        end

        context 'with invalid email' do
          let(:content) { '/remove_email user@example.com bad_email' }

          it 'only removes valid emails' do
            expect { remove_email }.to change { issue.issue_email_participants.count }.by(-1)
          end
        end

        context 'with non-existing email address' do
          let(:content) { '/remove_email NonExistent@gitlab.com' }

          it 'returns message' do
            _, _, message = service.execute(content, issuable)

            expect(message).to eq(_("No email participants were removed. Either none were provided, or they don't exist."))
          end
        end

        context 'with more than the max number of emails' do
          let(:content) { '/remove_email user@example.com user1@example.com' }

          before do
            stub_const("IssueEmailParticipants::DestroyService::MAX_NUMBER_OF_EMAILS", 1)
            # user@example.com has already been added above
            issuable.issue_email_participants.create!(email: "user1@example.com")
          end

          it 'only removes the max allowed number of emails' do
            expect { remove_email }.to change { issue.issue_email_participants.count }.by(-1)
          end
        end
      end

      context 'with non-persisted issue' do
        let(:issuable) { build(:issue) }

        it 'is not part of the available commands' do
          expect(service.available_commands(issuable)).not_to include(a_hash_including(name: :remove_email))
        end
      end

      context 'with feature flag disabled' do
        before do
          stub_feature_flags(issue_email_participants: false)
        end

        it 'is not part of the available commands' do
          expect(service.available_commands(issuable)).not_to include(a_hash_including(name: :remove_email))
        end
      end
    end

    describe 'convert_to_ticket command' do
      shared_examples 'a failed command execution' do
        it 'fails with message' do
          _, _, message = convert_to_ticket

          expect(message).to eq(expected_message)
          expect(issuable).to have_attributes(
            confidential: false,
            author_id: original_author.id,
            service_desk_reply_to: nil
          )
        end
      end

      shared_examples 'a successful command execution' do
        it 'converts issue to Service Desk issue' do
          _, _, message = convert_to_ticket

          expect(message).to eq(s_('ServiceDesk|Converted issue to Service Desk ticket.'))
          expect(issuable).to have_attributes(
            confidential: expected_confidentiality,
            author_id: Users::Internal.support_bot_id,
            service_desk_reply_to: 'user@example.com'
          )
        end
      end

      let_it_be_with_reload(:issuable) { issue }
      let_it_be(:original_author) { issue.author }

      let(:content) { '/convert_to_ticket' }
      let(:expected_message) do
        s_("ServiceDesk|Cannot convert issue to ticket because no email was provided or the format was invalid.")
      end

      subject(:convert_to_ticket) { service.execute(content, issuable) }

      it 'is part of the available commands' do
        expect(service.available_commands(issuable)).to include(a_hash_including(name: :convert_to_ticket))
      end

      it_behaves_like 'a failed command execution'

      context 'when parameter is not an email' do
        let(:content) { '/convert_to_ticket no-email-at-all' }

        it_behaves_like 'a failed command execution'
      end

      context 'when parameter is an email' do
        let(:content) { '/convert_to_ticket user@example.com' }
        let(:expected_confidentiality) { true }

        it_behaves_like 'a successful command execution'

        context 'when tickets should not be confidential by default' do
          let_it_be(:service_desk_settings) do
            create(:service_desk_setting, project: project, tickets_confidential_by_default: false)
          end

          context 'when issuable is in a public project' do
            it_behaves_like 'a successful command execution'

            context 'when issuable is already confidential' do
              before do
                issuable.update!(confidential: true)
              end

              it_behaves_like 'a successful command execution'
            end
          end

          context 'when issuable is in a private project' do
            let(:expected_confidentiality) { false }

            before do
              project.update!(visibility_level: Gitlab::VisibilityLevel::PRIVATE)
            end

            it_behaves_like 'a successful command execution'
          end

          context 'when issuable is already confidential' do
            let(:expected_confidentiality) { true }

            before do
              issuable.update!(confidential: true)
            end

            it_behaves_like 'a successful command execution'
          end
        end
      end

      context 'when issue is Service Desk issue' do
        before do
          issue.update!(
            author: support_bot,
            service_desk_reply_to: 'user@example.com'
          )
        end

        it 'is not part of the available commands', quarantine: 'https://gitlab.com/gitlab-org/gitlab/-/issues/512578' do
          expect(service.available_commands(issuable)).not_to include(a_hash_including(name: :convert_to_ticket))
        end
      end

      context 'with non-persisted issue' do
        let(:issuable) { build(:issue) }

        it 'is not part of the available commands' do
          expect(service.available_commands(issuable)).not_to include(a_hash_including(name: :convert_to_ticket))
        end
      end
    end

    context 'severity command' do
      let_it_be_with_reload(:issuable) { create(:incident, project: project) }

      subject(:set_severity) { service.execute(content, issuable) }

      it_behaves_like 'failed command', 'No severity matches the provided parameter' do
        let(:content) { '/severity something' }
      end

      shared_examples 'updates the severity' do |new_severity|
        it do
          expect { set_severity }.to change { issuable.severity }.from('unknown').to(new_severity)
        end
      end

      context 'when quick action is used on creation' do
        let(:content) { '/severity s3' }
        let(:issuable) { build(:incident, project: project) }

        it_behaves_like 'updates the severity', 'medium'

        context 'issuable does not support severity' do
          let(:issuable) { build(:issue, project: project) }

          it_behaves_like 'failed command', ''
        end
      end

      context 'severity given with S format' do
        let(:content) { '/severity s3' }

        it_behaves_like 'updates the severity', 'medium'
      end

      context 'severity given with number format' do
        let(:content) { '/severity 3' }

        it_behaves_like 'updates the severity', 'medium'
      end

      context 'severity given with text format' do
        let(:content) { '/severity medium' }

        it_behaves_like 'updates the severity', 'medium'
      end

      context 'an issuable that does not support severity' do
        let_it_be_with_reload(:issuable) { create(:issue, project: project) }

        it_behaves_like 'failed command', 'Could not apply severity command.' do
          let(:content) { '/severity s3' }
        end
      end
    end

    context 'approve command' do
      let(:merge_request) { create(:merge_request, source_project: project) }
      let(:content) { '/approve' }

      it 'approves the current merge request' do
        service.execute(content, merge_request)

        expect(merge_request.approved_by_users).to eq([developer])
      end

      context "when the user can't approve" do
        before do
          project.team.truncate
          project.add_guest(developer)
        end

        it 'does not approve the MR' do
          service.execute(content, merge_request)

          expect(merge_request.approved_by_users).to be_empty
        end
      end

      context 'when MR is already merged' do
        before do
          merge_request.mark_as_merged!
        end

        it_behaves_like 'approve command unavailable' do
          let(:issuable) { merge_request }
        end
      end

      it_behaves_like 'approve command unavailable' do
        let(:issuable) { issue }
      end
    end

    context 'unapprove command' do
      let!(:merge_request) { create(:merge_request, source_project: project) }
      let(:content) { '/unapprove' }

      before do
        service.execute('/approve', merge_request)
      end

      it 'unapproves the current merge request' do
        service.execute(content, merge_request)

        expect(merge_request.approved_by_users).to be_empty
      end

      it 'calls MergeRequests::UpdateReviewerStateService' do
        expect_next_instance_of(
          MergeRequests::UpdateReviewerStateService,
          project: project, current_user: current_user
        ) do |service|
          expect(service).to receive(:execute).with(merge_request, 'unapproved')
        end

        service.execute(content, merge_request)
      end

      context "when the user can't unapprove" do
        before do
          project.team.truncate
          project.add_guest(developer)
        end

        it 'does not unapprove the MR' do
          service.execute(content, merge_request)

          expect(merge_request.approved_by_users).to eq([developer])
        end
      end

      context 'when MR is already merged' do
        before do
          merge_request.mark_as_merged!
        end

        it_behaves_like 'unapprove command unavailable' do
          let(:issuable) { merge_request }
        end
      end

      it_behaves_like 'unapprove command unavailable' do
        let(:issuable) { issue }
      end
    end

    context 'crm_contact commands' do
      let_it_be(:new_contact) { create(:contact, group: group) }
      let_it_be(:another_contact) { create(:contact, group: group) }
      let_it_be(:existing_contact) { create(:contact, group: group) }

      let(:add_command) { service.execute("/add_contacts #{new_contact.email}", issue) }
      let(:remove_command) { service.execute("/remove_contacts #{existing_contact.email}", issue) }

      before do
        issue.project.group.add_developer(developer)
        create(:issue_customer_relations_contact, issue: issue, contact: existing_contact)
      end

      describe 'add_contacts command' do
        it 'adds a contact' do
          _, updates, message = add_command

          expect(updates).to eq(add_contacts: [new_contact.email])
          expect(message).to eq(_('One or more contacts were successfully added.'))
        end

        context 'with multiple contacts in the same command' do
          it 'adds both contacts' do
            _, updates, message = service.execute("/add_contacts #{new_contact.email} #{another_contact.email}", issue)

            expect(updates).to eq(add_contacts: [new_contact.email, another_contact.email])
            expect(message).to eq(_('One or more contacts were successfully added.'))
          end
        end

        context 'with multiple commands' do
          it 'adds both contacts' do
            _, updates, message = service.execute("/add_contacts #{new_contact.email}\n/add_contacts #{another_contact.email}", issue)

            expect(updates).to eq(add_contacts: [new_contact.email, another_contact.email])
            expect(message).to eq(_('One or more contacts were successfully added. One or more contacts were successfully added.'))
          end
        end
      end

      describe 'remove_contacts command' do
        before do
          create(:issue_customer_relations_contact, issue: issue, contact: another_contact)
        end

        it 'removes the contact' do
          _, updates, message = remove_command

          expect(updates).to eq(remove_contacts: [existing_contact.email])
          expect(message).to eq(_('One or more contacts were successfully removed.'))
        end

        context 'with multiple contacts in the same command' do
          it 'removes the contact' do
            _, updates, message = service.execute("/remove_contacts #{existing_contact.email} #{another_contact.email}", issue)

            expect(updates).to eq(remove_contacts: [existing_contact.email, another_contact.email])
            expect(message).to eq(_('One or more contacts were successfully removed.'))
          end
        end

        context 'with multiple commands' do
          it 'removes the contact' do
            _, updates, message = service.execute("/remove_contacts #{existing_contact.email}\n/remove_contacts #{another_contact.email}", issue)

            expect(updates).to eq(remove_contacts: [existing_contact.email, another_contact.email])
            expect(message).to eq(_('One or more contacts were successfully removed. One or more contacts were successfully removed.'))
          end
        end
      end
    end

    context 'when using an alias' do
      it 'returns the correct execution message' do
        content = "/labels ~#{bug.title}"

        _, _, message = service.execute(content, issue)

        expect(message).to eq(_("Added ~\"Bug\" label."))
      end
    end

    it_behaves_like 'quick actions that change work item type'

    context '/set_parent command' do
      let_it_be(:parent) { create(:work_item, :issue, project: project) }
      let_it_be(:work_item) { create(:work_item, :task, project: project) }
      let_it_be(:parent_ref) { parent.to_reference(project) }

      let(:content) { "/set_parent #{parent_ref}" }

      it 'returns success message' do
        _, _, message = service.execute(content, work_item)

        expect(message).to eq(_('Parent set successfully'))
      end

      it 'sets correct update params' do
        _, updates, _ = service.execute(content, work_item)

        expect(updates).to eq(set_parent: parent)
      end
    end

    context '/remove_parent command' do
      let_it_be_with_reload(:work_item) { create(:work_item, :task, project: project) }

      let(:content) { "/remove_parent" }

      context 'when a parent is not present' do
        it 'is empty' do
          _, explanations = service.explain(content, work_item)

          expect(explanations).to eq([])
        end
      end

      context 'when a parent is present' do
        let_it_be(:parent) { create(:work_item, :issue, project: project) }

        before do
          create(:parent_link, work_item_parent: parent, work_item: work_item)
        end

        it 'returns correct explanation' do
          _, explanations = service.explain(content, work_item)
          translated_string = _("Remove %{parent_to_reference} as this item's parent.")
          formatted_message = format(translated_string, parent_to_reference: parent.to_reference(work_item).to_s)

          expect(explanations)
            .to contain_exactly(formatted_message)
        end

        it 'returns success message' do
          _, updates, message = service.execute(content, work_item)

          expect(updates).to eq(remove_parent: true)
          expect(message).to eq(_('Parent removed successfully'))
        end
      end
    end
  end

  describe '#explain' do
    let(:service) { described_class.new(container: project, current_user: developer) }
    let(:merge_request) { create(:merge_request, source_project: project) }

    describe 'close command' do
      let(:content) { '/close' }

      it 'includes issuable name' do
        content_result, explanations = service.explain(content, issue)

        expect(content_result).to eq('')
        expect(explanations).to eq([_('Closes this issue.')])
      end
    end

    describe 'reopen command' do
      let(:content) { '/reopen' }
      let(:merge_request) { create(:merge_request, :closed, source_project: project) }

      it 'includes issuable name' do
        _, explanations = service.explain(content, merge_request)

        expect(explanations).to eq([_('Reopens this merge request.')])
      end
    end

    describe 'title command' do
      let(:content) { '/title This is new title' }

      it 'includes new title' do
        _, explanations = service.explain(content, issue)

        expect(explanations).to eq([_('Changes the title to "This is new title".')])
      end
    end

    describe 'assign command' do
      shared_examples 'assigns developer' do
        it 'tells us we will assign the developer' do
          _, explanations = service.explain(content, merge_request)
          translated_string = _("Assigns @%{developer_username}.")
          formatted_message = format(translated_string, developer_username: developer.username.to_s)

          expect(explanations).to eq([formatted_message])
        end
      end

      context 'when using a reference' do
        let(:content) { "/assign @#{developer.username}" }

        include_examples 'assigns developer'
      end

      context 'when using a bare username' do
        let(:content) { "/assign #{developer.username}" }

        include_examples 'assigns developer'
      end

      context 'when using me' do
        let(:content) { "/assign me" }

        include_examples 'assigns developer'
      end

      context 'when there are unparseable arguments' do
        let(:arg) { "#{developer.username} to this issue" }
        let(:content) { "/assign #{arg}" }

        it 'tells us why we cannot do that' do
          _, explanations = service.explain(content, merge_request)

          expect(explanations)
            .to contain_exactly _("Problem with assign command: Failed to find users for 'to', 'this', and 'issue'.")
        end
      end
    end

    describe 'unassign command' do
      let(:content) { '/unassign' }
      let(:issue) { create(:issue, project: project, assignees: [developer]) }

      it 'includes current assignee reference' do
        _, explanations = service.explain(content, issue)
        translated_string = _("Removes assignee @%{developer_username}.")
        formatted_message = format(translated_string, developer_username: developer.username.to_s)

        expect(explanations).to eq([formatted_message])
      end
    end

    describe 'unassign_reviewer command' do
      let(:content) { '/unassign_reviewer' }
      let(:merge_request) { create(:merge_request, source_project: project, reviewers: [developer]) }

      it 'includes current assignee reference' do
        _, explanations = service.explain(content, merge_request)
        translated_string = _("Removes reviewer @%{developer_username}.")
        formatted_message = format(translated_string, developer_username: developer.username.to_s)

        expect(explanations).to eq([formatted_message])
      end
    end

    describe 'assign_reviewer command' do
      let(:content) { "/assign_reviewer #{developer.to_reference}" }
      let(:merge_request) { create(:merge_request, source_project: project, assignees: [developer]) }

      it 'includes only the user reference' do
        _, explanations = service.explain(content, merge_request)
        translated_string = _("Assigns %{developer_to_reference} as reviewer.")
        formatted_message = format(translated_string, developer_to_reference: developer.to_reference.to_s)

        expect(explanations).to eq([formatted_message])
      end

      context 'when users are not set' do
        let(:content) { "/assign_reviewer , " }

        it 'returns an error message' do
          _, explanations = service.explain(content, merge_request)

          expect(explanations).to eq(['Failed to assign a reviewer because no user was specified.'])
        end
      end
    end

    describe 'milestone command' do
      let(:content) { '/milestone %wrong-milestone' }
      let!(:milestone) { create(:milestone, project: project, title: '9.10') }

      it 'is empty when milestone reference is wrong' do
        _, explanations = service.explain(content, issue)

        expect(explanations).to eq([])
      end
    end

    describe 'remove milestone command' do
      let(:content) { '/remove_milestone' }
      let(:merge_request) { create(:merge_request, source_project: project, milestone: milestone) }

      it 'includes current milestone name' do
        _, explanations = service.explain(content, merge_request)
        milestone_description = _("Removes /%{project_path}%%\"9.10\" milestone.")
        expected_explanation = format(milestone_description, project_path: project.full_path)

        expect(explanations).to eq([expected_explanation])
      end
    end

    describe 'label command' do
      let(:content) { '/label ~missing' }
      let!(:label) { create(:label, project: project) }

      it 'is empty when there are no correct labels' do
        _, explanations = service.explain(content, issue)

        expect(explanations).to eq([])
      end
    end

    describe 'unlabel command' do
      let(:content) { '/unlabel' }

      it 'says all labels if no parameter provided' do
        merge_request.update!(label_ids: [bug.id])
        _, explanations = service.explain(content, merge_request)

        expect(explanations).to eq([_('Removes all labels.')])
      end
    end

    describe 'relabel command' do
      let(:content) { "/relabel #{bug.title}" }
      let(:feature) { create(:label, project: project, title: 'Feature') }

      it 'includes label name' do
        issue.update!(label_ids: [feature.id])
        _, explanations = service.explain(content, issue)
        translated_string = _("Replaces all labels with ~%{bug_id} label.")
        formatted_message = format(translated_string, bug_id: bug.id.to_s)

        expect(explanations).to eq([formatted_message])
      end
    end

    describe 'copy_metadata command' do
      context 'when reference is invalid' do
        let(:content) { '/copy_metadata xxx' }

        it 'returns an error message' do
          _, explanations = service.explain(content, merge_request)

          expect(explanations)
            .to contain_exactly _("Problem with copy_metadata command: Failed to find work item or merge request.")
        end
      end
    end

    describe 'subscribe command' do
      let(:content) { '/subscribe' }

      it 'includes issuable name' do
        _, explanations = service.explain(content, issue)

        expect(explanations).to eq([_('Subscribes to notifications.')])
      end
    end

    describe 'unsubscribe command' do
      let(:content) { '/unsubscribe' }

      it 'includes issuable name' do
        merge_request.subscribe(developer, project)
        _, explanations = service.explain(content, merge_request)

        expect(explanations).to eq([_('Unsubscribes from notifications.')])
      end
    end

    describe 'due command' do
      let(:content) { '/due April 1st 2016' }

      it 'includes the date' do
        _, explanations = service.explain(content, issue)

        expect(explanations).to eq([_('Sets the due date to Apr 1, 2016.')])
      end
    end

    describe 'draft command set' do
      let(:content) { '/draft' }

      it 'includes the new status' do
        _, explanations = service.explain(content, merge_request)

        expect(explanations).to match_array(['Marks this merge request as a draft.'])
      end

      it 'includes the no change message when status unchanged' do
        merge_request.update!(title: merge_request.draft_title)
        _, explanations = service.explain(content, merge_request)

        expect(explanations).to match_array(["No change to this merge request's draft status."])
      end
    end

    describe 'ready command' do
      let(:content) { '/ready' }

      it 'includes the new status' do
        merge_request.update!(title: merge_request.draft_title)
        _, explanations = service.explain(content, merge_request)

        expect(explanations).to match_array(['Marks this merge request as ready.'])
      end

      it 'includes the no change message when status unchanged' do
        _, explanations = service.explain(content, merge_request)

        expect(explanations).to match_array(["No change to this merge request's draft status."])
      end
    end

    describe 'award command' do
      let(:content) { '/award :confetti_ball: ' }

      it 'includes the emoji' do
        _, explanations = service.explain(content, issue)

        expect(explanations).to eq([_('Toggles :confetti_ball: emoji reaction.')])
      end
    end

    describe 'estimate command' do
      context 'positive estimation' do
        let(:content) { '/estimate 79d' }

        it 'includes the formatted duration' do
          _, explanations = service.explain(content, merge_request)

          expect(explanations).to eq([_('Sets time estimate to 3mo 3w 4d.')])
        end
      end

      context 'zero estimation' do
        let(:content) { '/estimate 0' }

        it 'includes the formatted duration' do
          _, explanations = service.explain(content, merge_request)

          expect(explanations).to eq([_('Removes time estimate.')])
        end
      end

      context 'negative estimation' do
        let(:content) { '/estimate -79d' }

        it 'does not explain' do
          _, explanations = service.explain(content, merge_request)

          expect(explanations).to be_empty
        end
      end

      context 'invalid estimation' do
        let(:content) { '/estimate a' }

        it 'does not explain' do
          _, explanations = service.explain(content, merge_request)

          expect(explanations).to be_empty
        end
      end
    end

    describe 'spend command' do
      it 'includes the formatted duration and proper verb when using /spend' do
        _, explanations = service.explain('/spend -120m', issue)

        expect(explanations).to eq([_('Subtracts 2h spent time.')])
      end

      it 'includes the formatted duration and proper verb when using /spent' do
        _, explanations = service.explain('/spent -120m', issue)

        expect(explanations).to eq([_('Subtracts 2h spent time.')])
      end
    end

    describe 'target branch command' do
      let(:content) { '/target_branch my-feature ' }

      it 'includes the branch name' do
        _, explanations = service.explain(content, merge_request)

        expect(explanations).to eq([_('Sets target branch to my-feature.')])
      end
    end

    describe 'board move command' do
      let(:content) { "/board_move ~#{bug.title}" }
      let!(:board) { create(:board, project: project) }

      it 'includes the label name' do
        _, explanations = service.explain(content, issue)
        translated_string = _("Moves issue to ~%{bug_id} column in the board.")
        formatted_message = format(translated_string, bug_id: bug.id.to_s)

        expect(explanations).to eq([formatted_message])
      end
    end

    describe 'move issue to another project command' do
      let(:content) { '/move test/project' }

      it 'includes the project name' do
        _, explanations = service.explain(content, issue)

        expect(explanations).to eq([_("Moves this issue to test/project.")])
      end

      context "when work item type is an issue" do
        let(:move_command) { "/move test/project" }
        let(:work_item) { create(:work_item, :issue, project: project) }

        it "/move is available" do
          _, explanations = service.explain(move_command, work_item)

          expect(explanations).to match_array(["Moves this issue to test/project."])
        end
      end
    end

    describe 'clone issue to another project command' do
      let(:content) { '/clone test/project' }

      it 'includes the project name' do
        _, explanations = service.explain(content, issue)

        expect(explanations).to match_array([_("Clones this issue, without comments, to test/project.")])
      end

      context "when work item type is an issue" do
        let(:work_item) { create(:work_item, :issue, project: project) }

        it "/clone is available" do
          _, explanations = service.explain("/clone test/project", work_item)

          expect(explanations).to match_array(["Clones this issue, without comments, to test/project."])
        end
      end
    end

    describe 'tag a commit' do
      describe 'with a tag name' do
        context 'without a message' do
          let(:content) { '/tag v1.2.3' }

          it 'includes the tag name only' do
            _, explanations = service.explain(content, commit)

            expect(explanations).to eq([_("Tags this commit to v1.2.3.")])
          end
        end

        context 'with an empty message' do
          let(:content) { '/tag v1.2.3 ' }

          it 'includes the tag name only' do
            _, explanations = service.explain(content, commit)

            expect(explanations).to eq([_("Tags this commit to v1.2.3.")])
          end
        end
      end

      describe 'with a tag name and message' do
        let(:content) { '/tag v1.2.3 Stable release' }

        it 'includes the tag name and message' do
          _, explanations = service.explain(content, commit)

          expect(explanations).to eq([_("Tags this commit to v1.2.3 with \"Stable release\".")])
        end
      end
    end

    describe 'create a merge request' do
      context 'with no branch name' do
        let(:content) { '/create_merge_request' }

        it 'uses the default branch name' do
          _, explanations = service.explain(content, issue)

          expect(explanations).to eq([_('Creates a branch and a merge request to resolve this issue.')])
        end

        it 'returns the execution message using the default branch name' do
          _, _, message = service.execute(content, issue)

          expect(message).to eq(_('Created a branch and a merge request to resolve this issue.'))
        end
      end

      context 'with a branch name' do
        let(:content) { '/create_merge_request foo' }

        it 'uses the given branch name' do
          _, explanations = service.explain(content, issue)

          expect(explanations).to eq([_("Creates branch 'foo' and a merge request to resolve this issue.")])
        end

        it 'returns the execution message using the given branch name' do
          _, _, message = service.execute(content, issue)

          expect(message).to eq(_("Created branch 'foo' and a merge request to resolve this issue."))
        end
      end
    end

    describe "#commands_executed_count" do
      it 'counts commands executed' do
        content = "/close and \n/assign me and \n/title new title"

        service.execute(content, issue)

        expect(service.commands_executed_count).to eq(3)
      end
    end

    describe 'crm commands' do
      let(:add_contacts) { '/add_contacts' }
      let(:remove_contacts) { '/remove_contacts' }

      before_all do
        group.add_developer(developer)
      end

      context 'when group has no contacts' do
        it '/add_contacts is not available' do
          _, explanations = service.explain(add_contacts, issue)

          expect(explanations).to be_empty
        end
      end

      context 'when group has contacts' do
        let!(:contact) { create(:contact, group: group) }

        it '/add_contacts is available' do
          _, explanations = service.explain(add_contacts, issue)

          expect(explanations).to contain_exactly(_("Add customer relation contacts."))
        end

        context 'when issue has no contacts' do
          it '/remove_contacts is not available' do
            _, explanations = service.explain(remove_contacts, issue)

            expect(explanations).to be_empty
          end
        end

        context 'when issue has contacts' do
          let!(:issue_contact) { create(:issue_customer_relations_contact, issue: issue, contact: contact) }

          it '/remove_contacts is available' do
            _, explanations = service.explain(remove_contacts, issue)

            expect(explanations).to contain_exactly(_("Remove customer relation contacts."))
          end
        end
      end
    end

    context 'with keep_actions' do
      let(:content) { '/close' }

      it 'keeps quick actions' do
        content_result, explanations = service.explain(content, issue, keep_actions: true)

        expect(content_result).to eq("<p>/close</p>")
        expect(explanations).to eq([_('Closes this issue.')])
      end

      it 'removes the quick action' do
        content_result, explanations = service.explain(content, issue, keep_actions: false)

        expect(content_result).to eq('')
        expect(explanations).to eq([_('Closes this issue.')])
      end
    end

    describe 'type command' do
      let_it_be(:project) { create(:project, :private) }
      let_it_be(:work_item) { create(:work_item, :task, project: project) }

      let(:command) { '/type issue' }

      it 'has command available' do
        _, explanations = service.explain(command, work_item)

        expect(explanations)
          .to contain_exactly(_("Converts item to issue. Widgets not supported in new type are removed."))
      end
    end

    describe 'relate and unlink commands' do
      let_it_be(:other_issue) { create(:issue, project: project).to_reference(issue) }
      let(:relate_content) { "/relate #{other_issue}" }
      let(:unlink_content) { "/unlink #{other_issue}" }

      context 'when user has permissions' do
        it '/relate command is available' do
          _, explanations = service.explain(relate_content, issue)
          translated_string = _("Added %{target} as a linked item related to this %{work_item_type}.")
          formatted_message = format(
            translated_string,
            target: other_issue,
            work_item_type: "issue"
          )

          expect(explanations).to eq([formatted_message])
        end

        it '/unlink command is available' do
          _, explanations = service.explain(unlink_content, issue)
          translated_string = _("Removes linked item %{issue}.")
          formatted_message = format(translated_string, issue: other_issue.to_s)

          expect(explanations).to eq([formatted_message])
        end
      end

      context 'when user has insufficient permissions' do
        before do
          allow(Ability).to receive(:allowed?).and_call_original
          allow(Ability).to receive(:allowed?).with(current_user, :admin_issue_link, issue).and_return(false)
        end

        it '/relate command is not available' do
          _, explanations = service.explain(relate_content, issue)

          expect(explanations).to be_empty
        end

        it '/unlink command is not available' do
          _, explanations = service.explain(unlink_content, issue)

          expect(explanations).to be_empty
        end
      end
    end

    describe 'promote_to command' do
      let(:content) { '/promote_to issue' }

      context 'when work item supports promotion' do
        let_it_be(:task) { build(:work_item, :task, project: project) }

        it 'includes the value' do
          _, explanations = service.explain(content, task)
          expect(explanations).to eq([_('Promotes item to issue.')])
        end
      end

      context 'when work item does not support promotion' do
        let_it_be(:incident) { build(:work_item, :incident, project: project) }

        it 'does not include the value' do
          _, explanations = service.explain(content, incident)
          expect(explanations).to be_empty
        end
      end

      context 'when promotion is not allowed' do
        let_it_be(:public_project) { create(:project, :public) }
        let_it_be(:task) { build(:work_item, :task, project: public_project) }

        it 'returns the forbidden error message' do
          _, _, message = service.execute(content, task)
          expect(message).to eq(_('Failed to promote this work item: You have insufficient permissions.'))
        end
      end
    end

    describe '/set_parent command' do
      let_it_be(:parent) { create(:work_item, :issue, project: project) }
      let_it_be(:work_item) { create(:work_item, :task, project: project) }
      let_it_be(:parent_ref) { parent.to_reference(project) }

      let(:command) { "/set_parent #{parent_ref}" }

      shared_examples 'command is available' do
        it 'explanation contains correct message' do
          _, explanations = service.explain(command, work_item)
          translated_string = _("Change item's parent to %{parent_ref}.")
          formatted_message = format(translated_string, parent_ref: parent_ref.to_s)

          expect(explanations).to contain_exactly(formatted_message)
        end

        it 'contains command' do
          expect(service.available_commands(work_item)).to include(a_hash_including(name: :set_parent))
        end
      end

      shared_examples 'command is not available' do
        it 'explanation is empty' do
          _, explanations = service.explain(command, work_item)

          expect(explanations).to eq([])
        end

        it 'does not contain command' do
          expect(service.available_commands(work_item)).not_to include(a_hash_including(name: :set_parent))
        end
      end

      context 'when user can admin link' do
        it_behaves_like 'command is available'

        context 'when work item type does not support a parent' do
          let_it_be(:work_item) { build(:work_item, :incident, project: project) }

          it_behaves_like 'command is not available'
        end
      end

      context 'when user cannot admin link' do
        subject(:service) { described_class.new(container: project, current_user: create(:user)) }

        it_behaves_like 'command is not available'
      end
    end

    describe '/add_child command' do
      let_it_be(:child) { create(:work_item, :issue, project: project) }
      let_it_be(:work_item) { create(:work_item, :objective, project: project) }
      let_it_be(:child_ref) { child.to_reference(project) }

      let(:command) { "/add_child #{child_ref}" }

      shared_examples 'command is available' do
        it 'explanation contains correct message' do
          _, explanations = service.explain(command, work_item)
          translated_string = _("Add %{child_ref} as a child item.")
          formatted_message = format(translated_string, child_ref: child_ref.to_s)

          expect(explanations)
            .to contain_exactly(formatted_message)
        end

        it 'contains command' do
          expect(service.available_commands(work_item)).to include(a_hash_including(name: :add_child))
        end
      end

      shared_examples 'command is not available' do
        it 'explanation is empty' do
          _, explanations = service.explain(command, work_item)

          expect(explanations).to eq([])
        end

        it 'does not contain command' do
          expect(service.available_commands(work_item)).not_to include(a_hash_including(name: :add_child))
        end
      end

      context 'when user can admin link' do
        it_behaves_like 'command is available'

        context 'when work item type does not support children' do
          let_it_be(:work_item) { build(:work_item, :key_result, project: project) }

          it_behaves_like 'command is not available'
        end
      end

      context 'when user cannot admin link' do
        subject(:service) { described_class.new(container: project, current_user: create(:user)) }

        it_behaves_like 'command is not available'
      end
    end

    describe '/remove child command' do
      let_it_be(:child) { create(:work_item, :objective, project: project) }
      let_it_be(:work_item) { create(:work_item, :objective, project: project) }
      let_it_be(:child_ref) { child.to_reference(project) }

      let(:command) { "/remove_child #{child_ref}" }

      shared_examples 'command is available' do
        before do
          create(:parent_link, work_item_parent: work_item, work_item: child)
        end

        it 'explanation contains correct message' do
          _, explanations = service.explain(command, work_item)
          translated_string = _("Remove %{child_ref} as a child item.")
          formatted_message = format(translated_string, child_ref: child_ref.to_s)

          expect(explanations)
            .to contain_exactly(formatted_message)
        end

        it 'contains command' do
          expect(service.available_commands(work_item)).to include(a_hash_including(name: :remove_child))
        end
      end

      shared_examples 'command is not available' do
        it 'explanation is empty' do
          _, explanations = service.explain(command, work_item)

          expect(explanations).to eq([])
        end

        it 'does not contain command' do
          expect(service.available_commands(work_item)).not_to include(a_hash_including(name: :remove_child))
        end
      end

      context 'when user can admin link' do
        it_behaves_like 'command is available'
      end

      context 'when user cannot admin link' do
        subject(:service) { described_class.new(container: project, current_user: create(:user)) }

        it_behaves_like 'command is not available'
      end

      context 'when work item does not support children' do
        let_it_be(:work_item) { create(:work_item, :key_result, project: project) }

        it_behaves_like 'command is not available'
      end
    end
  end

  describe '#available_commands' do
    context 'when Guest is creating a new issue' do
      let_it_be(:guest) { create(:user) }
      let_it_be(:developer) { create(:user) }

      let(:current_user) { guest }

      let(:issue) { build(:issue, project: public_project) }
      let(:service) { described_class.new(container: project, current_user: guest) }

      before_all do
        public_project.add_guest(guest)
      end

      it 'includes commands to set metadata' do
        # milestone action is only available when project has a milestone
        milestone

        available_commands = service.available_commands(issue)

        expect(available_commands).to include(
          a_hash_including(name: :label),
          a_hash_including(name: :milestone),
          a_hash_including(name: :copy_metadata),
          a_hash_including(name: :assign),
          a_hash_including(name: :due)
        )
      end
    end

    context 'when target is a work item type of issue' do
      let(:target) { create(:work_item, :issue, project: project) }

      context "when work_item supports move and clone commands" do
        it 'does recognize the actions' do
          expect(service.available_commands(target).pluck(:name)).to include(:move, :clone)
        end
      end

      context "when work_item does not support move and clone commands" do
        before do
          allow(target).to receive(:supports_move_and_clone?).and_return(false)
        end

        it 'does not recognize the action' do
          expect(service.available_commands(target).pluck(:name)).not_to include(:move, :clone)
        end
      end
    end
  end
end
