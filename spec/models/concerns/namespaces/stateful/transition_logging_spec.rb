# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Namespaces::Stateful::TransitionLogging, feature_category: :groups_and_projects do
  include Namespaces::StatefulHelpers

  let_it_be(:user) { create(:user) }
  let_it_be_with_reload(:namespace) { create(:namespace) }

  it 'logs successful state transitions' do
    set_state(namespace, :ancestor_inherited)

    expect(Gitlab::AppLogger).to receive(:info).with(
      hash_including(
        message: 'Namespace state transition',
        namespace_id: namespace.id,
        from_state: :ancestor_inherited,
        to_state: :archived,
        event: :archive,
        user_id: user.id
      )
    )

    namespace.archive!(transition_user: user)
  end

  it 'logs successful state transitions without user' do
    set_state(namespace, :ancestor_inherited)

    expect(Gitlab::AppLogger).to receive(:info).with(
      hash_including(
        message: 'Namespace state transition',
        namespace_id: namespace.id,
        from_state: :ancestor_inherited,
        to_state: :archived,
        event: :archive,
        user_id: nil
      )
    )

    namespace.archive!
  end

  it 'logs failed state transitions' do
    set_state(namespace, :archived)

    expect(Gitlab::AppLogger).to receive(:error).with(
      hash_including(
        message: 'Namespace state transition failed',
        namespace_id: namespace.id,
        event: :archive,
        current_state: :archived,
        error: 'Cannot transition from archived to archived via archive: cannot transition via "archive"',
        user_id: user.id
      )
    )

    namespace.archive(transition_user: user)
  end
end
