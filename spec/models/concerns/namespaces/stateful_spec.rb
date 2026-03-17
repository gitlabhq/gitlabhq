# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Namespaces::Stateful, feature_category: :groups_and_projects do
  using RSpec::Parameterized::TableSyntax

  let_it_be(:user) { create(:user) }
  let_it_be_with_reload(:namespace) { create(:namespace) }
  let_it_be(:states) { Namespace.states }

  describe 'enums' do
    subject { namespace }

    it { is_expected.to define_enum_for(:state).with_values(**states).without_instance_methods }
  end

  describe 'NULL and zero handling during migration' do
    describe 'state reading' do
      where(:db_value) do
        [nil, 0]
      end

      with_them do
        it "treats #{params[:db_value].inspect} state as ancestor_inherited" do
          namespace.update_column(:state, db_value)
          namespace.reload

          expect(namespace.state).to eq('ancestor_inherited')
          expect(namespace.state_name).to eq(:ancestor_inherited)
        end
      end
    end

    describe 'transitions from ancestor_inherited' do
      where(:db_value, :event, :to_state) do
        nil | :archive           | :archived
        nil | :schedule_deletion | :deletion_scheduled
        nil | :start_deletion    | :deletion_in_progress
        0   | :archive           | :archived
        0   | :schedule_deletion | :deletion_scheduled
        0   | :start_deletion    | :deletion_in_progress
      end

      with_them do
        before do
          namespace.update_column(:state, db_value)
          namespace.reload
        end

        it "transitions from #{params[:db_value].inspect} to #{params[:to_state]} on #{params[:event]}" do
          expect { namespace.public_send(event, transition_user: user) }
            .to change { namespace.state_name }
                  .from(:ancestor_inherited)
                  .to(to_state)
        end
      end
    end

    describe 'transitions back to ancestor_inherited write 0 instead of NULL' do
      it 'writes 0 to the database when transitioning to ancestor_inherited' do
        namespace.update!(state: :archived)

        namespace.unarchive

        raw_state = Namespace.where(id: namespace.id).first.state_before_type_cast
        expect(raw_state).to eq(0)
      end
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
      Namespace.states.each_key do |state_name|
        it { is_expected.to have_state state_name.to_sym, value: state_name }
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
      it { is_expected.to handle_events :start_transfer, when: :ancestor_inherited }
      it { is_expected.to handle_events :start_transfer, when: :archived }
      it { is_expected.to handle_events :complete_transfer, when: :transfer_in_progress }
      it { is_expected.to handle_events :cancel_transfer, when: :transfer_in_progress }
      it { is_expected.to reject_events :archive, when: :archived }
      it { is_expected.to reject_events :schedule_deletion, when: :deletion_scheduled }
      it { is_expected.to reject_events :start_transfer, when: :transfer_in_progress }
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
        :start_transfer      | :ancestor_inherited   | :transfer_in_progress
        :start_transfer      | :archived             | :transfer_in_progress
        :complete_transfer   | :transfer_in_progress | :ancestor_inherited
        :cancel_transfer     | :transfer_in_progress | :ancestor_inherited
      end

      with_them do
        before do
          namespace.state = from_state
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
          :complete_transfer   | :transfer_in_progress | :start_transfer    | :ancestor_inherited
          :complete_transfer   | :transfer_in_progress | :start_transfer    | :archived
          :cancel_transfer     | :transfer_in_progress | :start_transfer    | :archived
        end

        with_them do
          before do
            namespace.update!(state: from_state)
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
        :start_transfer      | :deletion_scheduled
        :start_transfer      | :deletion_in_progress
        :start_transfer      | :creation_in_progress
        :start_transfer      | :transfer_in_progress
        :start_transfer      | :maintenance
        :complete_transfer   | :ancestor_inherited
        :complete_transfer   | :archived
        :complete_transfer   | :deletion_scheduled
        :complete_transfer   | :deletion_in_progress
        :complete_transfer   | :creation_in_progress
        :complete_transfer   | :maintenance
        :cancel_transfer     | :ancestor_inherited
        :cancel_transfer     | :archived
        :cancel_transfer     | :deletion_scheduled
        :cancel_transfer     | :deletion_in_progress
        :cancel_transfer     | :creation_in_progress
        :cancel_transfer     | :maintenance
      end

      with_them do
        it "does not transition from #{params[:current_state]} on #{params[:event]}" do
          namespace.state = current_state

          expect { namespace.public_send(event, transition_user: user) }
            .not_to change { namespace.state_name }
        end
      end
    end
  end
end
