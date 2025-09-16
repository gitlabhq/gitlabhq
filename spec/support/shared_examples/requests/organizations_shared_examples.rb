# frozen_string_literal: true

RSpec.shared_examples 'organization - successful response' do
  it 'renders 200 OK' do
    gitlab_request

    expect(response).to have_gitlab_http_status(:ok)
  end
end

RSpec.shared_examples 'organization - not found response' do
  it 'renders 404 NOT_FOUND' do
    gitlab_request

    expect(response).to have_gitlab_http_status(:not_found)
  end
end

RSpec.shared_examples 'organization - redirects to sign in page' do
  it 'redirects to sign in page' do
    gitlab_request

    expect(response).to redirect_to(new_user_session_path)
  end
end

RSpec.shared_examples 'organization - action disabled by ui_for_organizations_enabled?' do
  context 'when ui_for_organizations_enabled? returns false', :ui_for_organizations_disabled do
    it_behaves_like 'organization - not found response'
  end
end
