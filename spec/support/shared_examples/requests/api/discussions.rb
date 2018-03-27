shared_examples 'discussions API' do |parent_type, noteable_type, id_name|
  describe "GET /#{parent_type}/:id/#{noteable_type}/:noteable_id/discussions" do
    it "returns an array of discussions" do
      get api("/#{parent_type}/#{parent.id}/#{noteable_type}/#{noteable[id_name]}/discussions", user)

      expect(response).to have_gitlab_http_status(200)
      expect(response).to include_pagination_headers
      expect(json_response).to be_an Array
      expect(json_response.first['id']).to eq(note.discussion_id)
    end

    it "returns a 404 error when noteable id not found" do
      get api("/#{parent_type}/#{parent.id}/#{noteable_type}/12345/discussions", user)

      expect(response).to have_gitlab_http_status(404)
    end

    it "returns 404 when not authorized" do
      parent.update!(visibility_level: Gitlab::VisibilityLevel::PRIVATE)

      get api("/#{parent_type}/#{parent.id}/#{noteable_type}/#{noteable[id_name]}/discussions", private_user)

      expect(response).to have_gitlab_http_status(404)
    end
  end

  describe "GET /#{parent_type}/:id/#{noteable_type}/:noteable_id/discussions/:discussion_id" do
    it "returns a discussion by id" do
      get api("/#{parent_type}/#{parent.id}/#{noteable_type}/#{noteable[id_name]}/discussions/#{note.discussion_id}", user)

      expect(response).to have_gitlab_http_status(200)
      expect(json_response['id']).to eq(note.discussion_id)
      expect(json_response['notes'].first['body']).to eq(note.note)
    end

    it "returns a 404 error if discussion not found" do
      get api("/#{parent_type}/#{parent.id}/#{noteable_type}/#{noteable[id_name]}/discussions/12345", user)

      expect(response).to have_gitlab_http_status(404)
    end
  end

  describe "POST /#{parent_type}/:id/#{noteable_type}/:noteable_id/discussions" do
    it "creates a new note" do
      post api("/#{parent_type}/#{parent.id}/#{noteable_type}/#{noteable[id_name]}/discussions", user), body: 'hi!'

      expect(response).to have_gitlab_http_status(201)
      expect(json_response['notes'].first['body']).to eq('hi!')
      expect(json_response['notes'].first['author']['username']).to eq(user.username)
    end

    it "returns a 400 bad request error if body not given" do
      post api("/#{parent_type}/#{parent.id}/#{noteable_type}/#{noteable[id_name]}/discussions", user)

      expect(response).to have_gitlab_http_status(400)
    end

    it "returns a 401 unauthorized error if user not authenticated" do
      post api("/#{parent_type}/#{parent.id}/#{noteable_type}/#{noteable[id_name]}/discussions"), body: 'hi!'

      expect(response).to have_gitlab_http_status(401)
    end

    context 'when an admin or owner makes the request' do
      it 'accepts the creation date to be set' do
        creation_time = 2.weeks.ago
        post api("/#{parent_type}/#{parent.id}/#{noteable_type}/#{noteable[id_name]}/discussions", user),
          body: 'hi!', created_at: creation_time

        expect(response).to have_gitlab_http_status(201)
        expect(json_response['notes'].first['body']).to eq('hi!')
        expect(json_response['notes'].first['author']['username']).to eq(user.username)
        expect(Time.parse(json_response['notes'].first['created_at'])).to be_like_time(creation_time)
      end
    end

    context 'when user does not have access to read the discussion' do
      before do
        parent.update!(visibility_level: Gitlab::VisibilityLevel::PRIVATE)
      end

      it 'responds with 404' do
        post api("/#{parent_type}/#{parent.id}/#{noteable_type}/#{noteable[id_name]}/discussions", private_user),
          body: 'Foo'

        expect(response).to have_gitlab_http_status(404)
      end
    end
  end

  describe "POST /#{parent_type}/:id/#{noteable_type}/:noteable_id/discussions/:discussion_id/notes" do
    it 'adds a new note to the discussion' do
      post api("/#{parent_type}/#{parent.id}/#{noteable_type}/#{noteable[id_name]}/"\
               "discussions/#{note.discussion_id}/notes", user), body: 'Hello!'

      expect(response).to have_gitlab_http_status(201)
      expect(json_response['body']).to eq('Hello!')
      expect(json_response['type']).to eq('DiscussionNote')
    end

    it 'returns a 400 bad request error if body not given' do
      post api("/#{parent_type}/#{parent.id}/#{noteable_type}/#{noteable[id_name]}/"\
               "discussions/#{note.discussion_id}/notes", user)

      expect(response).to have_gitlab_http_status(400)
    end

    it "returns a 400 bad request error if discussion is individual note" do
      note.update_attribute(:type, nil)

      post api("/#{parent_type}/#{parent.id}/#{noteable_type}/#{noteable[id_name]}/"\
               "discussions/#{note.discussion_id}/notes", user), body: 'hi!'

      expect(response).to have_gitlab_http_status(400)
    end
  end

  describe "PUT /#{parent_type}/:id/#{noteable_type}/:noteable_id/discussions/:discussion_id/notes/:note_id" do
    it 'returns modified note' do
      put api("/#{parent_type}/#{parent.id}/#{noteable_type}/#{noteable[id_name]}/"\
              "discussions/#{note.discussion_id}/notes/#{note.id}", user), body: 'Hello!'

      expect(response).to have_gitlab_http_status(200)
      expect(json_response['body']).to eq('Hello!')
    end

    it 'returns a 404 error when note id not found' do
      put api("/#{parent_type}/#{parent.id}/#{noteable_type}/#{noteable[id_name]}/"\
              "discussions/#{note.discussion_id}/notes/12345", user),
              body: 'Hello!'

      expect(response).to have_gitlab_http_status(404)
    end

    it 'returns a 400 bad request error if body not given' do
      put api("/#{parent_type}/#{parent.id}/#{noteable_type}/#{noteable[id_name]}/"\
              "discussions/#{note.discussion_id}/notes/#{note.id}", user)

      expect(response).to have_gitlab_http_status(400)
    end
  end

  describe "DELETE /#{parent_type}/:id/#{noteable_type}/:noteable_id/discussions/:discussion_id/notes/:note_id" do
    it 'deletes a note' do
      delete api("/#{parent_type}/#{parent.id}/#{noteable_type}/#{noteable[id_name]}/"\
                 "discussions/#{note.discussion_id}/notes/#{note.id}", user)

      expect(response).to have_gitlab_http_status(204)
      # Check if note is really deleted
      delete api("/#{parent_type}/#{parent.id}/#{noteable_type}/#{noteable[id_name]}/"\
                 "discussions/#{note.discussion_id}/notes/#{note.id}", user)
      expect(response).to have_gitlab_http_status(404)
    end

    it 'returns a 404 error when note id not found' do
      delete api("/#{parent_type}/#{parent.id}/#{noteable_type}/#{noteable[id_name]}/"\
                 "discussions/#{note.discussion_id}/notes/12345", user)

      expect(response).to have_gitlab_http_status(404)
    end

    it_behaves_like '412 response' do
      let(:request) do
        api("/#{parent_type}/#{parent.id}/#{noteable_type}/#{noteable[id_name]}/"\
            "discussions/#{note.discussion_id}/notes/#{note.id}", user)
      end
    end
  end
end
