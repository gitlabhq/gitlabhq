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
    get api("/projects/#{project.id}/#{area}/#{entity.id}/participants", user)

    expect(response).to have_gitlab_http_status(:not_found)
  end

  context 'with a confidential note' do
    let!(:note) do
      create(
        :note,
        :confidential,
        project: project,
        noteable: entity,
        author: create(:user)
      )
    end

    it 'returns a full list of participants' do
      get api("/projects/#{project.id}/#{area}/#{entity.iid}/participants", user)

      expect(response).to have_gitlab_http_status(:ok)
      participant_ids = json_response.map { |el| el['id'] }
      expect(participant_ids).to match_array([entity.author_id, note.author_id])
    end

    context 'when user cannot see a confidential note' do
      it 'returns a limited list of participants' do
        get api("/projects/#{project.id}/#{area}/#{entity.iid}/participants", create(:user))

        expect(response).to have_gitlab_http_status(:ok)
        participant_ids = json_response.map { |el| el['id'] }
        expect(participant_ids).to match_array([entity.author_id])
      end
    end
  end
end
