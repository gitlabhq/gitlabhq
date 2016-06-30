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
        :assign, :reassign,
        :unassign, :remove_assignee,
        :milestone,
        :remove_milestone,
        :clear_milestone,
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

    shared_examples 'open command' do
      it 'returns state_event: "open" if content contains /open' do
        changes = service.execute(content)

        expect(changes).to eq(state_event: 'reopen')
      end
    end

    shared_examples 'close command' do
      it 'returns state_event: "close" if content contains /open' do
        changes = service.execute(content)

        expect(changes).to eq(state_event: 'close')
      end
    end

    shared_examples 'assign command' do
      it 'fetches assignee and populates assignee_id if content contains /assign' do
        changes = service.execute(content)

        expect(changes).to eq(assignee_id: user.id)
      end
    end

    shared_examples 'milestone command' do
      it 'fetches milestone and populates milestone_id if content contains /milestone' do
        changes = service.execute(content)

        expect(changes).to eq(milestone_id: milestone.id)
      end
    end

    shared_examples 'label command' do
      it 'fetches label ids and populates add_label_ids if content contains /label' do
        changes = service.execute(content)

        expect(changes).to eq(add_label_ids: [bug.id, inprogress.id])
      end
    end

    shared_examples 'remove_labels command' do
      it 'fetches label ids and populates remove_label_ids if content contains /label' do
        changes = service.execute(content)

        expect(changes).to eq(remove_label_ids: [inprogress.id])
      end
    end

    shared_examples 'clear_labels command' do
      it 'populates label_ids: [] if content contains /clear_labels' do
        changes = service.execute(content)

        expect(changes).to eq(label_ids: [])
      end
    end

    shared_examples 'command returning no changes' do
      it 'returns an empty hash if content contains /open' do
        changes = service.execute(content)

        expect(changes).to be_empty
      end
    end

    it_behaves_like 'open command' do
      let(:content) { '/open' }
    end

    it_behaves_like 'open command' do
      let(:content) { '/reopen' }
    end

    it_behaves_like 'close command' do
      let(:content) { '/close' }
    end

    it_behaves_like 'assign command' do
      let(:content) { "/assign @#{user.username}" }
    end

    it 'does not populate assignee_id if content contains /assign with an unknown user' do
      changes = service.execute('/assign joe')

      expect(changes).to be_empty
    end

    it 'does not populate assignee_id if content contains /assign without user' do
      changes = service.execute('/assign')

      expect(changes).to be_empty
    end

    it 'populates assignee_id: nil if content contains /unassign' do
      changes = service.execute('/unassign')

      expect(changes).to eq(assignee_id: nil)
    end

    it_behaves_like 'milestone command' do
      let(:content) { "/milestone %#{milestone.title}" }
    end

    it 'populates milestone_id: nil if content contains /clear_milestone' do
      changes = service.execute('/clear_milestone')

      expect(changes).to eq(milestone_id: nil)
    end

    it_behaves_like 'label command' do
      let(:content) { %(/label ~"#{inprogress.title}" ~#{bug.title} ~unknown) }
    end

    it_behaves_like 'label command' do
      let(:content) { %(/labels ~"#{inprogress.title}" ~#{bug.title} ~unknown) }
    end

    it_behaves_like 'remove_labels command' do
      let(:content) { %(/unlabel ~"#{inprogress.title}") }
    end

    it_behaves_like 'remove_labels command' do
      let(:content) { %(/remove_labels ~"#{inprogress.title}") }
    end

    it_behaves_like 'remove_labels command' do
      let(:content) { %(/remove_label ~"#{inprogress.title}") }
    end

    it_behaves_like 'clear_labels command' do
      let(:content) { '/clear_labels' }
    end

    it_behaves_like 'clear_labels command' do
      let(:content) { '/clear_label' }
    end

    it 'populates todo: :mark if content contains /todo' do
      changes = service.execute('/todo')

      expect(changes).to eq(todo_event: 'mark')
    end

    it 'populates todo: :done if content contains /done' do
      changes = service.execute('/done')

      expect(changes).to eq(todo_event: 'done')
    end

    it 'populates subscription: :subscribe if content contains /subscribe' do
      changes = service.execute('/subscribe')

      expect(changes).to eq(subscription_event: 'subscribe')
    end

    it 'populates subscription: :unsubscribe if content contains /unsubscribe' do
      changes = service.execute('/unsubscribe')

      expect(changes).to eq(subscription_event: 'unsubscribe')
    end

    it 'populates due_date: Time.now.tomorrow if content contains /due_date 2016-08-28' do
      changes = service.execute('/due_date 2016-08-28')

      expect(changes).to eq(due_date: Date.new(2016, 8, 28))
    end

    it 'populates due_date: Time.now.tomorrow if content contains /due_date foo' do
      changes = service.execute('/due_date foo')

      expect(changes).to be_empty
    end

    it 'populates due_date: nil if content contains /clear_due_date' do
      changes = service.execute('/clear_due_date')

      expect(changes).to eq(due_date: nil)
    end
  end
end
