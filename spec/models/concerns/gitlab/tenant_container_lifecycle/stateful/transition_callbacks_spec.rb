# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::TenantContainerLifecycle::Stateful::TransitionCallbacks, feature_category: :organization do
  using RSpec::Parameterized::TableSyntax

  let_it_be(:user) { create(:user) }
  let_it_be_with_refind(:organization) { create(:organization) }

  describe '#update_state_metadata' do
    where(:initial_state, :event, :args) do
      :active       | :soft_delete | ref(:user_args)
      :soft_deleted | :hard_delete | ref(:user_args)
      :confirmed    | :activate    | {}
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
      organization.update_column(:state, Organizations::Organization.states['confirmed'])
      organization.activate!

      metadata = organization.organization_detail.reload.state_metadata

      expect(metadata['last_changed_by_user_id']).to be_nil
    end
  end

  describe '#update_state_metadata_on_failure' do
    it 'records an error and saves state_metadata when transition is invalid' do
      organization.restore(transition_user: user)

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
    let(:base_message) { 'Cannot transition from active to active via restore' }
    let(:transition) do
      instance_double(StateMachines::Transition, from_name: :active, to_name: :active, event: :restore)
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
