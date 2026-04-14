# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Namespaces::Stateful::TransitionCallbacks, feature_category: :groups_and_projects do
  using RSpec::Parameterized::TableSyntax

  let_it_be(:user) { create(:user) }
  let_it_be_with_refind(:namespace) { create(:group) }

  describe '#update_state_metadata' do
    where(:initial_state, :transition) do
      :ancestor_inherited   | :archive
      :archived             | :unarchive
      :ancestor_inherited   | :schedule_deletion
      :archived             | :schedule_deletion
      :deletion_scheduled   | :start_deletion
      :deletion_in_progress | :reschedule_deletion
      :deletion_scheduled   | :cancel_deletion
      :deletion_in_progress | :cancel_deletion
    end

    with_them do
      before do
        namespace.update!(state: initial_state)
      end

      it "updates state_metadata on successful transition" do
        namespace.public_send(transition, transition_user: user)

        metadata = namespace.reload.state_metadata

        expect(metadata['last_changed_by_user_id']).to eq(user.id)
        expect(metadata['last_updated_at']).to be_present
        expect(metadata['last_error']).to be_nil
      end
    end

    it 'allows nil transition_user' do
      namespace.archive!

      metadata = namespace.reload.state_metadata

      expect(metadata['last_changed_by_user_id']).to be_nil
    end
  end

  describe '#set_deletion_schedule_data', :freeze_time do
    where(:initial_state) { %i[ancestor_inherited archived] }

    with_them do
      before do
        namespace.update!(state: initial_state)
      end

      it 'sets deletion schedule data on successful transition' do
        namespace.schedule_deletion!(transition_user: user)

        namespace.reload
        metadata = namespace.state_metadata

        expect(namespace.deletion_scheduled_at).to eq(Time.current)
        expect(metadata['deletion_scheduled_by_user_id']).to eq(user.id)
      end
    end
  end

  describe '#set_deletion_error_data' do
    before do
      namespace.update!(state: :deletion_in_progress)
    end

    it 'sets deletion_error when provided in transition args' do
      namespace.reschedule_deletion!(transition_user: user, deletion_error: 'Test error message')

      expect(namespace.reload.deletion_error).to eq('Test error message')
    end

    it 'does not set deletion_error when not provided' do
      namespace.reschedule_deletion!(transition_user: user)

      expect(namespace.reload.deletion_error).to be_nil
    end

    it 'does not set deletion_error when provided as empty string' do
      namespace.reschedule_deletion!(transition_user: user, deletion_error: '')

      expect(namespace.reload.deletion_error).to be_nil
    end
  end

  describe '#clear_deletion_schedule_data' do
    where(:initial_state) { %i[deletion_scheduled deletion_in_progress] }

    with_them do
      before do
        namespace.update!(state: initial_state)
        namespace.update!(deletion_scheduled_at: 1.day.ago)
        namespace.state_metadata[:deletion_scheduled_by_user_id] = user.id
        namespace.namespace_details.save!
      end

      it 'clears deletion schedule data on successful transition' do
        namespace.cancel_deletion!(transition_user: user)

        namespace.reload

        expect(namespace.deletion_scheduled_at).to be_nil
        expect(namespace.state_metadata['deletion_scheduled_by_user_id']).to be_nil
      end
    end
  end

  describe '#set_transfer_schedule_data', :freeze_time do
    where(:initial_state) { %i[ancestor_inherited archived] }

    with_them do
      before do
        namespace.update!(state: initial_state)
      end

      it 'sets transfer schedule data on successful transition' do
        namespace.schedule_transfer!(transition_user: user)

        namespace.reload
        metadata = namespace.state_metadata

        expect(metadata['transfer_scheduled_at']).to eq(Time.current.as_json)
        expect(metadata['transfer_scheduled_by_user_id']).to eq(user.id)
      end
    end
  end

  describe '#clear_transfer_data' do
    where(:initial_state, :event) do
      :transfer_scheduled   | :cancel_transfer
      :transfer_in_progress | :cancel_transfer
      :transfer_in_progress | :complete_transfer
    end

    with_them do
      before do
        namespace.update!(state: initial_state)
        namespace.state_metadata.merge!(
          transfer_scheduled_at: 1.day.ago.as_json,
          transfer_scheduled_by_user_id: user.id,
          transfer_initiated_at: 1.day.ago.as_json,
          transfer_initiated_by_user_id: user.id,
          transfer_target_parent_id: 123,
          transfer_attempt_count: 1,
          transfer_last_error: 'some error'
        )
        namespace.namespace_details.save!
      end

      it 'clears all transfer data on successful transition' do
        namespace.public_send(:"#{event}!", transition_user: user)

        namespace.reload
        metadata = namespace.state_metadata

        expect(metadata['transfer_scheduled_at']).to be_nil
        expect(metadata['transfer_scheduled_by_user_id']).to be_nil
        expect(metadata['transfer_initiated_at']).to be_nil
        expect(metadata['transfer_initiated_by_user_id']).to be_nil
        expect(metadata['transfer_target_parent_id']).to be_nil
        expect(metadata['transfer_attempt_count']).to be_nil
        expect(metadata['transfer_last_error']).to be_nil
      end
    end
  end

  describe '#update_state_metadata_on_failure' do
    before do
      namespace.update!(state: :archived)
    end

    it 'includes state errors when present' do
      namespace.archive(transition_user: user)

      metadata = namespace.reload.state_metadata

      expect(metadata['last_changed_by_user_id']).to eq(user.id)
      expect(metadata['last_updated_at']).to be_present
      expect(metadata['last_error']).to be_present
      expect(metadata['last_error']).to include("Cannot transition from")
    end
  end

  describe '#build_transition_error_message' do
    let(:base_message) { 'Cannot transition from ancestor_inherited to archived via archive' }
    let(:transition) do
      instance_double(StateMachines::Transition, from_name: :ancestor_inherited, to_name: :archived, event: :archive)
    end

    it 'includes state errors when present' do
      namespace.errors.add(:state, 'is invalid')
      namespace.errors.add(:state, 'requires admin')

      message = namespace.send(:build_transition_error_message, transition)

      expect(message).to eq("#{base_message}: is invalid, requires admin")
    end

    it 'includes unknown reason when no state errors' do
      message = namespace.send(:build_transition_error_message, transition)

      expect(message).to eq("#{base_message}: unknown reason")
    end
  end
end
