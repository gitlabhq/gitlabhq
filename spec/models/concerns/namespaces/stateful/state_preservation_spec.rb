# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Namespaces::Stateful::StatePreservation, feature_category: :groups_and_projects do
  include Namespaces::StatefulHelpers

  let_it_be(:user) { create(:user) }
  let_it_be_with_reload(:namespace) { create(:namespace) }

  describe 'STATE_MEMORY_CONFIG constant' do
    it 'defines state memory mappings' do
      expect(described_class::STATE_MEMORY_CONFIG).to eq({
        schedule_deletion: :cancel_deletion
      })
    end

    it 'is frozen' do
      expect(described_class::STATE_MEMORY_CONFIG).to be_frozen
    end
  end

  describe 'state preservation' do
    before do
      namespace.state = Namespaces::Stateful::STATES[:ancestor_inherited]
    end

    describe '#preserve_previous_state?' do
      it 'returns true for events that preserve state' do
        result = namespace.send(:preserve_previous_state?, :schedule_deletion)
        expect(result).to be true
      end

      it 'returns false for events that do not preserve state' do
        result = namespace.send(:preserve_previous_state?, :archive)
        expect(result).to be false
      end
    end

    describe '#preserved_state' do
      it 'returns the preserved state for an event' do
        namespace.namespace_details.update!(
          state_metadata: {
            preserved_states: {
              'schedule_deletion' => 'archived'
            }
          }
        )

        result = namespace.send(:preserved_state, :schedule_deletion)
        expect(result).to eq(:archived)
      end

      it 'returns nil when no preserved state exists' do
        result = namespace.send(:preserved_state, :schedule_deletion)
        expect(result).to be_nil
      end
    end

    describe '#should_restore_to?' do
      it 'returns true when preserved state matches target' do
        namespace.namespace_details.update!(
          state_metadata: {
            preserved_states: {
              'schedule_deletion' => 'archived'
            }
          }
        )

        result = namespace.send(:should_restore_to?, :schedule_deletion, :archived)
        expect(result).to be true
      end

      it 'returns false when preserved state does not match target' do
        namespace.namespace_details.update!(
          state_metadata: {
            preserved_states: {
              'schedule_deletion' => 'ancestor_inherited'
            }
          }
        )

        result = namespace.send(:should_restore_to?, :schedule_deletion, :archived)
        expect(result).to be false
      end
    end

    describe '#restore_to_archived?' do
      it 'returns true when schedule_deletion preserved archived state' do
        namespace.namespace_details.update!(
          state_metadata: {
            preserved_states: {
              'schedule_deletion' => 'archived'
            }
          }
        )

        result = namespace.send(:restore_to_archived?)
        expect(result).to be true
      end

      it 'returns false when schedule_deletion preserved ancestor_inherited state' do
        namespace.namespace_details.update!(
          state_metadata: {
            preserved_states: {
              'schedule_deletion' => 'ancestor_inherited'
            }
          }
        )

        result = namespace.send(:restore_to_archived?)
        expect(result).to be false
      end
    end

    describe 'state preservation workflow' do
      it 'preserves state when scheduling deletion from archived' do
        namespace.state = Namespaces::Stateful::STATES[:archived]
        namespace.schedule_deletion!(transition_user: user)

        namespace.namespace_details.reload
        metadata = namespace.namespace_details.state_metadata

        expect(metadata['preserved_states']['schedule_deletion']).to eq('archived')
      end

      it 'restores to archived when canceling deletion' do
        namespace.state = Namespaces::Stateful::STATES[:deletion_scheduled]
        namespace.namespace_details.update!(
          state_metadata: {
            preserved_states: {
              'schedule_deletion' => 'archived'
            }
          }
        )

        namespace.cancel_deletion!

        expect(namespace.state_name).to eq(:archived)
      end

      it 'restores to ancestor_inherited when canceling deletion without preserved archived state' do
        namespace.state = Namespaces::Stateful::STATES[:deletion_scheduled]
        namespace.namespace_details.update!(
          state_metadata: {
            preserved_states: {
              'schedule_deletion' => 'ancestor_inherited'
            }
          }
        )

        namespace.cancel_deletion!

        expect(namespace.state_name).to eq(:ancestor_inherited)
      end

      it 'clears only the specific preserved state when other preserved states exist' do
        namespace.state = Namespaces::Stateful::STATES[:deletion_scheduled]
        namespace.namespace_details.update_column(:state_metadata, {
          'preserved_states' => {
            'schedule_deletion' => 'archived',
            'other_event' => 'some_state'
          }
        })
        # rubocop:disable RSpec/AnyInstanceOf -- Not the next instance
        allow_any_instance_of(JsonSchemaValidator).to receive(:validate).and_return(true)
        # rubocop:enable RSpec/AnyInstanceOf

        namespace.cancel_deletion!

        namespace.namespace_details.reload
        metadata = namespace.namespace_details.state_metadata

        expect(metadata['preserved_states']).not_to have_key('schedule_deletion')
        expect(metadata['preserved_states']['other_event']).to eq('some_state')
      end

      it 'clears preserved state entirely when it was the only preserved state' do
        namespace.state = Namespaces::Stateful::STATES[:deletion_scheduled]
        namespace.namespace_details.update!(
          state_metadata: {
            preserved_states: {
              'schedule_deletion' => 'archived'
            }
          }
        )

        namespace.cancel_deletion!

        namespace.namespace_details.reload
        metadata = namespace.namespace_details.state_metadata

        expect(metadata['preserved_states']).to be_nil
      end

      describe 'transitions history', :freeze_time do
        context 'for state preservation through the deletion lifecycle' do
          shared_examples 'preserves state through deletion cycle' do |initial_state|
            it "preserves #{initial_state} state through schedule -> start -> cancel cycle" do
              set_state(namespace, initial_state)

              # Schedule deletion
              namespace.schedule_deletion(transition_user: user)
              expect(namespace.state_name).to eq(:deletion_scheduled)
              expect(namespace.state_metadata.dig('preserved_states', 'schedule_deletion')).to eq(initial_state.to_s)
              expect(namespace.namespace_details.deletion_scheduled_by_user_id).to eq(user.id)
              expect(namespace.namespace_details.deletion_scheduled_at).to eq(Time.current)

              # Start deletion
              namespace.start_deletion(transition_user: user)
              expect(namespace.state_name).to eq(:deletion_in_progress)

              # Cancel deletion - should restore original state
              namespace.cancel_deletion(transition_user: user)
              expect(namespace.state_name).to eq(initial_state)
              expect(namespace.state_metadata['preserved_states']).to be_nil
              expect(namespace.namespace_details.deletion_scheduled_by_user_id).to be_nil
              expect(namespace.namespace_details.deletion_scheduled_at).to be_nil
            end
          end

          it_behaves_like 'preserves state through deletion cycle', :archived
          it_behaves_like 'preserves state through deletion cycle', :ancestor_inherited
        end
      end
    end
  end
end
