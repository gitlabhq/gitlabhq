# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Namespaces::Stateful::StatePreservation, feature_category: :groups_and_projects do
  using RSpec::Parameterized::TableSyntax

  let_it_be(:user) { create(:user) }
  let_it_be_with_reload(:namespace) { create(:namespace) }

  describe 'STATE_MEMORY_CONFIG constant' do
    it 'defines state memory mappings' do
      expect(described_class::STATE_MEMORY_CONFIG).to eq({
        schedule_deletion: :cancel_deletion,
        start_deletion: :reschedule_deletion,
        start_transfer: [:complete_transfer, :cancel_transfer]
      })
    end

    it 'is frozen' do
      expect(described_class::STATE_MEMORY_CONFIG).to be_frozen
    end
  end

  describe 'state preservation' do
    before do
      namespace.state = :ancestor_inherited
    end

    describe '#preserve_previous_state?' do
      subject { namespace.send(:preserve_previous_state?, event) }

      where(:event, :result) do
        :schedule_deletion | true
        :start_deletion    | true
        :archive           | false
        :cancel_deletion   | false
      end

      with_them do
        it { is_expected.to eq(result) }
      end
    end

    describe '#preserve_event_for' do
      subject { namespace.send(:preserve_event_for, restore_event) }

      where(:restore_event, :result) do
        :cancel_deletion     | :schedule_deletion
        :reschedule_deletion | :start_deletion
        :schedule_deletion   | nil
        :archive             | nil
      end

      with_them do
        it { is_expected.to eq(result) }
      end
    end

    describe '#preserved_state' do
      subject { namespace.send(:preserved_state, event_key) }

      where(:event_key, :stored_state) do
        'schedule_deletion' | :archived
        'schedule_deletion' | :ancestor_inherited
        'schedule_deletion' | nil
        'start_deletion'    | :deletion_scheduled
      end

      with_them do
        before do
          if stored_state
            namespace.namespace_details.update!(
              state_metadata: { preserved_states: { event_key => stored_state } }
            )
          end
        end

        it { is_expected.to eq(stored_state) }
      end
    end

    describe '#should_restore_to?' do
      subject { namespace.send(:should_restore_to?, event_key, target_state) }

      where(:event_key, :stored_state, :target_state, :result) do
        'schedule_deletion' | 'archived'           | :archived           | true
        'schedule_deletion' | 'ancestor_inherited' | :archived           | false
        'schedule_deletion' | 'ancestor_inherited' | :ancestor_inherited | true
        'start_deletion'    | 'deletion_scheduled' | :archived           | false
        'start_deletion'    | 'archived'           | :archived           | true
      end

      with_them do
        before do
          namespace.namespace_details.update!(
            state_metadata: { preserved_states: { event_key => stored_state } }
          )
        end

        it { is_expected.to eq(result) }
      end
    end

    describe 'restore_to helpers' do
      subject { namespace.send(restore_to_method) }

      where(:restore_to_method, :event_key, :preserved_state, :result) do
        :restore_to_archived_on_cancel_deletion?               | 'schedule_deletion' | 'archived'           | true
        :restore_to_archived_on_cancel_deletion?               | 'schedule_deletion' | 'ancestor_inherited' | false
        :restore_to_archived_on_cancel_deletion?               | 'schedule_deletion' | nil                  | false
        :restore_to_archived_on_reschedule_deletion?           | 'start_deletion'    | 'archived'           | true
        :restore_to_archived_on_reschedule_deletion?           | 'start_deletion'    | 'deletion_scheduled' | false
        :restore_to_archived_on_reschedule_deletion?           | 'start_deletion'    | nil                  | false
        :restore_to_ancestor_inherited_on_reschedule_deletion? | 'start_deletion'    | 'ancestor_inherited' | true
        :restore_to_ancestor_inherited_on_reschedule_deletion? | 'start_deletion'    | 'deletion_scheduled' | false
        :restore_to_ancestor_inherited_on_reschedule_deletion? | 'start_deletion'    | nil                  | false
        :restore_to_deletion_scheduled_on_reschedule_deletion? | 'start_deletion'    | 'deletion_scheduled' | true
        :restore_to_deletion_scheduled_on_reschedule_deletion? | 'start_deletion'    | 'ancestor_inherited' | false
        :restore_to_deletion_scheduled_on_reschedule_deletion? | 'start_deletion'    | nil                  | false
      end

      with_them do
        before do
          if preserved_state
            namespace.namespace_details.update!(
              state_metadata: { preserved_states: { event_key => preserved_state } }
            )
          end
        end

        it { is_expected.to eq(result) }
      end
    end

    describe 'state preservation workflow' do
      describe 'preserves state on transition' do
        subject { namespace.namespace_details.state_metadata['preserved_states'][event.to_s] }

        where(:initial_state, :event) do
          :archived           | :schedule_deletion
          :deletion_scheduled | :start_deletion
          :ancestor_inherited | :start_deletion
        end

        with_them do
          before do
            namespace.state = initial_state
            namespace.send(:"#{event}!", transition_user: user)
            namespace.namespace_details.reload
          end

          it { is_expected.to eq(initial_state.to_s) }
        end
      end

      describe 'restores state on transition' do
        subject { namespace.state_name }

        where(:initial_state, :preserved_key, :preserved_state) do
          :deletion_scheduled   | :schedule_deletion | :archived
          :deletion_scheduled   | :schedule_deletion | :ancestor_inherited
          :deletion_in_progress | :start_deletion    | :deletion_scheduled
          :deletion_in_progress | :start_deletion    | :ancestor_inherited
          :deletion_in_progress | :start_deletion    | :archived
        end

        with_them do
          let(:restore_event) { described_class::STATE_MEMORY_CONFIG[preserved_key] }

          before do
            namespace.state = initial_state
            namespace.namespace_details.update!(
              state_metadata: { preserved_states: { preserved_key => preserved_state } }
            )
            namespace.send(:"#{restore_event}!")
          end

          it { is_expected.to eq(preserved_state) }
        end
      end

      describe 'clearing preserved states' do
        before do
          namespace.state = :deletion_scheduled
          namespace.namespace_details.update_column(:state_metadata, {
            'preserved_states' => preserved_states
          })

          namespace.cancel_deletion!
          namespace.namespace_details.reload
        end

        let(:metadata) { namespace.namespace_details.state_metadata }

        context 'when other preserved states exist' do
          let(:preserved_states) do
            {
              'schedule_deletion' => 'archived',
              'start_deletion' => 'deletion_scheduled'
            }
          end

          it 'clears only the specific preserved state' do
            expect(metadata['preserved_states']).not_to have_key('schedule_deletion')
            expect(metadata['preserved_states']['start_deletion']).to eq('deletion_scheduled')
          end
        end

        context 'when it was the only preserved state' do
          let(:preserved_states) { { 'schedule_deletion' => 'archived' } }

          it 'clears preserved state entirely' do
            expect(metadata['preserved_states']).to be_nil
          end
        end
      end

      describe 'transitions history', :freeze_time do
        context 'for state preservation through the deletion lifecycle' do
          where(:initial_state) do
            [:archived, :ancestor_inherited]
          end

          with_them do
            it 'preserves state through schedule -> start -> cancel cycle' do
              namespace.update!(state: initial_state)

              namespace.schedule_deletion(transition_user: user)
              expect(namespace.state_name).to eq(:deletion_scheduled)
              expect(namespace.state_metadata.dig('preserved_states', 'schedule_deletion')).to eq(initial_state.to_s)
              expect(namespace.namespace_details.reload.deletion_scheduled_by_user_id).to eq(user.id)
              expect(namespace.namespace_details.reload.deletion_scheduled_at).to eq(Time.current)

              namespace.start_deletion(transition_user: user)
              expect(namespace.state_name).to eq(:deletion_in_progress)
              expect(namespace.state_metadata.dig('preserved_states', 'start_deletion')).to eq('deletion_scheduled')

              namespace.cancel_deletion(transition_user: user)
              expect(namespace.state_name).to eq(initial_state)
              expect(namespace.state_metadata.dig('preserved_states', 'schedule_deletion')).to be_nil
              expect(namespace.namespace_details.reload.deletion_scheduled_by_user_id).to be_nil
              expect(namespace.namespace_details.reload.deletion_scheduled_at).to be_nil
            end
          end
        end

        context 'for state preservation through the reschedule lifecycle' do
          where(:initial_state) do
            [:deletion_scheduled, :ancestor_inherited]
          end

          with_them do
            it 'preserves state through start -> reschedule cycle' do
              namespace.update!(state: initial_state)

              namespace.start_deletion(transition_user: user)
              expect(namespace.state_name).to eq(:deletion_in_progress)
              expect(namespace.state_metadata.dig('preserved_states', 'start_deletion')).to eq(initial_state.to_s)

              namespace.reschedule_deletion(transition_user: user)
              expect(namespace.state_name).to eq(initial_state)
              expect(namespace.state_metadata.dig('preserved_states', 'start_deletion')).to be_nil
            end
          end
        end
      end
    end
  end
end
