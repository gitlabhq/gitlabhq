shared_examples 'issuable participants endpoint' do
  let(:area) { entity.class.name.underscore.pluralize }

  it 'returns participants' do
    get api("/projects/#{project.id}/#{area}/#{entity.iid}/participants", user)

    expect(response).to have_gitlab_http_status(200)
    expect(response).to include_pagination_headers
    expect(json_response).to be_an Array
    expect(json_response.size).to eq(entity.participants.size)

    last_participant = entity.participants.last
    expect(json_response.last['id']).to eq(last_participant.id)
    expect(json_response.last['name']).to eq(last_participant.name)
    expect(json_response.last['username']).to eq(last_participant.username)
  end

  it 'returns a 404 when iid does not exist' do
    get api("/projects/#{project.id}/#{area}/999/participants", user)

    expect(response).to have_gitlab_http_status(404)
  end

  it 'returns a 404 when id is used instead of iid' do
    get api("/projects/#{project.id}/#{area}/#{entity.id}/participants", user)

    expect(response).to have_gitlab_http_status(404)
  end
end
