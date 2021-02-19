# frozen_string_literal: true
#
# Requires a context containing:
# - user
# - params
# - request_full_path

RSpec.shared_examples 'request exceeding rate limit' do
  before do
    stub_application_setting(notes_create_limit: 2)
    2.times { post :create, params: params }
  end

  it 'prevents from creating more notes', :request_store do
    expect { post :create, params: params }
      .to change { Note.count }.by(0)

    expect(response).to have_gitlab_http_status(:too_many_requests)
    expect(response.body).to eq(_('This endpoint has been requested too many times. Try again later.'))
  end

  it 'logs the event in auth.log' do
    attributes = {
      message: 'Application_Rate_Limiter_Request',
      env: :notes_create_request_limit,
      remote_ip: '0.0.0.0',
      request_method: 'POST',
      path: request_full_path,
      user_id: user.id,
      username: user.username
    }

    expect(Gitlab::AuthLogger).to receive(:error).with(attributes).once
    post :create, params: params
  end

  it 'allows user in allow-list to create notes, even if the case is different' do
    user.update_attribute(:username, user.username.titleize)
    stub_application_setting(notes_create_limit_allowlist: ["#{user.username.downcase}"])

    post :create, params: params
    expect(response).to have_gitlab_http_status(:found)
  end
end
