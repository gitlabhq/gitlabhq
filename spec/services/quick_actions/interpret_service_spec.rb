require 'spec_helper'

describe QuickActions::InterpretService do
  let(:project) { create(:project, :public) }
  let(:developer) { create(:user) }
  let(:developer2) { create(:user) }
  let(:issue) { create(:issue, project: project) }
  let(:milestone) { create(:milestone, project: project, title: '9.10') }
  let(:inprogress) { create(:label, project: project, title: 'In Progress') }
  let(:bug) { create(:label, project: project, title: 'Bug') }
  let(:note) { build(:note, commit_id: merge_request.diff_head_sha) }
  let(:service) { described_class.new(project, developer) }

  before do
    project.add_developer(developer)
  end

  describe '#execute' do
    let(:merge_request) { create(:merge_request, source_project: project) }

    shared_examples 'reopen command' do
      it 'returns state_event: "reopen" if content contains /reopen' do
        issuable.close!
        _, updates = service.execute(content, issuable)

        expect(updates).to eq(state_event: 'reopen')
      end
    end

    shared_examples 'close command' do
      it 'returns state_event: "close" if content contains /close' do
        _, updates = service.execute(content, issuable)

        expect(updates).to eq(state_event: 'close')
      end
    end

    shared_examples 'title command' do
      it 'populates title: "A brand new title" if content contains /title A brand new title' do
        _, updates = service.execute(content, issuable)

        expect(updates).to eq(title: 'A brand new title')
      end
    end

    shared_examples 'milestone command' do
      it 'fetches milestone and populates milestone_id if content contains /milestone' do
        milestone # populate the milestone
        _, updates = service.execute(content, issuable)

        expect(updates).to eq(milestone_id: milestone.id)
      end
    end

    shared_examples 'remove_milestone command' do
      it 'populates milestone_id: nil if content contains /remove_milestone' do
        issuable.update!(milestone_id: milestone.id)
        _, updates = service.execute(content, issuable)

        expect(updates).to eq(milestone_id: nil)
      end
    end

    shared_examples 'label command' do
      it 'fetches label ids and populates add_label_ids if content contains /label' do
        bug # populate the label
        inprogress # populate the label
        _, updates = service.execute(content, issuable)

        expect(updates).to eq(add_label_ids: [bug.id, inprogress.id])
      end
    end

    shared_examples 'multiple label command' do
      it 'fetches label ids and populates add_label_ids if content contains multiple /label' do
        bug # populate the label
        inprogress # populate the label
        _, updates = service.execute(content, issuable)

        expect(updates).to eq(add_label_ids: [inprogress.id, bug.id])
      end
    end

    shared_examples 'multiple label with same argument' do
      it 'prevents duplicate label ids and populates add_label_ids if content contains multiple /label' do
        inprogress # populate the label
        _, updates = service.execute(content, issuable)

        expect(updates).to eq(add_label_ids: [inprogress.id])
      end
    end

    shared_examples 'unlabel command' do
      it 'fetches label ids and populates remove_label_ids if content contains /unlabel' do
        issuable.update!(label_ids: [inprogress.id]) # populate the label
        _, updates = service.execute(content, issuable)

        expect(updates).to eq(remove_label_ids: [inprogress.id])
      end
    end

    shared_examples 'multiple unlabel command' do
      it 'fetches label ids and populates remove_label_ids if content contains  mutiple /unlabel' do
        issuable.update!(label_ids: [inprogress.id, bug.id]) # populate the label
        _, updates = service.execute(content, issuable)

        expect(updates).to eq(remove_label_ids: [inprogress.id, bug.id])
      end
    end

    shared_examples 'unlabel command with no argument' do
      it 'populates label_ids: [] if content contains /unlabel with no arguments' do
        issuable.update!(label_ids: [inprogress.id]) # populate the label
        _, updates = service.execute(content, issuable)

        expect(updates).to eq(label_ids: [])
      end
    end

    shared_examples 'relabel command' do
      it 'populates label_ids: [] if content contains /relabel' do
        issuable.update!(label_ids: [bug.id]) # populate the label
        inprogress # populate the label
        _, updates = service.execute(content, issuable)

        expect(updates).to eq(label_ids: [inprogress.id])
      end
    end

    shared_examples 'todo command' do
      it 'populates todo_event: "add" if content contains /todo' do
        _, updates = service.execute(content, issuable)

        expect(updates).to eq(todo_event: 'add')
      end
    end

    shared_examples 'done command' do
      it 'populates todo_event: "done" if content contains /done' do
        TodoService.new.mark_todo(issuable, developer)
        _, updates = service.execute(content, issuable)

        expect(updates).to eq(todo_event: 'done')
      end
    end

    shared_examples 'subscribe command' do
      it 'populates subscription_event: "subscribe" if content contains /subscribe' do
        _, updates = service.execute(content, issuable)

        expect(updates).to eq(subscription_event: 'subscribe')
      end
    end

    shared_examples 'unsubscribe command' do
      it 'populates subscription_event: "unsubscribe" if content contains /unsubscribe' do
        issuable.subscribe(developer, project)
        _, updates = service.execute(content, issuable)

        expect(updates).to eq(subscription_event: 'unsubscribe')
      end
    end

    shared_examples 'due command' do
      it 'populates due_date: Date.new(2016, 8, 28) if content contains /due 2016-08-28' do
        _, updates = service.execute(content, issuable)

        expect(updates).to eq(due_date: defined?(expected_date) ? expected_date : Date.new(2016, 8, 28))
      end
    end

    shared_examples 'remove_due_date command' do
      it 'populates due_date: nil if content contains /remove_due_date' do
        issuable.update!(due_date: Date.today)
        _, updates = service.execute(content, issuable)

        expect(updates).to eq(due_date: nil)
      end
    end

    shared_examples 'wip command' do
      it 'returns wip_event: "wip" if content contains /wip' do
        _, updates = service.execute(content, issuable)

        expect(updates).to eq(wip_event: 'wip')
      end
    end

    shared_examples 'unwip command' do
      it 'returns wip_event: "unwip" if content contains /wip' do
        issuable.update!(title: issuable.wip_title)
        _, updates = service.execute(content, issuable)

        expect(updates).to eq(wip_event: 'unwip')
      end
    end

    shared_examples 'estimate command' do
      it 'populates time_estimate: 3600 if content contains /estimate 1h' do
        _, updates = service.execute(content, issuable)

        expect(updates).to eq(time_estimate: 3600)
      end
    end

    shared_examples 'spend command' do
      it 'populates spend_time: 3600 if content contains /spend 1h' do
        _, updates = service.execute(content, issuable)

        expect(updates).to eq(spend_time: {
                                duration: 3600,
                                user_id: developer.id,
                                spent_at: DateTime.now.to_date
                              })
      end
    end

    shared_examples 'spend command with negative time' do
      it 'populates spend_time: -1800 if content contains /spend -30m' do
        _, updates = service.execute(content, issuable)

        expect(updates).to eq(spend_time: {
                                duration: -1800,
                                user_id: developer.id,
                                spent_at: DateTime.now.to_date
                              })
      end
    end

    shared_examples 'spend command with valid date' do
      it 'populates spend time: 1800 with date in date type format' do
        _, updates = service.execute(content, issuable)

        expect(updates).to eq(spend_time: {
                                duration: 1800,
                                user_id: developer.id,
                                spent_at: Date.parse(date)
                              })
      end
    end

    shared_examples 'spend command with invalid date' do
      it 'will not create any note and timelog' do
        _, updates = service.execute(content, issuable)

        expect(updates).to eq({})
      end
    end

    shared_examples 'spend command with future date' do
      it 'will not create any note and timelog' do
        _, updates = service.execute(content, issuable)

        expect(updates).to eq({})
      end
    end

    shared_examples 'remove_estimate command' do
      it 'populates time_estimate: 0 if content contains /remove_estimate' do
        _, updates = service.execute(content, issuable)

        expect(updates).to eq(time_estimate: 0)
      end
    end

    shared_examples 'remove_time_spent command' do
      it 'populates spend_time: :reset if content contains /remove_time_spent' do
        _, updates = service.execute(content, issuable)

        expect(updates).to eq(spend_time: { duration: :reset, user_id: developer.id })
      end
    end

    shared_examples 'empty command' do
      it 'populates {} if content contains an unsupported command' do
        _, updates = service.execute(content, issuable)

        expect(updates).to be_empty
      end
    end

    shared_examples 'merge command' do
      let(:project) { create(:project, :repository) }

      it 'runs merge command if content contains /merge' do
        _, updates = service.execute(content, issuable)

        expect(updates).to eq(merge: merge_request.diff_head_sha)
      end
    end

    shared_examples 'award command' do
      it 'toggle award 100 emoji if content containts /award :100:' do
        _, updates = service.execute(content, issuable)

        expect(updates).to eq(emoji_award: "100")
      end
    end

    shared_examples 'duplicate command' do
      it 'fetches issue and populates canonical_issue_id if content contains /duplicate issue_reference' do
        issue_duplicate # populate the issue
        _, updates = service.execute(content, issuable)

        expect(updates).to eq(canonical_issue_id: issue_duplicate.id)
      end
    end

    shared_examples 'copy_metadata command' do
      it 'fetches issue or merge request and copies labels and milestone if content contains /copy_metadata reference' do
        source_issuable # populate the issue
        todo_label # populate this label
        inreview_label # populate this label
        _, updates = service.execute(content, issuable)

        expect(updates[:add_label_ids]).to match_array([inreview_label.id, todo_label.id])

        if source_issuable.milestone
          expect(updates[:milestone_id]).to eq(source_issuable.milestone.id)
        else
          expect(updates).not_to have_key(:milestone_id)
        end
      end
    end

    shared_examples 'shrug command' do
      it 'appends ¯\_(ツ)_/¯ to the comment' do
        new_content, _ = service.execute(content, issuable)

        expect(new_content).to end_with(described_class::SHRUG)
      end
    end

    shared_examples 'tableflip command' do
      it 'appends (╯°□°)╯︵ ┻━┻ to the comment' do
        new_content, _ = service.execute(content, issuable)

        expect(new_content).to end_with(described_class::TABLEFLIP)
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
      let(:service) { described_class.new(project, developer, { merge_request_diff_head_sha: merge_request.diff_head_sha }) }

      it_behaves_like 'merge command' do
        let(:content) { '/merge' }
        let(:issuable) { merge_request }
      end

      context 'can not be merged when logged user does not have permissions' do
        let(:service) { described_class.new(project, create(:user)) }

        it_behaves_like 'empty command' do
          let(:content) { "/merge" }
          let(:issuable) { merge_request }
        end
      end

      context 'can not be merged when sha does not match' do
        let(:service) { described_class.new(project, developer, { merge_request_diff_head_sha: 'othersha' }) }

        it_behaves_like 'empty command' do
          let(:content) { "/merge" }
          let(:issuable) { merge_request }
        end
      end

      context 'when sha is missing' do
        let(:project) { create(:project, :repository) }
        let(:service) { described_class.new(project, developer, {}) }

        it 'precheck passes and returns merge command' do
          _, updates = service.execute('/merge', merge_request)

          expect(updates).to eq(merge: nil)
        end
      end

      context 'issue can not be merged' do
        it_behaves_like 'empty command' do
          let(:content) { "/merge" }
          let(:issuable) { issue }
        end
      end

      context 'non persisted merge request  cant be merged' do
        it_behaves_like 'empty command' do
          let(:content) { "/merge" }
          let(:issuable) { build(:merge_request) }
        end
      end

      context 'not persisted merge request can not be merged' do
        it_behaves_like 'empty command' do
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

    it_behaves_like 'empty command' do
      let(:content) { '/title' }
      let(:issuable) { issue }
    end

    context 'assign command' do
      let(:content) { "/assign @#{developer.username}" }

      context 'Issue' do
        it 'fetches assignee and populates assignee_ids if content contains /assign' do
          _, updates = service.execute(content, issue)

          expect(updates[:assignee_ids]).to match_array([developer.id])
        end
      end

      context 'Merge Request' do
        it 'fetches assignee and populates assignee_ids if content contains /assign' do
          _, updates = service.execute(content, merge_request)

          expect(updates).to eq(assignee_ids: [developer.id])
        end
      end
    end

    context 'assign command with multiple assignees' do
      let(:content) { "/assign @#{developer.username} @#{developer2.username}" }

      before do
        project.add_developer(developer2)
      end

      context 'Issue' do
        it 'fetches assignee and populates assignee_ids if content contains /assign' do
          _, updates = service.execute(content, issue)

          expect(updates[:assignee_ids]).to match_array([developer.id])
        end
      end

      context 'Merge Request' do
        it 'fetches assignee and populates assignee_ids if content contains /assign' do
          _, updates = service.execute(content, merge_request)

          expect(updates).to eq(assignee_ids: [developer.id])
        end
      end
    end

    context 'assign command with me alias' do
      let(:content) { "/assign me" }

      context 'Issue' do
        it 'fetches assignee and populates assignee_ids if content contains /assign' do
          _, updates = service.execute(content, issue)

          expect(updates).to eq(assignee_ids: [developer.id])
        end
      end

      context 'Merge Request' do
        it 'fetches assignee and populates assignee_ids if content contains /assign' do
          _, updates = service.execute(content, merge_request)

          expect(updates).to eq(assignee_ids: [developer.id])
        end
      end
    end

    it_behaves_like 'empty command' do
      let(:content) { '/assign @abcd1234' }
      let(:issuable) { issue }
    end

    it_behaves_like 'empty command' do
      let(:content) { '/assign' }
      let(:issuable) { issue }
    end

    context 'unassign command' do
      let(:content) { '/unassign' }

      context 'Issue' do
        it 'populates assignee_ids: [] if content contains /unassign' do
          issue.update(assignee_ids: [developer.id])
          _, updates = service.execute(content, issue)

          expect(updates).to eq(assignee_ids: [])
        end
      end

      context 'Merge Request' do
        it 'populates assignee_ids: [] if content contains /unassign' do
          merge_request.update(assignee_ids: [developer.id])
          _, updates = service.execute(content, merge_request)

          expect(updates).to eq(assignee_ids: [])
        end
      end
    end

    it_behaves_like 'milestone command' do
      let(:content) { "/milestone %#{milestone.title}" }
      let(:issuable) { issue }
    end

    it_behaves_like 'milestone command' do
      let(:content) { "/milestone %#{milestone.title}" }
      let(:issuable) { merge_request }
    end

    context 'only group milestones available' do
      let(:group) { create(:group) }
      let(:project) { create(:project, :public, namespace: group) }
      let(:milestone) { create(:milestone, group: group, title: '10.0') }

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

    it_behaves_like 'multiple label command' do
      let(:content) { %(/label ~"#{inprogress.title}" \n/label ~#{bug.title}) }
      let(:issuable) { issue }
    end

    it_behaves_like 'multiple label with same argument' do
      let(:content) { %(/label ~"#{inprogress.title}" \n/label ~#{inprogress.title}) }
      let(:issuable) { issue }
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

    it_behaves_like 'todo command' do
      let(:content) { '/todo' }
      let(:issuable) { issue }
    end

    it_behaves_like 'todo command' do
      let(:content) { '/todo' }
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

    it_behaves_like 'subscribe command' do
      let(:content) { '/subscribe' }
      let(:issuable) { issue }
    end

    it_behaves_like 'subscribe command' do
      let(:content) { '/subscribe' }
      let(:issuable) { merge_request }
    end

    it_behaves_like 'unsubscribe command' do
      let(:content) { '/unsubscribe' }
      let(:issuable) { issue }
    end

    it_behaves_like 'unsubscribe command' do
      let(:content) { '/unsubscribe' }
      let(:issuable) { merge_request }
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

    it_behaves_like 'empty command' do
      let(:content) { '/due foo bar' }
      let(:issuable) { issue }
    end

    it_behaves_like 'empty command' do
      let(:content) { '/due 2016-08-28' }
      let(:issuable) { merge_request }
    end

    it_behaves_like 'remove_due_date command' do
      let(:content) { '/remove_due_date' }
      let(:issuable) { issue }
    end

    it_behaves_like 'wip command' do
      let(:content) { '/wip' }
      let(:issuable) { merge_request }
    end

    it_behaves_like 'unwip command' do
      let(:content) { '/wip' }
      let(:issuable) { merge_request }
    end

    it_behaves_like 'empty command' do
      let(:content) { '/remove_due_date' }
      let(:issuable) { merge_request }
    end

    it_behaves_like 'estimate command' do
      let(:content) { '/estimate 1h' }
      let(:issuable) { issue }
    end

    it_behaves_like 'empty command' do
      let(:content) { '/estimate' }
      let(:issuable) { issue }
    end

    it_behaves_like 'empty command' do
      let(:content) { '/estimate abc' }
      let(:issuable) { issue }
    end

    it_behaves_like 'spend command' do
      let(:content) { '/spend 1h' }
      let(:issuable) { issue }
    end

    it_behaves_like 'spend command with negative time' do
      let(:content) { '/spend -30m' }
      let(:issuable) { issue }
    end

    it_behaves_like 'spend command with valid date' do
      let(:date) { '2016-02-02' }
      let(:content) { "/spend 30m #{date}" }
      let(:issuable) { issue }
    end

    it_behaves_like 'spend command with invalid date' do
      let(:content) { '/spend 30m 17-99-99' }
      let(:issuable) { issue }
    end

    it_behaves_like 'spend command with future date' do
      let(:content) { '/spend 30m 6017-10-10' }
      let(:issuable) { issue }
    end

    it_behaves_like 'empty command' do
      let(:content) { '/spend' }
      let(:issuable) { issue }
    end

    it_behaves_like 'empty command' do
      let(:content) { '/spend abc' }
      let(:issuable) { issue }
    end

    it_behaves_like 'remove_estimate command' do
      let(:content) { '/remove_estimate' }
      let(:issuable) { issue }
    end

    it_behaves_like 'remove_time_spent command' do
      let(:content) { '/remove_time_spent' }
      let(:issuable) { issue }
    end

    context '/copy_metadata command' do
      let(:todo_label) { create(:label, project: project, title: 'To Do') }
      let(:inreview_label) { create(:label, project: project, title: 'In Review') }

      it_behaves_like 'empty command' do
        let(:content) { '/copy_metadata' }
        let(:issuable) { issue }
      end

      it_behaves_like 'copy_metadata command' do
        let(:source_issuable) { create(:labeled_issue, project: project, labels: [inreview_label, todo_label]) }

        let(:content) { "/copy_metadata #{source_issuable.to_reference}" }
        let(:issuable) { issue }
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
        it_behaves_like 'empty command' do
          let(:other_project) { create(:project, :public) }
          let(:source_issuable) { create(:labeled_issue, project: other_project, labels: [todo_label, inreview_label]) }
          let(:content) { "/copy_metadata #{source_issuable.to_reference(project)}" }
          let(:issuable) { issue }
        end

        it_behaves_like 'empty command' do
          let(:content) { "/copy_metadata imaginary#1234" }
          let(:issuable) { issue }
        end

        it_behaves_like 'empty command' do
          let(:other_project) { create(:project, :private) }
          let(:source_issuable) { create(:issue, project: other_project) }

          let(:content) { "/copy_metadata #{source_issuable.to_reference(project)}" }
          let(:issuable) { issue }
        end
      end
    end

    context '/duplicate command' do
      it_behaves_like 'duplicate command' do
        let(:issue_duplicate) { create(:issue, project: project) }
        let(:content) { "/duplicate #{issue_duplicate.to_reference}" }
        let(:issuable) { issue }
      end

      it_behaves_like 'empty command' do
        let(:content) { '/duplicate' }
        let(:issuable) { issue }
      end

      context 'cross project references' do
        it_behaves_like 'duplicate command' do
          let(:other_project) { create(:project, :public) }
          let(:issue_duplicate) { create(:issue, project: other_project) }
          let(:content) { "/duplicate #{issue_duplicate.to_reference(project)}" }
          let(:issuable) { issue }
        end

        it_behaves_like 'empty command' do
          let(:content) { "/duplicate imaginary#1234" }
          let(:issuable) { issue }
        end

        it_behaves_like 'empty command' do
          let(:other_project) { create(:project, :private) }
          let(:issue_duplicate) { create(:issue, project: other_project) }

          let(:content) { "/duplicate #{issue_duplicate.to_reference(project)}" }
          let(:issuable) { issue }
        end
      end
    end

    context 'when current_user cannot :admin_issue' do
      let(:visitor) { create(:user) }
      let(:issue) { create(:issue, project: project, author: visitor) }
      let(:service) { described_class.new(project, visitor) }

      it_behaves_like 'empty command' do
        let(:content) { "/assign @#{developer.username}" }
        let(:issuable) { issue }
      end

      it_behaves_like 'empty command' do
        let(:content) { '/unassign' }
        let(:issuable) { issue }
      end

      it_behaves_like 'empty command' do
        let(:content) { "/milestone %#{milestone.title}" }
        let(:issuable) { issue }
      end

      it_behaves_like 'empty command' do
        let(:content) { '/remove_milestone' }
        let(:issuable) { issue }
      end

      it_behaves_like 'empty command' do
        let(:content) { %(/label ~"#{inprogress.title}" ~#{bug.title} ~unknown) }
        let(:issuable) { issue }
      end

      it_behaves_like 'empty command' do
        let(:content) { %(/unlabel ~"#{inprogress.title}") }
        let(:issuable) { issue }
      end

      it_behaves_like 'empty command' do
        let(:content) { %(/relabel ~"#{inprogress.title}") }
        let(:issuable) { issue }
      end

      it_behaves_like 'empty command' do
        let(:content) { '/due tomorrow' }
        let(:issuable) { issue }
      end

      it_behaves_like 'empty command' do
        let(:content) { '/remove_due_date' }
        let(:issuable) { issue }
      end

      it_behaves_like 'empty command' do
        let(:content) { '/duplicate #{issue.to_reference}' }
        let(:issuable) { issue }
      end
    end

    context '/award command' do
      it_behaves_like 'award command' do
        let(:content) { '/award :100:' }
        let(:issuable) { issue }
      end

      it_behaves_like 'award command' do
        let(:content) { '/award :100:' }
        let(:issuable) { merge_request }
      end

      context 'ignores command with no argument' do
        it_behaves_like 'empty command' do
          let(:content) { '/award' }
          let(:issuable) { issue }
        end
      end

      context 'ignores non-existing / invalid  emojis' do
        it_behaves_like 'empty command' do
          let(:content) { '/award noop' }
          let(:issuable) { issue }
        end

        it_behaves_like 'empty command' do
          let(:content) { '/award :lorem_ipsum:' }
          let(:issuable) { issue }
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
      let(:service) { described_class.new(non_empty_project, developer)}

      it 'updates target_branch if /target_branch command is executed' do
        _, updates = service.execute('/target_branch merge-test', merge_request)

        expect(updates).to eq(target_branch: 'merge-test')
      end

      it 'handles blanks around param' do
        _, updates = service.execute('/target_branch  merge-test     ', merge_request)

        expect(updates).to eq(target_branch: 'merge-test')
      end

      context 'ignores command with no argument' do
        it_behaves_like 'empty command' do
          let(:content) { '/target_branch' }
          let(:issuable) { another_merge_request }
        end
      end

      context 'ignores non-existing target branch' do
        it_behaves_like 'empty command' do
          let(:content) { '/target_branch totally_non_existing_branch' }
          let(:issuable) { another_merge_request }
        end
      end
    end

    context '/board_move command' do
      let(:todo) { create(:label, project: project, title: 'To Do') }
      let(:inreview) { create(:label, project: project, title: 'In Review') }
      let(:content) { %{/board_move ~"#{inreview.title}"} }

      let!(:board) { create(:board, project: project) }
      let!(:todo_list) { create(:list, board: board, label: todo) }
      let!(:inreview_list) { create(:list, board: board, label: inreview) }
      let!(:inprogress_list) { create(:list, board: board, label: inprogress) }

      it 'populates remove_label_ids for all current board columns' do
        issue.update!(label_ids: [todo.id, inprogress.id])

        _, updates = service.execute(content, issue)

        expect(updates[:remove_label_ids]).to match_array([todo.id, inprogress.id])
      end

      it 'populates add_label_ids with the id of the given label' do
        _, updates = service.execute(content, issue)

        expect(updates[:add_label_ids]).to eq([inreview.id])
      end

      it 'does not include the given label id in remove_label_ids' do
        issue.update!(label_ids: [todo.id, inreview.id])

        _, updates = service.execute(content, issue)

        expect(updates[:remove_label_ids]).to match_array([todo.id])
      end

      it 'does not remove label ids that are not lists on the board' do
        issue.update!(label_ids: [todo.id, bug.id])

        _, updates = service.execute(content, issue)

        expect(updates[:remove_label_ids]).to match_array([todo.id])
      end

      context 'if the project has multiple boards' do
        let(:issuable) { issue }

        before do
          create(:board, project: project)
        end

        it_behaves_like 'empty command'
      end

      context 'if the given label does not exist' do
        let(:issuable) { issue }
        let(:content) { '/board_move ~"Fake Label"' }
        it_behaves_like 'empty command'
      end

      context 'if multiple labels are given' do
        let(:issuable) { issue }
        let(:content) { %{/board_move ~"#{inreview.title}" ~"#{todo.title}"} }
        it_behaves_like 'empty command'
      end

      context 'if the given label is not a list on the board' do
        let(:issuable) { issue }
        let(:content) { %{/board_move ~"#{bug.title}"} }
        it_behaves_like 'empty command'
      end

      context 'if issuable is not an Issue' do
        let(:issuable) { merge_request }
        it_behaves_like 'empty command'
      end
    end
  end

  describe '#explain' do
    let(:service) { described_class.new(project, developer) }
    let(:merge_request) { create(:merge_request, source_project: project) }

    describe 'close command' do
      let(:content) { '/close' }

      it 'includes issuable name' do
        _, explanations = service.explain(content, issue)

        expect(explanations).to eq(['Closes this issue.'])
      end
    end

    describe 'reopen command' do
      let(:content) { '/reopen' }
      let(:merge_request) { create(:merge_request, :closed, source_project: project) }

      it 'includes issuable name' do
        _, explanations = service.explain(content, merge_request)

        expect(explanations).to eq(['Reopens this merge request.'])
      end
    end

    describe 'title command' do
      let(:content) { '/title This is new title' }

      it 'includes new title' do
        _, explanations = service.explain(content, issue)

        expect(explanations).to eq(['Changes the title to "This is new title".'])
      end
    end

    describe 'assign command' do
      let(:content) { "/assign @#{developer.username} do it!" }

      it 'includes only the user reference' do
        _, explanations = service.explain(content, merge_request)

        expect(explanations).to eq(["Assigns @#{developer.username}."])
      end
    end

    describe 'unassign command' do
      let(:content) { '/unassign' }
      let(:issue) { create(:issue, project: project, assignees: [developer]) }

      it 'includes current assignee reference' do
        _, explanations = service.explain(content, issue)

        expect(explanations).to eq(["Removes assignee @#{developer.username}."])
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

        expect(explanations).to eq(['Removes %"9.10" milestone.'])
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

        expect(explanations).to eq(['Removes all labels.'])
      end
    end

    describe 'relabel command' do
      let(:content) { '/relabel Bug' }
      let!(:bug) { create(:label, project: project, title: 'Bug') }
      let(:feature) { create(:label, project: project, title: 'Feature') }

      it 'includes label name' do
        issue.update!(label_ids: [feature.id])
        _, explanations = service.explain(content, issue)

        expect(explanations).to eq(["Replaces all labels with ~#{bug.id} label."])
      end
    end

    describe 'subscribe command' do
      let(:content) { '/subscribe' }

      it 'includes issuable name' do
        _, explanations = service.explain(content, issue)

        expect(explanations).to eq(['Subscribes to this issue.'])
      end
    end

    describe 'unsubscribe command' do
      let(:content) { '/unsubscribe' }

      it 'includes issuable name' do
        merge_request.subscribe(developer, project)
        _, explanations = service.explain(content, merge_request)

        expect(explanations).to eq(['Unsubscribes from this merge request.'])
      end
    end

    describe 'due command' do
      let(:content) { '/due April 1st 2016' }

      it 'includes the date' do
        _, explanations = service.explain(content, issue)

        expect(explanations).to eq(['Sets the due date to Apr 1, 2016.'])
      end
    end

    describe 'wip command' do
      let(:content) { '/wip' }

      it 'includes the new status' do
        _, explanations = service.explain(content, merge_request)

        expect(explanations).to eq(['Marks this merge request as Work In Progress.'])
      end
    end

    describe 'award command' do
      let(:content) { '/award :confetti_ball: ' }

      it 'includes the emoji' do
        _, explanations = service.explain(content, issue)

        expect(explanations).to eq(['Toggles :confetti_ball: emoji award.'])
      end
    end

    describe 'estimate command' do
      let(:content) { '/estimate 79d' }

      it 'includes the formatted duration' do
        _, explanations = service.explain(content, merge_request)

        expect(explanations).to eq(['Sets time estimate to 3mo 3w 4d.'])
      end
    end

    describe 'spend command' do
      let(:content) { '/spend -120m' }

      it 'includes the formatted duration and proper verb' do
        _, explanations = service.explain(content, issue)

        expect(explanations).to eq(['Substracts 2h spent time.'])
      end
    end

    describe 'target branch command' do
      let(:content) { '/target_branch my-feature ' }

      it 'includes the branch name' do
        _, explanations = service.explain(content, merge_request)

        expect(explanations).to eq(['Sets target branch to my-feature.'])
      end
    end

    describe 'board move command' do
      let(:content) { '/board_move ~bug' }
      let!(:bug) { create(:label, project: project, title: 'bug') }
      let!(:board) { create(:board, project: project) }

      it 'includes the label name' do
        _, explanations = service.explain(content, issue)

        expect(explanations).to eq(["Moves issue to ~#{bug.id} column in the board."])
      end
    end

    describe 'move issue to another project command' do
      let(:content) { '/move test/project' }

      it 'includes the project name' do
        _, explanations = service.explain(content, issue)

        expect(explanations).to eq(["Moves this issue to test/project."])
      end
    end
  end
end
