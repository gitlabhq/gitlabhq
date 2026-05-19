# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::TenantContainerLifecycle::Stateful::TransitionCallbacks, feature_category: :organization do
  using RSpec::Parameterized::TableSyntax

  let_it_be(:user) { create(:user) }
  let_it_be_with_refind(:organization) { create(:organization) }

  describe '#update_state_metadata' do
    where(:initial_state, :event, :args) do
      :active               | :schedule_deletion  | ref(:user_args)
      :deletion_scheduled   | :start_deletion     | {}
      :deletion_in_progress | :reschedule_deletion | {}
      :deletion_scheduled   | :cancel_deletion    | {}
      :deletion_in_progress | :cancel_deletion    | {}
    end

    let(:user_args) { { transition_user: user } }

    with_them do
      before do
        organization.update_column(:state, Organizations::Organization.states[initial_state.to_s])
      end

      it 'updates state_metadata on successful transition' do
        organization.public_send(event, **args)

        metadata = organization.organization_detail.reload.state_metadata

        expect(metadata['last_changed_by_user_id']).to eq(args[:transition_user]&.id)
        expect(metadata['last_updated_at']).to be_present
        expect(metadata['last_error']).to be_nil
      end
    end

    it 'allows nil transition_user' do
      organization.update_column(:state, Organizations::Organization.states['deletion_scheduled'])
      organization.start_deletion!

      metadata = organization.organization_detail.reload.state_metadata

      expect(metadata['last_changed_by_user_id']).to be_nil
    end
  end

  describe '#set_deletion_schedule_data', :freeze_time do
    it 'sets deletion_scheduled_at and deletion_scheduled_by_user_id on successful schedule_deletion' do
      organization.schedule_deletion!(transition_user: user)

      organization_detail = organization.organization_detail.reload

      expect(organization_detail.deletion_scheduled_at).to eq(Time.current)
      expect(organization_detail.state_metadata['deletion_scheduled_by_user_id']).to eq(user.id)
    end
  end

  describe '#clear_deletion_schedule_data' do
    shared_examples 'clears deletion schedule data' do
      it 'clears deletion_scheduled_at and deletion_scheduled_by_user_id on successful cancel_deletion' do
        organization.cancel_deletion!

        organization_detail = organization.organization_detail.reload

        expect(organization_detail.deletion_scheduled_at).to be_nil
        expect(organization_detail.state_metadata['deletion_scheduled_by_user_id']).to be_nil
      end
    end

    context 'when cancelling from deletion_scheduled' do
      before do
        organization.schedule_deletion!(transition_user: user)
      end

      include_examples 'clears deletion schedule data'
    end

    context 'when cancelling from deletion_in_progress' do
      before do
        organization.schedule_deletion!(transition_user: user)
        organization.start_deletion!
      end

      include_examples 'clears deletion schedule data'
    end
  end

  describe '#set_deletion_error_data' do
    before do
      organization.schedule_deletion!(transition_user: user)
      organization.start_deletion!
    end

    it 'sets deletion_error when provided in transition args' do
      organization.reschedule_deletion!(deletion_error: 'Worker failed: timeout')

      expect(organization.organization_detail.reload.deletion_error).to eq('Worker failed: timeout')
    end

    it 'does not set deletion_error when not provided' do
      organization.reschedule_deletion!

      expect(organization.organization_detail.reload.deletion_error).to be_nil
    end

    it 'does not set deletion_error when provided as empty string' do
      organization.reschedule_deletion!(deletion_error: '')

      expect(organization.organization_detail.reload.deletion_error).to be_nil
    end
  end

  describe '#update_state_metadata_on_failure' do
    it 'records an error and saves state_metadata when transition is invalid' do
      organization.cancel_deletion(transition_user: user)

      metadata = organization.organization_detail.reload.state_metadata

      expect(metadata['last_changed_by_user_id']).to eq(user.id)
      expect(metadata['last_updated_at']).to be_present
      expect(metadata['last_error']).to include('Cannot transition from')
    end
  end

  describe '#stateful_detail' do
    it 'raises NotImplementedError when not overridden' do
      klass = Class.new { include Gitlab::TenantContainerLifecycle::Stateful::TransitionCallbacks }

      expect { klass.new.send(:stateful_detail) }
        .to raise_error(NotImplementedError, /stateful_detail must be implemented/)
    end
  end

  describe '#build_transition_error_message' do
    let(:base_message) { 'Cannot transition from active to active via cancel_deletion' }
    let(:transition) do
      instance_double(StateMachines::Transition, from_name: :active, to_name: :active, event: :cancel_deletion)
    end

    it 'includes state errors when present' do
      organization.errors.add(:state, 'is invalid')
      organization.errors.add(:state, 'requires admin')

      message = organization.send(:build_transition_error_message, transition)

      expect(message).to eq("#{base_message}: is invalid, requires admin")
    end

    it 'falls back to unknown reason when no state errors are present' do
      message = organization.send(:build_transition_error_message, transition)

      expect(message).to eq("#{base_message}: unknown reason")
    end
  end
end
