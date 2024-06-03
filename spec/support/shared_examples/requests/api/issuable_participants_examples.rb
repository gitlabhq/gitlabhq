# frozen_string_literal: true

RSpec.shared_examples 'issuable participants endpoint' do
  let(:area) { entity.class.name.underscore.pluralize }

  it 'returns participants' do
    get api("/projects/#{project.id}/#{area}/#{entity.iid}/participants", user)

    expect(response).to have_gitlab_http_status(:ok)
    expect(response).to include_pagination_headers
    expect(json_response).to be_an Array
    expect(json_response.size).to eq(entity.participants.size)

    last_participant = entity.participants.last
    expect(json_response.last['id']).to eq(last_participant.id)
    expect(json_response.last['name']).to eq(last_participant.name)
    expect(json_response.last['username']).to eq(last_participant.username)
  end

  it 'returns a 404 when iid does not exist' do
    get api("/projects/#{project.id}/#{area}/#{non_existing_record_iid}/participants", user)

    expect(response).to have_gitlab_http_status(:not_found)
  end

  it 'returns a 404 when id is used instead of iid' do
    # Make sure other issues don't exist with a matching id or iid to avoid flakyness
    max_id = [entity.class.maximum(:iid), entity.class.maximum(:id)].max + 10
    new_entity = entity.dup.tap { |e| e.id = max_id }
    entity.class.where(id: entity.id).delete_all
    new_entity.save!

    # make sure it does work with iid
    get api("/projects/#{project.id}/#{area}/#{new_entity.iid}/participants", user)
    expect(response).to have_gitlab_http_status(:ok)

    get api("/projects/#{project.id}/#{area}/#{new_entity.id}/participants", user)
    expect(response).to have_gitlab_http_status(:not_found)
  end
end
