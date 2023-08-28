# frozen_string_literal: true

RSpec.shared_examples 'handle subscription based on user access' do
  it 'subscribes to the noteable stream when user has access' do
    subscribe(subscribe_params)

    expect(subscription).to be_confirmed
    expect(subscription).to have_stream_for(noteable)
  end

  it 'rejects the subscription when the user does not have access' do
    stub_action_cable_connection current_user: nil

    subscribe(subscribe_params)

    expect(subscription).to be_rejected
  end
end
