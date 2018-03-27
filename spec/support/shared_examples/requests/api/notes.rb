shared_examples 'noteable API' do |parent_type, noteable_type, id_name|
  describe "GET /#{parent_type}/:id/#{noteable_type}/:noteable_id/notes" do
    context 'sorting' do
      before do
        params = { noteable: noteable, author: user }
        params[:project] = parent if parent.is_a?(Project)

        create_list(:note, 3, params)
      end

      it 'sorts by created_at in descending order by default' do
        get api("/#{parent_type}/#{parent.id}/#{noteable_type}/#{noteable[id_name]}/notes", user)

        response_dates = json_response.map { |note| note['created_at'] }

        expect(json_response.length).to eq(4)
        expect(response_dates).to eq(response_dates.sort.reverse)
      end

      it 'sorts by ascending order when requested' do
        get api("/#{parent_type}/#{parent.id}/#{noteable_type}/#{noteable[id_name]}/notes?sort=asc", user)

        response_dates = json_response.map { |note| note['created_at'] }

        expect(json_response.length).to eq(4)
        expect(response_dates).to eq(response_dates.sort)
      end

      it 'sorts by updated_at in descending order when requested' do
        get api("/#{parent_type}/#{parent.id}/#{noteable_type}/#{noteable[id_name]}/notes?order_by=updated_at", user)

        response_dates = json_response.map { |note| note['updated_at'] }

        expect(json_response.length).to eq(4)
        expect(response_dates).to eq(response_dates.sort.reverse)
      end

      it 'sorts by updated_at in ascending order when requested' do
        get api("/#{parent_type}/#{parent.id}/#{noteable_type}/#{noteable[id_name]}/notes?order_by=updated_at&sort=asc", user)

        response_dates = json_response.map { |note| note['updated_at'] }

        expect(json_response.length).to eq(4)
        expect(response_dates).to eq(response_dates.sort)
      end
    end

    it "returns an array of notes" do
      get api("/#{parent_type}/#{parent.id}/#{noteable_type}/#{noteable[id_name]}/notes", user)

      expect(response).to have_gitlab_http_status(200)
      expect(response).to include_pagination_headers
      expect(json_response).to be_an Array
      expect(json_response.first['body']).to eq(note.note)
    end

    it "returns a 404 error when noteable id not found" do
      get api("/#{parent_type}/#{parent.id}/#{noteable_type}/12345/notes", user)

      expect(response).to have_gitlab_http_status(404)
    end

    it "returns 404 when not authorized" do
      parent.update!(visibility_level: Gitlab::VisibilityLevel::PRIVATE)

      get api("/#{parent_type}/#{parent.id}/#{noteable_type}/#{noteable[id_name]}/notes", private_user)

      expect(response).to have_gitlab_http_status(404)
    end
  end

  describe "GET /#{parent_type}/:id/#{noteable_type}/:noteable_id/notes/:note_id" do
    it "returns a note by id" do
      get api("/#{parent_type}/#{parent.id}/#{noteable_type}/#{noteable[id_name]}/notes/#{note.id}", user)

      expect(response).to have_gitlab_http_status(200)
      expect(json_response['body']).to eq(note.note)
    end

    it "returns a 404 error if note not found" do
      get api("/#{parent_type}/#{parent.id}/#{noteable_type}/#{noteable[id_name]}/notes/12345", user)

      expect(response).to have_gitlab_http_status(404)
    end
  end

  describe "POST /#{parent_type}/:id/#{noteable_type}/:noteable_id/notes" do
    it "creates a new note" do
      post api("/#{parent_type}/#{parent.id}/#{noteable_type}/#{noteable[id_name]}/notes", user), body: 'hi!'

      expect(response).to have_gitlab_http_status(201)
      expect(json_response['body']).to eq('hi!')
      expect(json_response['author']['username']).to eq(user.username)
    end

    it "returns a 400 bad request error if body not given" do
      post api("/#{parent_type}/#{parent.id}/#{noteable_type}/#{noteable[id_name]}/notes", user)

      expect(response).to have_gitlab_http_status(400)
    end

    it "returns a 401 unauthorized error if user not authenticated" do
      post api("/#{parent_type}/#{parent.id}/#{noteable_type}/#{noteable[id_name]}/notes"), body: 'hi!'

      expect(response).to have_gitlab_http_status(401)
    end

    it "creates an activity event when a note is created" do
      expect(Event).to receive(:create!)

      post api("/#{parent_type}/#{parent.id}/#{noteable_type}/#{noteable[id_name]}/notes", user), body: 'hi!'
    end

    context 'when an admin or owner makes the request' do
      it 'accepts the creation date to be set' do
        creation_time = 2.weeks.ago
        post api("/#{parent_type}/#{parent.id}/#{noteable_type}/#{noteable[id_name]}/notes", user),
          body: 'hi!', created_at: creation_time

        expect(response).to have_gitlab_http_status(201)
        expect(json_response['body']).to eq('hi!')
        expect(json_response['author']['username']).to eq(user.username)
        expect(Time.parse(json_response['created_at'])).to be_like_time(creation_time)
      end
    end

    context 'when the user is posting an award emoji on a noteable created by someone else' do
      it 'creates a new note' do
        parent.add_developer(private_user)
        post api("/#{parent_type}/#{parent.id}/#{noteable_type}/#{noteable[id_name]}/notes", private_user), body: ':+1:'

        expect(response).to have_gitlab_http_status(201)
        expect(json_response['body']).to eq(':+1:')
      end
    end

    context 'when the user is posting an award emoji on his/her own noteable' do
      it 'creates a new note' do
        post api("/#{parent_type}/#{parent.id}/#{noteable_type}/#{noteable[id_name]}/notes", user), body: ':+1:'

        expect(response).to have_gitlab_http_status(201)
        expect(json_response['body']).to eq(':+1:')
      end
    end

    context 'when user does not have access to read the noteable' do
      before do
        parent.update!(visibility_level: Gitlab::VisibilityLevel::PRIVATE)
      end

      it 'responds with 404' do
        post api("/#{parent_type}/#{parent.id}/#{noteable_type}/#{noteable[id_name]}/notes", private_user),
          body: 'Foo'

        expect(response).to have_gitlab_http_status(404)
      end
    end
  end

  describe "PUT /#{parent_type}/:id/#{noteable_type}/:noteable_id/notes/:note_id" do
    it 'returns modified note' do
      put api("/#{parent_type}/#{parent.id}/#{noteable_type}/#{noteable[id_name]}/"\
                "notes/#{note.id}", user), body: 'Hello!'

      expect(response).to have_gitlab_http_status(200)
      expect(json_response['body']).to eq('Hello!')
    end

    it 'returns a 404 error when note id not found' do
      put api("/#{parent_type}/#{parent.id}/#{noteable_type}/#{noteable[id_name]}/notes/12345", user),
              body: 'Hello!'

      expect(response).to have_gitlab_http_status(404)
    end

    it 'returns a 400 bad request error if body not given' do
      put api("/#{parent_type}/#{parent.id}/#{noteable_type}/#{noteable[id_name]}/"\
                "notes/#{note.id}", user)

      expect(response).to have_gitlab_http_status(400)
    end
  end

  describe "DELETE /#{parent_type}/:id/#{noteable_type}/:noteable_id/notes/:note_id" do
    it 'deletes a note' do
      delete api("/#{parent_type}/#{parent.id}/#{noteable_type}/#{noteable[id_name]}/"\
                 "notes/#{note.id}", user)

      expect(response).to have_gitlab_http_status(204)
      # Check if note is really deleted
      delete api("/#{parent_type}/#{parent.id}/#{noteable_type}/#{noteable[id_name]}/"\
                 "notes/#{note.id}", user)
      expect(response).to have_gitlab_http_status(404)
    end

    it 'returns a 404 error when note id not found' do
      delete api("/#{parent_type}/#{parent.id}/#{noteable_type}/#{noteable[id_name]}/notes/12345", user)

      expect(response).to have_gitlab_http_status(404)
    end

    it_behaves_like '412 response' do
      let(:request) { api("/#{parent_type}/#{parent.id}/#{noteable_type}/#{noteable[id_name]}/notes/#{note.id}", user) }
    end
  end
end
