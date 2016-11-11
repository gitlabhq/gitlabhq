require 'spec_helper'

describe SlashCommands::InterpretService, services: true do
  let(:project) { create(:empty_project, :public) }
  let(:developer) { create(:user) }
  let(:issue) { create(:issue, project: project) }
  let(:milestone) { create(:milestone, project: project, title: '9.10') }
  let(:inprogress) { create(:label, project: project, title: 'In Progress') }
  let(:bug) { create(:label, project: project, title: 'Bug') }

  before do
    project.team << [developer, :developer]
  end

  describe '#execute' do
    let(:service) { described_class.new(project, developer) }
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

    shared_examples 'assign command' do
      it 'fetches assignee and populates assignee_id if content contains /assign' do
        _, updates = service.execute(content, issuable)

        expect(updates).to eq(assignee_id: developer.id)
      end
    end

    shared_examples 'unassign command' do
      it 'populates assignee_id: nil if content contains /unassign' do
        issuable.update(assignee_id: developer.id)
        _, updates = service.execute(content, issuable)

        expect(updates).to eq(assignee_id: nil)
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
        issuable.update(milestone_id: milestone.id)
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
        issuable.update(label_ids: [inprogress.id]) # populate the label
        _, updates = service.execute(content, issuable)

        expect(updates).to eq(remove_label_ids: [inprogress.id])
      end
    end

    shared_examples 'multiple unlabel command' do
      it 'fetches label ids and populates remove_label_ids if content contains  mutiple /unlabel' do
        issuable.update(label_ids: [inprogress.id, bug.id]) # populate the label
        _, updates = service.execute(content, issuable)

        expect(updates).to eq(remove_label_ids: [inprogress.id, bug.id])
      end
    end

    shared_examples 'unlabel command with no argument' do
      it 'populates label_ids: [] if content contains /unlabel with no arguments' do
        issuable.update(label_ids: [inprogress.id]) # populate the label
        _, updates = service.execute(content, issuable)

        expect(updates).to eq(label_ids: [])
      end
    end

    shared_examples 'relabel command' do
      it 'populates label_ids: [] if content contains /relabel' do
        issuable.update(label_ids: [bug.id]) # populate the label
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
        issuable.subscribe(developer)
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
        issuable.update(due_date: Date.today)
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
        issuable.update(title: issuable.wip_title)
        _, updates = service.execute(content, issuable)

        expect(updates).to eq(wip_event: 'unwip')
      end
    end

    shared_examples 'estimate command' do
      it 'populates time_estimate: "3600" if content contains /estimate 1h' do
        _, updates = service.execute(content, issuable)

        expect(updates).to eq(time_estimate: 3600)
      end
    end

    shared_examples 'spend command' do
      it 'populates spend_time: "3600" if content contains /spend 1h' do
        _, updates = service.execute(content, issuable)

        expect(updates).to eq(spend_time: 3600)
      end
    end

    shared_examples 'spend command with negative time' do
      it 'populates spend_time: "-1800" if content contains /spend -30m' do
        _, updates = service.execute(content, issuable)

        expect(updates).to eq(spend_time: -1800)
      end
    end

    shared_examples 'remove_estimation command' do
      it 'populates time_estimate: "0" if content contains /remove_estimation' do
        _, updates = service.execute(content, issuable)

        expect(updates).to eq(time_estimate: 0)
      end
    end

    shared_examples 'remove_time_spent command' do
      it 'populates spend_time: "0" if content contains /remove_time_spent' do
        _, updates = service.execute(content, issuable)

        expect(updates).to eq(spend_time: 0)
      end
    end

    shared_examples 'empty command' do
      it 'populates {} if content contains an unsupported command' do
        _, updates = service.execute(content, issuable)

        expect(updates).to be_empty
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
      let(:content) { "/assign @#{developer.username}" }
      let(:issuable) { issue }
    end

    it_behaves_like 'assign command' do
      let(:content) { "/assign @#{developer.username}" }
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

    it_behaves_like 'milestone command' do
      let(:content) { "/milestone %#{milestone.title}" }
      let(:issuable) { issue }
    end

    it_behaves_like 'milestone command' do
      let(:content) { "/milestone %#{milestone.title}" }
      let(:issuable) { merge_request }
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

    it_behaves_like 'empty command' do
      let(:content) { '/spend' }
      let(:issuable) { issue }
    end

    it_behaves_like 'empty command' do
      let(:content) { '/spend abc' }
      let(:issuable) { issue }
    end

    it_behaves_like 'remove_estimation command' do
      let(:content) { '/remove_estimation' }
      let(:issuable) { issue }
    end

    it_behaves_like 'remove_time_spent command' do
      let(:content) { '/remove_time_spent' }
      let(:issuable) { issue }
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
    end
  end
end
