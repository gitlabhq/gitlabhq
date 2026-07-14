# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::TenantContainerLifecycle::Stateful::TransitionLogging, feature_category: :organization do
  let_it_be(:user) { create(:user) }
  let_it_be_with_reload(:organization) { create(:organization) }

  describe '#stateful_log_metadata' do
    it 'raises NotImplementedError when not overridden' do
      klass = Class.new { include Gitlab::TenantContainerLifecycle::Stateful::TransitionLogging }

      expect { klass.new.send(:stateful_log_metadata) }
        .to raise_error(NotImplementedError, /stateful_log_metadata must be implemented/)
    end
  end

  it 'logs successful state transitions with a user' do
    expect(Gitlab::AppLogger).to receive(:info).with(
      hash_including(
        message: 'Organization state transition',
        organization_id: organization.id,
        from_state: :active,
        to_state: :soft_deleted,
        event: :soft_delete,
        Labkit::Fields::GL_USER_ID => user.id
      )
    )

    organization.soft_delete!(transition_user: user)
  end

  it 'logs successful state transitions without a user' do
    organization.update_column(:state, Organizations::Organization.states['confirmed'])

    expect(Gitlab::AppLogger).to receive(:info).with(
      hash_including(
        message: 'Organization state transition',
        organization_id: organization.id,
        from_state: :confirmed,
        to_state: :active,
        event: :activate,
        Labkit::Fields::GL_USER_ID => nil
      )
    )

    organization.activate!
  end

  it 'logs failed state transitions' do
    expect(Gitlab::AppLogger).to receive(:error).with(
      hash_including(
        message: 'Organization state transition failed',
        organization_id: organization.id,
        event: :restore,
        current_state: :active,
        Labkit::Fields::GL_USER_ID => user.id
      )
    )

    organization.restore(transition_user: user)
  end
end
