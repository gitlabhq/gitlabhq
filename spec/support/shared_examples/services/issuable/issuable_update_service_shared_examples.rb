# frozen_string_literal: true

RSpec.shared_examples 'issuable update service' do
  def update_issuable(opts)
    described_class.new(project, user, opts).execute(open_issuable)
  end

  describe 'changing state' do
    let(:hook_event) { :"#{closed_issuable.class.name.underscore.to_sym}_hooks" }

    describe 'to reopened' do
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
        hooks_container = described_class < Issues::BaseService ? project.project_namespace : project
        expect(hooks_container).to receive(:execute_hooks).with(expected_payload, hook_event)
        expect(hooks_container).to receive(:execute_integrations).with(expected_payload, hook_event)

        described_class.new(
          **described_class.constructor_container_arg(project),
          current_user: user,
          params: { state_event: 'reopen' }
        ).execute(closed_issuable)
      end
    end

    describe 'to closed' do
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
        hooks_container = described_class < Issues::BaseService ? project.project_namespace : project
        expect(hooks_container).to receive(:execute_hooks).with(expected_payload, hook_event)
        expect(hooks_container).to receive(:execute_integrations).with(expected_payload, hook_event)

        described_class.new(
          **described_class.constructor_container_arg(project),
          current_user: user,
          params: { state_event: 'close' }
        ).execute(open_issuable)
      end
    end
  end
end

RSpec.shared_examples 'updating issuable labels' do
  context 'when add_label_ids and label_ids are passed' do
    let(:params) { { label_ids: [label_a.id], add_label_ids: [label_c.id] } }

    it 'replaces the labels with the ones in label_ids and adds those in add_label_ids' do
      issuable.update!(labels: [label_b])
      update_issuable(params)

      expect(issuable.label_ids).to contain_exactly(label_a.id, label_c.id)
    end
  end

  context 'when remove_label_ids and label_ids are passed' do
    let(:params) { { label_ids: [label_a.id, label_b.id, label_c.id], remove_label_ids: [label_a.id] } }

    it 'replaces the labels with the ones in label_ids and removes those in remove_label_ids' do
      issuable.update!(labels: [label_a, label_c])
      update_issuable(params)

      expect(issuable.label_ids).to contain_exactly(label_b.id, label_c.id)
    end
  end

  context 'when add_label_ids and remove_label_ids are passed' do
    let(:params) { { add_label_ids: [label_c.id], remove_label_ids: [label_a.id] } }

    before do
      issuable.update!(labels: [label_a])
      update_issuable(params)
    end

    it 'adds the passed labels' do
      expect(issuable.label_ids).to include(label_c.id)
    end

    it 'removes the passed labels' do
      expect(issuable.label_ids).not_to include(label_a.id)
    end
  end

  context 'when same id is passed as add_label_ids and remove_label_ids' do
    let(:params) { { add_label_ids: [label_a.id], remove_label_ids: [label_a.id] } }

    context 'for a label assigned to an issue' do
      it 'removes the label' do
        issuable.update!(labels: [label_a])
        update_issuable(params)

        expect(issuable.label_ids).to be_empty
      end
    end

    context 'for a label not assigned to an issue' do
      it 'does not add the label' do
        expect(issuable.label_ids).to be_empty
      end
    end
  end

  context 'when duplicate label titles are given' do
    let(:params) { { labels: [label_c.title, label_c.title] } }

    it 'assigns the label once' do
      update_issuable(params)

      expect(issuable.labels).to contain_exactly(label_c)
    end
  end

  context 'when remove_label_ids contains a locked label' do
    let(:params) { { remove_label_ids: [label_locked.id] } }

    it 'removes locked labels for non-merged issuables' do
      issuable.update!(labels: [label_a, label_locked])
      update_issuable(params)

      expect(issuable.label_ids).to contain_exactly(label_a.id)
    end
  end
end

RSpec.shared_examples 'updating merged MR with locked labels' do
  context 'when add_label_ids and label_ids are passed' do
    let(:params) { { label_ids: [label_a.id], add_label_ids: [label_c.id] } }

    it 'replaces unlocked labels with the ones in label_ids and adds those in add_label_ids' do
      issuable.update!(labels: [label_b, label_unlocked])
      update_issuable(params)

      expect(issuable.label_ids).to contain_exactly(label_a.id, label_b.id, label_c.id)
    end
  end

  context 'when remove_label_ids and label_ids are passed' do
    let(:params) { { label_ids: [label_a.id, label_b.id, label_c.id], remove_label_ids: [label_a.id] } }

    it 'replaces unlocked labels with the ones in label_ids and does not remove locked label in remove_label_ids' do
      issuable.update!(labels: [label_a, label_c, label_unlocked])
      update_issuable(params)

      expect(issuable.label_ids).to contain_exactly(label_a.id, label_b.id, label_c.id)
    end
  end

  context 'when add_label_ids and remove_label_ids are passed' do
    let(:params) { { add_label_ids: [label_c.id], remove_label_ids: [label_a.id, label_unlocked.id] } }

    before do
      issuable.update!(labels: [label_a, label_unlocked])
      update_issuable(params)
    end

    it 'adds the passed labels' do
      expect(issuable.label_ids).to include(label_c.id)
    end

    it 'removes the passed unlocked labels' do
      expect(issuable.label_ids).to include(label_a.id)
      expect(issuable.label_ids).not_to include(label_unlocked.id)
    end
  end

  context 'when same id is passed as add_label_ids and remove_label_ids' do
    let(:params) { { add_label_ids: [label_a.id], remove_label_ids: [label_a.id] } }

    context 'for a label assigned to an issue' do
      it 'does not remove the label' do
        issuable.update!(labels: [label_a])
        update_issuable(params)

        expect(issuable.label_ids).to contain_exactly(label_a.id)
      end
    end

    context 'for a label not assigned to an issue' do
      it 'does not add the label' do
        expect(issuable.label_ids).to be_empty
      end
    end
  end

  context 'when duplicate label titles are given' do
    let(:params) { { labels: [label_c.title, label_c.title] } }

    it 'assigns the label once' do
      update_issuable(params)

      expect(issuable.labels).to contain_exactly(label_c)
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

RSpec.shared_examples_for 'issuable update service updating last_edited_at values' do
  context 'when updating the title of the issuable' do
    let(:update_params) { { title: 'updated title' } }

    it 'does not update last_edited values' do
      expect { update_issuable }.to change { issuable.title }.from(issuable.title).to('updated title').and(
        not_change(issuable, :last_edited_at)
      ).and(
        not_change(issuable, :last_edited_by)
      )
    end
  end

  context 'when updating the description of the issuable' do
    let(:update_params) { { description: 'updated description' } }

    it 'updates last_edited values' do
      expect do
        update_issuable
      end.to change { issuable.description }.from(issuable.description).to('updated description').and(
        change { issuable.last_edited_at }
      ).and(
        change { issuable.last_edited_by }
      )
    end
  end
end
