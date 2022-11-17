# frozen_string_literal: true

RSpec.shared_examples 'issuable update service' do
  def update_issuable(opts)
    described_class.new(project, user, opts).execute(open_issuable)
  end

  context 'changing state' do
    let(:hook_event) { :"#{closed_issuable.class.name.underscore.to_sym}_hooks" }

    context 'to reopened' do
      let(:expected_payload) do
        include(
          changes: include(
            state_id: { current: 1, previous: 2 },
            updated_at: { current: kind_of(Time), previous: kind_of(Time) }
          ),
          object_attributes: include(
            state: 'opened',
            action: 'reopen'
          )
        )
      end

      it 'executes hooks' do
        expect(project).to receive(:execute_hooks).with(expected_payload, hook_event)
        expect(project).to receive(:execute_integrations).with(expected_payload, hook_event)

        described_class.new(project: project, current_user: user, params: { state_event: 'reopen' }).execute(closed_issuable)
      end
    end

    context 'to closed' do
      let(:expected_payload) do
        include(
          changes: include(
            state_id: { current: 2, previous: 1 },
            updated_at: { current: kind_of(Time), previous: kind_of(Time) }
          ),
          object_attributes: include(
            state: 'closed',
            action: 'close'
          )
        )
      end

      it 'executes hooks' do
        expect(project).to receive(:execute_hooks).with(expected_payload, hook_event)
        expect(project).to receive(:execute_integrations).with(expected_payload, hook_event)

        described_class.new(project: project, current_user: user, params: { state_event: 'close' }).execute(open_issuable)
      end
    end
  end
end

RSpec.shared_examples 'keeps issuable labels sorted after update' do
  before do
    update_issuable(label_ids: [label_b.id])
  end

  context 'when label is changed' do
    it 'keeps the labels sorted by title ASC' do
      update_issuable({ add_label_ids: [label_a.id] })

      expect(issuable.labels).to eq([label_a, label_b])
    end
  end
end

RSpec.shared_examples 'broadcasting issuable labels updates' do
  before do
    update_issuable(label_ids: [label_a.id])
  end

  context 'when label is added' do
    it 'triggers the GraphQL subscription' do
      expect(GraphqlTriggers).to receive(:issuable_labels_updated).with(issuable)

      update_issuable(add_label_ids: [label_b.id])
    end
  end

  context 'when label is removed' do
    it 'triggers the GraphQL subscription' do
      expect(GraphqlTriggers).to receive(:issuable_labels_updated).with(issuable)

      update_issuable(remove_label_ids: [label_a.id])
    end
  end

  context 'when label is unchanged' do
    it 'does not trigger the GraphQL subscription' do
      expect(GraphqlTriggers).not_to receive(:issuable_labels_updated).with(issuable)

      update_issuable(label_ids: [label_a.id])
    end
  end
end
