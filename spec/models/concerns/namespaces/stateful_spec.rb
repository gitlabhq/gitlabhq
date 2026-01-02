# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Namespaces::Stateful, feature_category: :groups_and_projects do
  using RSpec::Parameterized::TableSyntax
  include Namespaces::StatefulHelpers

  let_it_be(:user) { create(:user) }
  let_it_be_with_reload(:namespace) { create(:namespace) }

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

    describe 'state values' do
      described_class::STATES.each do |state_name, state_value|
        it { is_expected.to have_state state_name.to_sym, value: state_value }
      end
    end

    describe 'event handling' do
      it { is_expected.to handle_events :archive, when: :ancestor_inherited }
      it { is_expected.to handle_events :unarchive, when: :archived }
      it { is_expected.to handle_events :unarchive, when: :ancestor_inherited }
      it { is_expected.to handle_events :schedule_deletion, when: :ancestor_inherited }
      it { is_expected.to handle_events :schedule_deletion, when: :archived }
      it { is_expected.to handle_events :start_deletion, when: :ancestor_inherited }
      it { is_expected.to handle_events :start_deletion, when: :archived }
      it { is_expected.to handle_events :start_deletion, when: :deletion_scheduled }
      it { is_expected.to handle_events :reschedule_deletion, when: :deletion_in_progress }
      it { is_expected.to handle_events :reschedule_deletion, when: :ancestor_inherited }
      it { is_expected.to handle_events :cancel_deletion, when: :deletion_scheduled }
      it { is_expected.to handle_events :cancel_deletion, when: :deletion_in_progress }
      it { is_expected.to handle_events :cancel_deletion, when: :ancestor_inherited }
      it { is_expected.to reject_events :archive, when: :archived }
      it { is_expected.to reject_events :schedule_deletion, when: :deletion_scheduled }
    end

    describe 'transitions' do
      where(:event, :from_state, :to_state) do
        :archive             | :ancestor_inherited   | :archived
        :unarchive           | :archived             | :ancestor_inherited
        :schedule_deletion   | :ancestor_inherited   | :deletion_scheduled
        :schedule_deletion   | :archived             | :deletion_scheduled
        :start_deletion      | :ancestor_inherited   | :deletion_in_progress
        :start_deletion      | :archived             | :deletion_in_progress
        :start_deletion      | :deletion_scheduled   | :deletion_in_progress
        :reschedule_deletion | :deletion_in_progress | :deletion_scheduled
        :reschedule_deletion | :ancestor_inherited   | :deletion_scheduled
      end

      with_them do
        before do
          namespace.state = described_class::STATES[from_state.to_s]
        end

        it "transitions from #{params[:from_state]} to #{params[:to_state]} on #{params[:event]}" do
          expect { namespace.public_send(event, transition_user: user) }
            .to change { namespace.state_name }
                  .from(from_state)
                  .to(to_state)
        end

        it 'updates state_metadata with user and timestamp' do
          freeze_time do
            namespace.public_send(event, transition_user: user)
            metadata = namespace.namespace_details.reload.state_metadata

            expect(metadata).to include(
              'last_changed_by_user_id' => user.id,
              'last_error' => nil
            )
            expect(metadata['last_updated_at']).to be_present
          end
        end
      end

      context 'for transitions with state preservation' do
        where(:event, :from_state, :preserve_event, :preserved_state) do
          :cancel_deletion     | :deletion_scheduled   | :schedule_deletion | :ancestor_inherited
          :cancel_deletion     | :deletion_scheduled   | :schedule_deletion | :archived
          :cancel_deletion     | :deletion_in_progress | :schedule_deletion | :ancestor_inherited
          :cancel_deletion     | :deletion_in_progress | :schedule_deletion | :archived
          :reschedule_deletion | :deletion_in_progress | :start_deletion    | :ancestor_inherited
          :reschedule_deletion | :deletion_in_progress | :start_deletion    | :archived
          :reschedule_deletion | :deletion_in_progress | :start_deletion    | :deletion_scheduled
        end

        with_them do
          before do
            set_state(namespace, from_state)
            namespace.namespace_details.update!(
              state_metadata: {
                preserved_states: {
                  preserve_event.to_s => preserved_state.to_s
                }
              }
            )
          end

          it "transitions from #{params[:from_state]} to #{params[:preserved_state]} on #{params[:event]}" do
            expect { namespace.public_send(event, transition_user: user) }
              .to change { namespace.state_name }
                    .from(from_state)
                    .to(preserved_state)
          end
        end
      end
    end

    describe 'system-triggered transitions' do
      it 'updates state_metadata without user' do
        freeze_time do
          namespace.archive
          metadata = namespace.namespace_details.reload.state_metadata

          expect(metadata).to include(
            'last_changed_by_user_id' => nil,
            'last_error' => nil
          )
          expect(metadata['last_updated_at']).to be_present
        end
      end
    end

    describe 'rejected transitions' do
      where(:event, :current_state) do
        :archive             | :archived
        :archive             | :deletion_scheduled
        :archive             | :deletion_in_progress
        :archive             | :creation_in_progress
        :archive             | :transfer_in_progress
        :archive             | :maintenance
        :unarchive           | :deletion_scheduled
        :unarchive           | :deletion_in_progress
        :unarchive           | :creation_in_progress
        :unarchive           | :transfer_in_progress
        :unarchive           | :maintenance
        :schedule_deletion   | :deletion_scheduled
        :schedule_deletion   | :deletion_in_progress
        :schedule_deletion   | :creation_in_progress
        :schedule_deletion   | :transfer_in_progress
        :schedule_deletion   | :maintenance
        :start_deletion      | :deletion_in_progress
        :start_deletion      | :creation_in_progress
        :start_deletion      | :transfer_in_progress
        :start_deletion      | :maintenance
        :reschedule_deletion | :archived
        :reschedule_deletion | :deletion_scheduled
        :reschedule_deletion | :creation_in_progress
        :reschedule_deletion | :transfer_in_progress
        :reschedule_deletion | :maintenance
        :cancel_deletion     | :archived
        :cancel_deletion     | :creation_in_progress
        :cancel_deletion     | :transfer_in_progress
        :cancel_deletion     | :maintenance
      end

      with_them do
        it "does not transition from #{params[:current_state]} on #{params[:event]}" do
          namespace.state = described_class::STATES[current_state.to_s]

          expect { namespace.public_send(event, transition_user: user) }
            .not_to change { namespace.state_name }
        end
      end
    end
  end
end
