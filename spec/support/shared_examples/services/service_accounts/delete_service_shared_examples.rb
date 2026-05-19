# frozen_string_literal: true

RSpec.shared_examples 'service account deletion success' do
  it 'deletes service account successfully', :sidekiq_inline, :aggregate_failures do
    result = perform_enqueued_jobs { service.execute(options) }

    expect(result.status).to eq(:success)
    expect(result.message).to eq('User successfully deleted')
    expect(Users::GhostUserMigration.where(user: service_account_user, initiator_user: current_user)).to exist
    expect(service_account_user.reload.blocked?).to be(true)
  end
end

RSpec.shared_examples 'service account deletion failure' do
  let(:user_under_test) { service_account_user }

  it 'returns forbidden error and does not enqueue deletion', :aggregate_failures do
    result = service.execute(options)

    expect(result.status).to eq(:error)
    expect(result.message).to eq(s_('ServiceAccount|User does not have permission to delete a service account.'))
    expect(result.reason).to eq(:forbidden)
    expect(Users::GhostUserMigration.where(user: user_under_test, initiator_user: current_user)).not_to exist
    expect(user_under_test.reload.blocked?).to be(false)
  end
end
