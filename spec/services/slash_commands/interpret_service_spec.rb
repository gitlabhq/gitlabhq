require 'spec_helper'

describe SlashCommands::InterpretService, services: true do
  let(:project) { create(:project) }
  let(:user) { create(:user) }
  let(:issue) { create(:issue, project: project) }
  let(:milestone) { create(:milestone, project: project, title: '9.10') }
  let(:inprogress) { create(:label, project: project, title: 'In Progress') }
  let(:bug) { create(:label, project: project, title: 'Bug') }

  before do
    project.team << [user, :developer]
  end

  describe '#command_names' do
    subject do
      described_class.command_names(
        project: project,
        noteable: issue,
        current_user: user
      )
    end

    it 'returns the basic known commands' do
      is_expected.to match_array([
        :close,
        :title,
        :assign, :reassign,
        :todo,
        :subscribe,
        :due_date, :due
      ])
    end

    context 'when noteable is open' do
      it 'includes the :close command' do
        is_expected.to include(*[:close])
      end
    end

    context 'when noteable is closed' do
      before do
        issue.close!
      end

      it 'includes the :open, :reopen commands' do
        is_expected.to include(*[:open, :reopen])
      end
    end

    context 'when noteable has an assignee' do
      before do
        issue.update(assignee_id: user.id)
      end

      it 'includes the :unassign, :remove_assignee commands' do
        is_expected.to include(*[:unassign, :remove_assignee])
      end
    end

    context 'when noteable has a milestone' do
      before do
        issue.update(milestone: milestone)
      end

      it 'includes the :clear_milestone, :remove_milestone commands' do
        is_expected.to include(*[:milestone, :clear_milestone, :remove_milestone])
      end
    end

    context 'when project has a milestone' do
      before do
        milestone
      end

      it 'includes the :milestone command' do
        is_expected.to include(*[:milestone])
      end
    end

    context 'when noteable has a label' do
      before do
        issue.update(label_ids: [bug.id])
      end

      it 'includes the :unlabel, :remove_labels, :remove_label, :clear_labels, :clear_label commands' do
        is_expected.to include(*[:unlabel, :remove_labels, :remove_label, :clear_labels, :clear_label])
      end
    end

    context 'when project has a label' do
      before do
        inprogress
      end

      it 'includes the :labels, :label commands' do
        is_expected.to include(*[:labels, :label])
      end
    end

    context 'when user has no todo' do
      it 'includes the :todo command' do
        is_expected.to include(*[:todo])
      end
    end

    context 'when user has a todo' do
      before do
        TodoService.new.mark_todo(issue, user)
      end

      it 'includes the :done command' do
        is_expected.to include(*[:done])
      end
    end

    context 'when user is not subscribed' do
      it 'includes the :subscribe command' do
        is_expected.to include(*[:subscribe])
      end
    end

    context 'when user is subscribed' do
      before do
        issue.subscribe(user)
      end

      it 'includes the :unsubscribe command' do
        is_expected.to include(*[:unsubscribe])
      end
    end

    context 'when noteable has a no due date' do
      it 'includes the :due_date, :due commands' do
        is_expected.to include(*[:due_date, :due])
      end
    end

    context 'when noteable has a due date' do
      before do
        issue.update(due_date: Date.today)
      end

      it 'includes the :clear_due_date command' do
        is_expected.to include(*[:due_date, :due, :clear_due_date])
      end
    end
  end

  describe '#execute' do
    let(:service) { described_class.new(project, user) }
    let(:merge_request) { create(:merge_request, source_project: project) }

    shared_examples 'open command' do
      it 'returns state_event: "open" if content contains /open' do
        issuable.close!
        changes = service.execute(content, issuable)

        expect(changes).to eq(state_event: 'reopen')
      end
    end

    shared_examples 'close command' do
      it 'returns state_event: "close" if content contains /open' do
        changes = service.execute(content, issuable)

        expect(changes).to eq(state_event: 'close')
      end
    end

    shared_examples 'title command' do
      it 'populates title: "A brand new title" if content contains /title A brand new title' do
        changes = service.execute(content, issuable)

        expect(changes).to eq(title: 'A brand new title')
      end
    end

    shared_examples 'assign command' do
      it 'fetches assignee and populates assignee_id if content contains /assign' do
        changes = service.execute(content, issuable)

        expect(changes).to eq(assignee_id: user.id)
      end
    end

    shared_examples 'unassign command' do
      it 'populates assignee_id: nil if content contains /unassign' do
        issuable.update(assignee_id: user.id)
        changes = service.execute(content, issuable)

        expect(changes).to eq(assignee_id: nil)
      end
    end

    shared_examples 'milestone command' do
      it 'fetches milestone and populates milestone_id if content contains /milestone' do
        milestone # populate the milestone
        changes = service.execute(content, issuable)

        expect(changes).to eq(milestone_id: milestone.id)
      end
    end

    shared_examples 'clear_milestone command' do
      it 'populates milestone_id: nil if content contains /clear_milestone' do
        issuable.update(milestone_id: milestone.id)
        changes = service.execute(content, issuable)

        expect(changes).to eq(milestone_id: nil)
      end
    end

    shared_examples 'label command' do
      it 'fetches label ids and populates add_label_ids if content contains /label' do
        bug # populate the label
        inprogress # populate the label
        changes = service.execute(content, issuable)

        expect(changes).to eq(add_label_ids: [bug.id, inprogress.id])
      end
    end

    shared_examples 'unlabel command' do
      it 'fetches label ids and populates remove_label_ids if content contains /unlabel' do
        issuable.update(label_ids: [inprogress.id]) # populate the label
        changes = service.execute(content, issuable)

        expect(changes).to eq(remove_label_ids: [inprogress.id])
      end
    end

    shared_examples 'clear_labels command' do
      it 'populates label_ids: [] if content contains /clear_labels' do
        issuable.update(label_ids: [inprogress.id]) # populate the label
        changes = service.execute(content, issuable)

        expect(changes).to eq(label_ids: [])
      end
    end

    shared_examples 'todo command' do
      it 'populates todo_event: "add" if content contains /todo' do
        changes = service.execute(content, issuable)

        expect(changes).to eq(todo_event: 'add')
      end
    end

    shared_examples 'done command' do
      it 'populates todo_event: "done" if content contains /done' do
        TodoService.new.mark_todo(issuable, user)
        changes = service.execute(content, issuable)

        expect(changes).to eq(todo_event: 'done')
      end
    end

    shared_examples 'subscribe command' do
      it 'populates subscription_event: "subscribe" if content contains /subscribe' do
        changes = service.execute(content, issuable)

        expect(changes).to eq(subscription_event: 'subscribe')
      end
    end

    shared_examples 'unsubscribe command' do
      it 'populates subscription_event: "unsubscribe" if content contains /unsubscribe' do
        issuable.subscribe(user)
        changes = service.execute(content, issuable)

        expect(changes).to eq(subscription_event: 'unsubscribe')
      end
    end

    shared_examples 'due_date command' do
      it 'populates due_date: Date.new(2016, 8, 28) if content contains /due_date 2016-08-28' do
        changes = service.execute(content, issuable)

        expect(changes).to eq(due_date: defined?(expected_date) ? expected_date : Date.new(2016, 8, 28))
      end
    end

    shared_examples 'clear_due_date command' do
      it 'populates due_date: nil if content contains /clear_due_date' do
        issuable.update(due_date: Date.today)
        changes = service.execute(content, issuable)

        expect(changes).to eq(due_date: nil)
      end
    end

    shared_examples 'empty command' do
      it 'populates {} if content contains an unsupported command' do
        changes = service.execute(content, issuable)

        expect(changes).to be_empty
      end
    end

    it_behaves_like 'open command' do
      let(:content) { '/open' }
      let(:issuable) { issue }
    end

    it_behaves_like 'open command' do
      let(:content) { '/open' }
      let(:issuable) { merge_request }
    end

    it_behaves_like 'open command' do
      let(:content) { '/reopen' }
      let(:issuable) { issue }
    end

    it_behaves_like 'close command' do
      let(:content) { '/close' }
      let(:issuable) { issue }
    end

    it_behaves_like 'close command' do
      let(:content) { '/close' }
      let(:issuable) { merge_request }
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

    it_behaves_like 'assign command' do
      let(:content) { "/assign @#{user.username}" }
      let(:issuable) { issue }
    end

    it_behaves_like 'assign command' do
      let(:content) { "/assign @#{user.username}" }
      let(:issuable) { merge_request }
    end

    it_behaves_like 'empty command' do
      let(:content) { '/assign @abcd1234' }
      let(:issuable) { issue }
    end

    it_behaves_like 'empty command' do
      let(:content) { '/assign' }
      let(:issuable) { issue }
    end

    it_behaves_like 'unassign command' do
      let(:content) { '/unassign' }
      let(:issuable) { issue }
    end

    it_behaves_like 'unassign command' do
      let(:content) { '/unassign' }
      let(:issuable) { merge_request }
    end

    it_behaves_like 'unassign command' do
      let(:content) { '/remove_assignee' }
      let(:issuable) { issue }
    end

    it_behaves_like 'milestone command' do
      let(:content) { "/milestone %#{milestone.title}" }
      let(:issuable) { issue }
    end

    it_behaves_like 'milestone command' do
      let(:content) { "/milestone %#{milestone.title}" }
      let(:issuable) { merge_request }
    end

    it_behaves_like 'clear_milestone command' do
      let(:content) { '/clear_milestone' }
      let(:issuable) { issue }
    end

    it_behaves_like 'clear_milestone command' do
      let(:content) { '/clear_milestone' }
      let(:issuable) { merge_request }
    end

    it_behaves_like 'clear_milestone command' do
      let(:content) { '/remove_milestone' }
      let(:issuable) { issue }
    end

    it_behaves_like 'label command' do
      let(:content) { %(/label ~"#{inprogress.title}" ~#{bug.title} ~unknown) }
      let(:issuable) { issue }
    end

    it_behaves_like 'label command' do
      let(:content) { %(/label ~"#{inprogress.title}" ~#{bug.title} ~unknown) }
      let(:issuable) { merge_request }
    end

    it_behaves_like 'label command' do
      let(:content) { %(/labels ~"#{inprogress.title}" ~#{bug.title} ~unknown) }
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

    it_behaves_like 'unlabel command' do
      let(:content) { %(/remove_labels ~"#{inprogress.title}") }
      let(:issuable) { issue }
    end

    it_behaves_like 'unlabel command' do
      let(:content) { %(/remove_label ~"#{inprogress.title}") }
      let(:issuable) { issue }
    end

    it_behaves_like 'clear_labels command' do
      let(:content) { '/clear_labels' }
      let(:issuable) { issue }
    end

    it_behaves_like 'clear_labels command' do
      let(:content) { '/clear_labels' }
      let(:issuable) { merge_request }
    end

    it_behaves_like 'clear_labels command' do
      let(:content) { '/clear_label' }
      let(:issuable) { issue }
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

    it_behaves_like 'due_date command' do
      let(:content) { '/due_date 2016-08-28' }
      let(:issuable) { issue }
    end

    it_behaves_like 'due_date command' do
      let(:content) { '/due tomorrow' }
      let(:issuable) { issue }
      let(:expected_date) { Date.tomorrow }
    end

    it_behaves_like 'due_date command' do
      let(:content) { '/due 5 days from now' }
      let(:issuable) { issue }
      let(:expected_date) { 5.days.from_now.to_date }
    end

    it_behaves_like 'due_date command' do
      let(:content) { '/due in 2 days' }
      let(:issuable) { issue }
      let(:expected_date) { 2.days.from_now.to_date }
    end

    it_behaves_like 'empty command' do
      let(:content) { '/due_date foo bar' }
      let(:issuable) { issue }
    end

    it_behaves_like 'empty command' do
      let(:content) { '/due_date 2016-08-28' }
      let(:issuable) { merge_request }
    end

    it_behaves_like 'clear_due_date command' do
      let(:content) { '/clear_due_date' }
      let(:issuable) { issue }
    end

    it_behaves_like 'empty command' do
      let(:content) { '/clear_due_date' }
      let(:issuable) { merge_request }
    end
  end
end
