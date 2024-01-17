# frozen_string_literal: true

RSpec.shared_examples 'a 404 response when source is private' do
  before do
    source.update_column(:visibility_level, Gitlab::VisibilityLevel::PRIVATE)
  end

  it 'returns 404' do
    route

    expect(response).to have_gitlab_http_status(:not_found)
  end
end

RSpec.shared_examples 'a 403 response when user does not have rights to manage members of a specific access level' do
  it 'returns 403' do
    expect { route }.not_to change { Member.count }

    expect(response).to have_gitlab_http_status(:forbidden)
  end
end
