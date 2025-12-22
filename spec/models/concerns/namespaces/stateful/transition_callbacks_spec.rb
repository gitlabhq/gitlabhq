# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Namespaces::Stateful::TransitionCallbacks, feature_category: :groups_and_projects do
  include Namespaces::StatefulHelpers
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
        set_state(namespace, initial_state)
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
        set_state(namespace, initial_state)
      end

      it 'sets deletion schedule data on successful transition' do
        namespace.schedule_deletion!(transition_user: user)

        metadata = namespace.reload.state_metadata

        expect(metadata['deletion_scheduled_at']).to eq(Time.current.as_json)
        expect(metadata['deletion_scheduled_by_user_id']).to eq(user.id)
      end
    end
  end

  describe '#clear_deletion_schedule_data' do
    where(:initial_state) { %i[deletion_scheduled deletion_in_progress] }

    with_them do
      before do
        set_state(namespace, initial_state)
        namespace.state_metadata.merge!(
          deletion_scheduled_at: 1.day.ago.as_json,
          deletion_scheduled_by_user_id: user.id
        )
        namespace.namespace_details.save!
      end

      it 'clears deletion schedule data on successful transition' do
        namespace.cancel_deletion!(transition_user: user)

        metadata = namespace.reload.state_metadata

        expect(metadata['deletion_scheduled_at']).to be_nil
        expect(metadata['deletion_scheduled_by_user_id']).to be_nil
      end
    end
  end

  describe '#update_state_metadata_on_failure' do
    before do
      set_state(namespace, :archived)
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
