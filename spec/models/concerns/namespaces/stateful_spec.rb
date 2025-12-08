# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Namespaces::Stateful, feature_category: :groups_and_projects do
  let_it_be(:user) { create(:user) }
  let_it_be_with_reload(:namespace) { create(:namespace) }

  # Helper method to set state bypassing validations
  def set_state(record, state_symbol)
    record.update_column(:state, described_class::STATES[state_symbol])
  end

  describe 'STATES constant' do
    it 'defines all expected states' do
      expect(described_class::STATES).to eq({
        'ancestor_inherited' => nil,
        'archived' => 1,
        'deletion_scheduled' => 2,
        'creation_in_progress' => 3,
        'deletion_in_progress' => 4,
        'transfer_in_progress' => 5,
        'maintenance' => 6
      })
    end

    it 'is frozen' do
      expect(described_class::STATES).to be_frozen
    end
  end

  describe 'state machine' do
    subject { namespace }

    it "declares all expected states" do
      is_expected.to have_states :ancestor_inherited, :archived, :deletion_scheduled,
        :creation_in_progress, :deletion_in_progress,
        :transfer_in_progress, :maintenance
    end

    it 'has ancestor_inherited as initial state' do
      expect(namespace.state_name).to eq(:ancestor_inherited)
    end

    it { is_expected.to handle_events :archive, when: :ancestor_inherited }
    it { is_expected.to handle_events :unarchive, when: :archived }
    it { is_expected.to handle_events :schedule_deletion, when: :ancestor_inherited }
    it { is_expected.to handle_events :schedule_deletion, when: :archived }
    it { is_expected.to handle_events :start_deletion, when: :deletion_scheduled }

    it 'transitions from ancestor_inherited to archived on archive' do
      namespace.state = described_class::STATES[:ancestor_inherited]
      expect { namespace.archive(current_user: user) }
        .to change { namespace.state_name }
        .from(:ancestor_inherited)
        .to(:archived)
    end

    it 'transitions from archived to ancestor_inherited on unarchive' do
      namespace.state = described_class::STATES[:archived]
      expect { namespace.unarchive(current_user: user) }
        .to change { namespace.state_name }
        .from(:archived)
        .to(:ancestor_inherited)
    end

    it 'transitions from ancestor_inherited to deletion_scheduled on schedule_deletion' do
      namespace.state = described_class::STATES[:ancestor_inherited]
      expect { namespace.schedule_deletion(current_user: user) }
        .to change { namespace.state_name }
        .from(:ancestor_inherited)
        .to(:deletion_scheduled)
    end

    it 'transitions from archived to deletion_scheduled on schedule_deletion' do
      namespace.state = described_class::STATES[:archived]
      expect { namespace.schedule_deletion(current_user: user) }
        .to change { namespace.state_name }
        .from(:archived)
        .to(:deletion_scheduled)
    end

    it 'transitions from deletion_scheduled to deletion_in_progress on start_deletion' do
      namespace.state = described_class::STATES[:deletion_scheduled]
      expect { namespace.start_deletion(current_user: user) }
        .to change { namespace.state_name }
        .from(:deletion_scheduled)
        .to(:deletion_in_progress)
    end

    it { is_expected.to reject_events :archive, when: :archived }
    it { is_expected.to reject_events :unarchive, when: :ancestor_inherited }
    it { is_expected.to reject_events :schedule_deletion, when: :deletion_scheduled }
    it { is_expected.to reject_events :start_deletion, when: :ancestor_inherited }

    describe 'state values' do
      described_class::STATES.each do |state_name, state_value|
        it { is_expected.to have_state state_name.to_sym, value: state_value }
      end
    end

    describe 'events' do
      describe '#archive' do
        context 'when namespace is in ancestor_inherited state' do
          before do
            namespace.state = described_class::STATES[:ancestor_inherited]
          end

          it 'transitions to archived' do
            expect { namespace.archive(current_user: user) }
              .to change { namespace.state_name }
              .from(:ancestor_inherited)
              .to(:archived)
          end

          it 'updates state_metadata with user and timestamp' do
            freeze_time do
              namespace.archive(current_user: user)

              namespace.namespace_details.reload
              metadata = namespace.namespace_details.state_metadata

              expect(metadata['last_changed_by_user_id']).to eq(user.id)
              expect(metadata['last_updated_at']).to be_present
              expect(metadata['last_error']).to be_nil
            end
          end

          it 'updates state_metadata without user for system-triggered transitions' do
            freeze_time do
              namespace.archive

              namespace.namespace_details.reload
              metadata = namespace.namespace_details.state_metadata

              expect(metadata['last_changed_by_user_id']).to be_nil
              expect(metadata['last_updated_at']).to be_present
              expect(metadata['last_error']).to be_nil
              expect(metadata['correlation_id']).to be_present
            end
          end
        end

        context 'when namespace is not in ancestor_inherited state' do
          before do
            namespace.state = described_class::STATES[:archived]
          end

          it 'does not transition' do
            expect { namespace.archive(current_user: user) }
              .to not_change { namespace.state_name }
          end
        end
      end

      describe '#unarchive' do
        context 'when namespace is in archived state' do
          before do
            namespace.state = described_class::STATES[:archived]
          end

          it 'transitions to ancestor_inherited' do
            expect { namespace.unarchive(current_user: user) }
              .to change { namespace.state_name }
              .from(:archived)
              .to(:ancestor_inherited)
          end

          it 'updates state_metadata' do
            freeze_time do
              namespace.unarchive(current_user: user)

              namespace.namespace_details.reload
              metadata = namespace.namespace_details.state_metadata

              expect(metadata['last_changed_by_user_id']).to eq(user.id)
              expect(metadata['last_updated_at']).to be_present
              expect(metadata['last_error']).to be_nil
            end
          end
        end
      end

      describe '#schedule_deletion' do
        context 'when namespace is in ancestor_inherited state' do
          before do
            namespace.state = described_class::STATES[:ancestor_inherited]
          end

          it 'transitions to deletion_scheduled' do
            expect { namespace.schedule_deletion(current_user: user) }
              .to change { namespace.state_name }
              .from(:ancestor_inherited)
              .to(:deletion_scheduled)
          end

          it 'updates state_metadata' do
            freeze_time do
              namespace.schedule_deletion(current_user: user)

              namespace.namespace_details.reload
              metadata = namespace.namespace_details.state_metadata

              expect(metadata['last_changed_by_user_id']).to eq(user.id)
              expect(metadata['last_updated_at']).to be_present
              expect(metadata['last_error']).to be_nil
            end
          end
        end

        context 'when namespace is in archived state' do
          before do
            namespace.state = described_class::STATES[:archived]
          end

          it 'transitions to deletion_scheduled' do
            expect { namespace.schedule_deletion(current_user: user) }
              .to change { namespace.state_name }
              .from(:archived)
              .to(:deletion_scheduled)
          end
        end
      end

      describe '#start_deletion' do
        context 'when namespace is in deletion_scheduled state' do
          before do
            namespace.state = described_class::STATES[:deletion_scheduled]
          end

          it 'transitions to deletion_in_progress' do
            expect { namespace.start_deletion(current_user: user) }
              .to change { namespace.state_name }
              .from(:deletion_scheduled)
              .to(:deletion_in_progress)
          end

          it 'updates state_metadata' do
            freeze_time do
              namespace.start_deletion(current_user: user)

              namespace.namespace_details.reload
              metadata = namespace.namespace_details.state_metadata

              expect(metadata['last_changed_by_user_id']).to eq(user.id)
              expect(metadata['last_updated_at']).to be_present
              expect(metadata['last_error']).to be_nil
            end
          end
        end
      end
    end
  end

  describe '#handle_transition_failure' do
    before do
      namespace.state = described_class::STATES[:ancestor_inherited]
    end

    it 'saves error message when transition fails' do
      namespace.errors.add(:state, 'invalid transition')

      transition = Struct.new(:args, :event, :from_name, :to_name).new(
        args: [{ current_user: user }],
        event: :archive,
        from_name: :ancestor_inherited,
        to_name: :archived
      )
      namespace.send(:handle_transition_failure, transition)

      metadata = namespace.namespace_details.reload.state_metadata
      expect(metadata['last_error']).to include(
        'Cannot transition from ancestor_inherited to archived via archive'
      )
      expect(metadata['last_error']).to include('invalid transition')
      expect(metadata['last_changed_by_user_id']).to eq(user.id)
    end

    it 'saves error without current_user' do
      namespace.namespace_details.update!(state_metadata: { last_changed_by_user_id: user.id })
      namespace.errors.add(:state, 'some error')

      transition = Struct.new(:args, :event, :from_name, :to_name).new(
        args: [{}],
        event: :unarchive,
        from_name: :archived,
        to_name: :ancestor_inherited
      )
      namespace.send(:handle_transition_failure, transition)

      metadata = namespace.namespace_details.reload.state_metadata
      expect(metadata['last_error']).to include(
        'Cannot transition from archived to ancestor_inherited via unarchive'
      )
      expect(metadata['last_error']).to include('some error')
      expect(metadata['last_changed_by_user_id']).to be_nil
    end

    it 'handles unknown errors when no state errors exist' do
      namespace.namespace_details.update!(state_metadata: {})
      namespace.errors.clear

      expect(namespace.errors[:state]).to be_empty

      transition = Struct.new(:args, :event, :from_name, :to_name).new(
        args: [{ current_user: user }],
        event: :schedule_deletion,
        from_name: :ancestor_inherited,
        to_name: :deletion_scheduled
      )
      namespace.send(:handle_transition_failure, transition)

      metadata = namespace.namespace_details.reload.state_metadata
      expect(metadata['last_error']).to include(
        'Cannot transition from ancestor_inherited to deletion_scheduled via schedule_deletion'
      )
      expect(metadata['last_error']).to include('unknown reason')
    end
  end

  describe 'correlation_id tracking' do
    it 'stores custom correlation_id when provided' do
      custom_correlation_id = 'custom-correlation-id-123'
      namespace.state = described_class::STATES[:ancestor_inherited]
      namespace.archive(current_user: user, correlation_id: custom_correlation_id)

      metadata = namespace.namespace_details.reload.state_metadata
      expect(metadata['correlation_id']).to eq(custom_correlation_id)
    end

    it 'uses current correlation_id when not provided' do
      namespace.state = described_class::STATES[:ancestor_inherited]

      allow(Labkit::Correlation::CorrelationId).to receive(:current_id).and_return('auto-correlation-id')
      namespace.archive(current_user: user)

      metadata = namespace.namespace_details.reload.state_metadata
      expect(metadata['correlation_id']).to eq('auto-correlation-id')
    end

    it 'tracks correlation_id in failure scenarios' do
      custom_correlation_id = 'failure-correlation-id'
      namespace.errors.add(:state, 'test error')

      transition = Struct.new(:args, :event, :from_name, :to_name).new(
        args: [{ current_user: user, correlation_id: custom_correlation_id }],
        event: :archive,
        from_name: :ancestor_inherited,
        to_name: :archived
      )
      namespace.send(:handle_transition_failure, transition)

      metadata = namespace.namespace_details.reload.state_metadata
      expect(metadata['correlation_id']).to eq(custom_correlation_id)
    end
  end

  describe 'logging' do
    it 'logs successful state transitions' do
      namespace.state = described_class::STATES[:ancestor_inherited]

      expect(Gitlab::AppLogger).to receive(:info).with(
        hash_including(
          message: 'Namespace state transition',
          namespace_id: namespace.id,
          from_state: :ancestor_inherited,
          to_state: :archived,
          event: :archive,
          user_id: user.id,
          correlation_id: be_present
        )
      )

      namespace.archive(current_user: user)
    end

    it 'logs successful state transitions without user' do
      namespace.state = described_class::STATES[:ancestor_inherited]

      expect(Gitlab::AppLogger).to receive(:info).with(
        hash_including(
          message: 'Namespace state transition',
          namespace_id: namespace.id,
          from_state: :ancestor_inherited,
          to_state: :archived,
          event: :archive,
          user_id: nil,
          correlation_id: be_present
        )
      )

      namespace.archive
    end

    it 'logs failed state transitions' do
      namespace.errors.add(:state, 'test error')

      expect(Gitlab::AppLogger).to receive(:error).with(
        hash_including(
          message: 'Namespace state transition failed',
          namespace_id: namespace.id,
          event: :archive,
          current_state: :ancestor_inherited,
          error: match(/Cannot transition from ancestor_inherited to archived via archive/),
          user_id: user.id,
          correlation_id: be_present
        )
      )

      transition = Struct.new(:args, :event, :from_name, :to_name).new(
        args: [{ current_user: user }],
        event: :archive,
        from_name: :ancestor_inherited,
        to_name: :archived
      )
      namespace.send(:handle_transition_failure, transition)
    end
  end

  describe '#effective_state' do
    context 'when namespace has its own explicit state' do
      it 'returns the namespace own state when archived' do
        namespace.state = described_class::STATES[:archived]
        expect(namespace.effective_state).to eq(:archived)
      end

      it 'returns the namespace own state when transfer_in_progress' do
        namespace.state = described_class::STATES[:transfer_in_progress]
        expect(namespace.effective_state).to eq(:transfer_in_progress)
      end

      it 'returns the namespace own state when maintenance' do
        namespace.state = described_class::STATES[:maintenance]
        expect(namespace.effective_state).to eq(:maintenance)
      end

      it 'returns the namespace own state when deletion_scheduled' do
        namespace.state = described_class::STATES[:deletion_scheduled]
        expect(namespace.effective_state).to eq(:deletion_scheduled)
      end

      it 'returns the namespace own state when creation_in_progress' do
        namespace.state = described_class::STATES[:creation_in_progress]
        expect(namespace.effective_state).to eq(:creation_in_progress)
      end

      it 'returns the namespace own state when deletion_in_progress' do
        namespace.state = described_class::STATES[:deletion_in_progress]
        expect(namespace.effective_state).to eq(:deletion_in_progress)
      end
    end

    context 'when namespace has ancestor_inherited state' do
      let_it_be(:root_group) { create(:group) }
      let_it_be(:parent_group) { create(:group, parent: root_group) }
      let_it_be(:child_group) { create(:group, parent: parent_group) }

      before do
        child_group.update_column(:state, described_class::STATES[:ancestor_inherited])
      end

      it 'returns ancestor_inherited when no ancestors have explicit state' do
        root_group.update_column(:state, described_class::STATES[:ancestor_inherited])
        parent_group.update_column(:state, described_class::STATES[:ancestor_inherited])

        expect(child_group.effective_state).to eq(:ancestor_inherited)
      end

      it 'returns parent state when parent has explicit state' do
        root_group.update_column(:state, described_class::STATES[:ancestor_inherited])
        parent_group.update_column(:state, described_class::STATES[:archived])

        expect(child_group.effective_state).to eq(:archived)
      end

      it 'returns root ancestor state when only root has explicit state' do
        root_group.update_column(:state, described_class::STATES[:maintenance])
        parent_group.update_column(:state, described_class::STATES[:ancestor_inherited])

        expect(child_group.effective_state).to eq(:maintenance)
      end

      it 'returns closest ancestor state (parent) when multiple ancestors have explicit states' do
        root_group.update_column(:state, described_class::STATES[:maintenance])
        parent_group.update_column(:state, described_class::STATES[:archived])

        expect(child_group.effective_state).to eq(:archived)
      end

      it 'returns ancestor_inherited for top-level namespace with ancestor_inherited state' do
        root_group.update_column(:state, described_class::STATES[:ancestor_inherited])
        expect(root_group.effective_state).to eq(:ancestor_inherited)
      end

      it 'returns nil when ancestor has an invalid state value' do
        parent_group.update_column(:state, 999)
        child_group.update_column(:state, described_class::STATES[:ancestor_inherited])

        result = child_group.reload.effective_state
        expect(result).to be_nil
      end

      it 'handles deeply nested hierarchies correctly' do
        grandchild_group = create(:group, parent: child_group)
        grandchild_group.update_column(:state, described_class::STATES[:ancestor_inherited])
        root_group.update_column(:state, described_class::STATES[:transfer_in_progress])
        parent_group.update_column(:state, described_class::STATES[:ancestor_inherited])
        child_group.update_column(:state, described_class::STATES[:ancestor_inherited])

        expect(grandchild_group.effective_state).to eq(:transfer_in_progress)
      end
    end

    context 'for N+1 query prevention' do
      let_it_be(:root_group) { create(:group, state: described_class::STATES[:archived]) }

      it 'executes only one query per namespace to resolve effective_state' do
        child_groups = create_list(:group, 3,
          state: described_class::STATES[:ancestor_inherited],
          parent: root_group
        )

        queries = ActiveRecord::QueryRecorder.new do
          child_groups.each(&:effective_state)
        end

        # Should execute exactly 3 queries (one per child), not N (where N is ancestor count)
        # Each query fetches all ancestors at once via WHERE IN
        expect(queries.count).to eq(3)
      end
    end

    context 'for ordering of traversed ancestors' do
      it 'returns closest ancestor state, not based on ID ordering' do
        # The group hierarchy is such that: root.id > parent.id > child.id
        child = create(:group, state: described_class::STATES[:ancestor_inherited])
        parent = create(:group, state: described_class::STATES[:archived])
        root = create(:group, state: described_class::STATES[:maintenance])

        # Set the ancestry such that: child.traversal_ids: [root.id, parent.id, child.id]
        child.parent = parent
        parent.parent = root

        child.save!
        parent.save!

        root.reload

        expect(child.effective_state).to eq(:archived) # Parent's state, not root's
      end
    end
  end

  describe 'ancestor state validations' do
    using RSpec::Parameterized::TableSyntax

    let_it_be(:parent) { create(:group) }
    let_it_be(:child) { create(:group, parent: parent) }

    after do
      set_state(parent, :ancestor_inherited)
      set_state(child, :ancestor_inherited)
    end

    describe 'blocks transition when parent in blocking state' do
      where(:event, :child_from, :parent_state) do
        :archive           | :ancestor_inherited | :archived
        :archive           | :ancestor_inherited | :deletion_in_progress
        :archive           | :ancestor_inherited | :deletion_scheduled
        :unarchive         | :archived           | :deletion_in_progress
        :unarchive         | :archived           | :deletion_scheduled
        :schedule_deletion | :ancestor_inherited | :deletion_in_progress
        :schedule_deletion | :ancestor_inherited | :deletion_scheduled
        :schedule_deletion | :archived           | :deletion_in_progress
        :schedule_deletion | :archived           | :deletion_scheduled
      end

      with_them do
        it "prevents #{params[:event]} when parent is #{params[:parent_state]}" do
          set_state(parent, parent_state)
          set_state(child, child_from)

          expect { child.public_send(event) }.not_to change { child.reload.state_name }
          expect(child.errors[:state]).to include(match(/cannot be changed as ancestor ID \d+ is #{parent_state}/))
        end
      end
    end

    describe 'allows transition when parent in allowed state' do
      where(:event, :child_from, :child_to, :parent_state) do
        :archive           | :ancestor_inherited | :archived           | :ancestor_inherited
        :unarchive         | :archived           | :ancestor_inherited | :ancestor_inherited
        :schedule_deletion | :ancestor_inherited | :deletion_scheduled | :ancestor_inherited
        :schedule_deletion | :archived           | :deletion_scheduled | :archived
      end

      with_them do
        it "allows #{params[:event]} when parent is #{params[:parent_state]}" do
          set_state(parent, parent_state)
          set_state(child, child_from)

          expect { child.public_send(event) }
            .to change { child.reload.state_name }.from(child_from).to(child_to)
        end
      end
    end
  end

  describe '#validate_ancestors_state' do
    let_it_be(:parent) { create(:group) }
    let_it_be(:child) { create(:group, parent: parent) }

    let(:transition) do
      Struct.new(:event).new(:archive)
    end

    after do
      set_state(parent, :ancestor_inherited)
      set_state(child, :ancestor_inherited)
    end

    context 'when namespace has no ancestors' do
      it 'returns true for root namespace' do
        allow(namespace).to receive(:ancestors).and_return([])

        result = namespace.send(:validate_ancestors_state, transition)

        expect(result).to be true
      end
    end

    context 'when forbidden states list is empty' do
      it 'returns true for events with no forbidden states' do
        transition = Struct.new(:event).new(:unknown_event)

        result = child.send(:validate_ancestors_state, transition)

        expect(result).to be true
      end
    end

    context 'when no ancestor is in forbidden state' do
      it 'returns true' do
        set_state(parent, :ancestor_inherited)
        transition = Struct.new(:event).new(:archive)

        result = child.send(:validate_ancestors_state, transition)

        expect(result).to be true
      end
    end

    context 'when an ancestor is in forbidden state' do
      it 'returns false and adds error' do
        set_state(parent, :archived)
        transition = Struct.new(:event).new(:archive)

        result = child.send(:validate_ancestors_state, transition)

        expect(result).to be false
        expect(child.errors[:state]).to include(
          "cannot be changed as ancestor ID #{parent.id} is archived"
        )
      end

      it 'includes correct ancestor ID and state in error message' do
        set_state(parent, :deletion_in_progress)
        transition = Struct.new(:event).new(:unarchive)

        child.send(:validate_ancestors_state, transition)

        expect(child.errors[:state]).to include(
          "cannot be changed as ancestor ID #{parent.id} is deletion_in_progress"
        )
      end
    end
  end

  describe '#forbidden_ancestors_states_for' do
    context 'when event is :archive' do
      it 'returns forbidden states for archive event' do
        result = namespace.send(:forbidden_ancestors_states_for, :archive)

        expect(result).to match_array(%i[archived deletion_in_progress deletion_scheduled])
      end
    end

    context 'when event is :unarchive' do
      it 'returns forbidden states for unarchive event' do
        result = namespace.send(:forbidden_ancestors_states_for, :unarchive)

        expect(result).to match_array(%i[deletion_in_progress deletion_scheduled])
      end
    end

    context 'when event is :schedule_deletion' do
      it 'returns forbidden states for schedule_deletion event' do
        result = namespace.send(:forbidden_ancestors_states_for, :schedule_deletion)

        expect(result).to match_array(%i[deletion_in_progress deletion_scheduled])
      end
    end

    context 'when event is unknown' do
      it 'returns empty array for unknown events' do
        result = namespace.send(:forbidden_ancestors_states_for, :unknown_event)

        expect(result).to eq([])
      end

      it 'returns empty array for nil event' do
        result = namespace.send(:forbidden_ancestors_states_for, nil)

        expect(result).to eq([])
      end
    end
  end
end
