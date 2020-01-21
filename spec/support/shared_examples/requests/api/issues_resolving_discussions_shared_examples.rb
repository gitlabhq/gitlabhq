# frozen_string_literal: true

RSpec.shared_examples 'creating an issue resolving discussions through the API' do
  it 'creates a new project issue' do
    expect(response).to have_gitlab_http_status(:created)
  end

  it 'resolves the discussions in a merge request' do
    discussion.first_note.reload

    expect(discussion.resolved?).to be(true)
  end

  it 'assigns a description to the issue mentioning the merge request' do
    expect(json_response['description']).to include(merge_request.to_reference)
  end
end
