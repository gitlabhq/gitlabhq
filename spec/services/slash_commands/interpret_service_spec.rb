require 'spec_helper'

describe SlashCommands::InterpretService, services: true do
  let(:project) { create(:project) }
  let(:user) { create(:user) }
  let(:issue) { create(:issue, project: project) }
  let(:milestone) { create(:milestone, project: project, title: '9.10') }
  let(:inprogress) { create(:label, project: project, title: 'In Progress') }
  let(:bug) { create(:label, project: project, title: 'Bug') }

  describe '#command_names' do
    subject { described_class.command_names }

    it 'returns the known commands' do
      is_expected.to match_array([
        :open, :reopen,
        :close,
        :title,
        :assign, :reassign,
        :unassign, :remove_assignee,
        :milestone,
        :clear_milestone, :remove_milestone,
        :labels, :label,
        :unlabel, :remove_labels, :remove_label,
        :clear_labels, :clear_label,
        :todo,
        :done,
        :subscribe,
        :unsubscribe,
        :due_date,
        :clear_due_date
      ])
    end
  end

  describe '#execute' do
    let(:service) { described_class.new(project, user) }
    let(:issue) { create(:issue) }
    let(:merge_request) { create(:merge_request) }

    shared_examples 'open command' do
      it 'returns state_event: "open" if content contains /open' do
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
        changes = service.execute(content, issuable)

        expect(changes).to eq(assignee_id: nil)
      end
    end

    shared_examples 'milestone command' do
      it 'fetches milestone and populates milestone_id if content contains /milestone' do
        changes = service.execute(content, issuable)

        expect(changes).to eq(milestone_id: milestone.id)
      end
    end

    shared_examples 'clear_milestone command' do
      it 'populates milestone_id: nil if content contains /clear_milestone' do
        changes = service.execute(content, issuable)

        expect(changes).to eq(milestone_id: nil)
      end
    end

    shared_examples 'label command' do
      it 'fetches label ids and populates add_label_ids if content contains /label' do
        changes = service.execute(content, issuable)

        expect(changes).to eq(add_label_ids: [bug.id, inprogress.id])
      end
    end

    shared_examples 'unlabel command' do
      it 'fetches label ids and populates remove_label_ids if content contains /unlabel' do
        changes = service.execute(content, issuable)

        expect(changes).to eq(remove_label_ids: [inprogress.id])
      end
    end

    shared_examples 'clear_labels command' do
      it 'populates label_ids: [] if content contains /clear_labels' do
        changes = service.execute(content, issuable)

        expect(changes).to eq(label_ids: [])
      end
    end

    shared_examples 'todo command' do
      it 'populates todo_event: "mark" if content contains /todo' do
        changes = service.execute(content, issuable)

        expect(changes).to eq(todo_event: 'mark')
      end
    end

    shared_examples 'done command' do
      it 'populates todo_event: "done" if content contains /done' do
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
        changes = service.execute(content, issuable)

        expect(changes).to eq(subscription_event: 'unsubscribe')
      end
    end

    shared_examples 'due_date command' do
      it 'populates due_date: Date.new(2016, 8, 28) if content contains /due_date 2016-08-28' do
        changes = service.execute(content, issuable)

        expect(changes).to eq(due_date: Date.new(2016, 8, 28))
      end
    end

    shared_examples 'clear_due_date command' do
      it 'populates due_date: nil if content contains /clear_due_date' do
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
