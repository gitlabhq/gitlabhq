# frozen_string_literal: true

RSpec.shared_examples 'service account update success' do
  it 'updates the service account successfully', :aggregate_failures do
    result = service.execute

    expect(result.status).to eq(:success)
    expect(result.message).to eq(_('Service account was successfully updated.'))
    expect(result.payload[:user]).to eq(service_account_user)
    expect(result.payload[:user].name).to eq(params[:name])
    expect(result.payload[:user].username).to eq(params[:username])
    expect(result.payload[:user].email).to eq(params[:email])
  end
end

RSpec.shared_examples 'service account update not authorized' do
  it 'returns forbidden error and does not update the account', :aggregate_failures do
    result = service.execute

    expect(result.status).to eq(:error)
    expect(result.message).to eq(
      s_('ServiceAccount|You are not authorized to update service accounts in this namespace.')
    )
    expect(result.reason).to eq(:forbidden)
  end
end
