# frozen_string_literal: true

RSpec.shared_examples 'noteable API' do |parent_type, noteable_type, id_name|
  describe "GET /#{parent_type}/:id/#{noteable_type}/:noteable_id/notes" do
    context 'sorting' do
      before do
        params = { noteable: noteable, author: user }
        params[:project] = parent if parent.is_a?(Project)

        create_list(:note, 3, params)
      end

      context 'without sort params' do
        it 'sorts by created_at in descending order by default' do
          get api("/#{parent_type}/#{parent.id}/#{noteable_type}/#{noteable[id_name]}/notes", user)

          response_dates = json_response.map { |note| note['created_at'] }

          expect(json_response.length).to eq(4)
          expect(response_dates).to eq(response_dates.sort.reverse)
        end

        it 'fetches notes using parent path as id paremeter' do
          parent_id = CGI.escape(parent.full_path)

          get api("/#{parent_type}/#{parent_id}/#{noteable_type}/#{noteable[id_name]}/notes", user)

          expect(response).to have_gitlab_http_status(:ok)
        end

        context '2 notes with equal created_at' do
          before do
            @first_note = Note.first

            params = { noteable: noteable, author: user }
            params[:project] = parent if parent.is_a?(Project)
            params[:created_at] = @first_note.created_at

            @note2 = create(:note, params)
          end

          it 'page breaks first page correctly' do
            get api("/#{parent_type}/#{parent.id}/#{noteable_type}/#{noteable[id_name]}/notes?per_page=4", user)

            response_ids = json_response.map { |note| note['id'] }

            expect(response_ids).to include(@note2.id)
            expect(response_ids).not_to include(@first_note.id)
          end

          it 'page breaks second page correctly' do
            get api("/#{parent_type}/#{parent.id}/#{noteable_type}/#{noteable[id_name]}/notes?per_page=4&page=2", user)

            response_ids = json_response.map { |note| note['id'] }

            expect(response_ids).not_to include(@note2.id)
            expect(response_ids).to include(@first_note.id)
          end
        end
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

      expect(response).to have_gitlab_http_status(:ok)
      expect(response).to include_pagination_headers
      expect(json_response).to be_an Array
      expect(json_response.first['body']).to eq(note.note)
    end

    it "returns a 404 error when noteable id not found" do
      get api("/#{parent_type}/#{parent.id}/#{noteable_type}/#{non_existing_record_id}/notes", user)

      expect(response).to have_gitlab_http_status(:not_found)
    end

    it "returns 404 when not authorized" do
      parent.update!(visibility_level: Gitlab::VisibilityLevel::PRIVATE)

      get api("/#{parent_type}/#{parent.id}/#{noteable_type}/#{noteable[id_name]}/notes", private_user)

      expect(response).to have_gitlab_http_status(:not_found)
    end
  end

  describe "GET /#{parent_type}/:id/#{noteable_type}/:noteable_id/notes/:note_id" do
    it "returns a note by id" do
      get api("/#{parent_type}/#{parent.id}/#{noteable_type}/#{noteable[id_name]}/notes/#{note.id}", user)

      expect(response).to have_gitlab_http_status(:ok)
      expect(json_response['body']).to eq(note.note)
    end

    it "returns a 404 error if note not found" do
      get api("/#{parent_type}/#{parent.id}/#{noteable_type}/#{noteable[id_name]}/notes/#{non_existing_record_id}", user)

      expect(response).to have_gitlab_http_status(:not_found)
    end
  end

  describe "POST /#{parent_type}/:id/#{noteable_type}/:noteable_id/notes" do
    it "creates a new note" do
      post api("/#{parent_type}/#{parent.id}/#{noteable_type}/#{noteable[id_name]}/notes", user), params: { body: 'hi!' }

      expect(response).to have_gitlab_http_status(:created)
      expect(json_response['body']).to eq('hi!')
      expect(json_response['confidential']).to be_falsey
      expect(json_response['author']['username']).to eq(user.username)
    end

    it "creates a confidential note if confidential is set to true" do
      post api("/#{parent_type}/#{parent.id}/#{noteable_type}/#{noteable[id_name]}/notes", user), params: { body: 'hi!', confidential: true }

      expect(response).to have_gitlab_http_status(:created)
      expect(json_response['body']).to eq('hi!')
      expect(json_response['confidential']).to be_truthy
      expect(json_response['author']['username']).to eq(user.username)
    end

    it "returns a 400 bad request error if body not given" do
      post api("/#{parent_type}/#{parent.id}/#{noteable_type}/#{noteable[id_name]}/notes", user)

      expect(response).to have_gitlab_http_status(:bad_request)
    end

    it "returns a 401 unauthorized error if user not authenticated" do
      post api("/#{parent_type}/#{parent.id}/#{noteable_type}/#{noteable[id_name]}/notes"), params: { body: 'hi!' }

      expect(response).to have_gitlab_http_status(:unauthorized)
    end

    it "creates an activity event when a note is created", :sidekiq_might_not_need_inline do
      uri = "/#{parent_type}/#{parent.id}/#{noteable_type}/#{noteable[id_name]}/notes"

      expect do
        post api(uri, user), params: { body: 'hi!' }
      end.to change(Event, :count).by(1)
    end

    context 'setting created_at' do
      let(:creation_time) { 2.weeks.ago }
      let(:params) { { body: 'hi!', created_at: creation_time } }

      context 'by an admin' do
        it 'sets the creation time on the new note' do
          admin = create(:admin)
          post api("/#{parent_type}/#{parent.id}/#{noteable_type}/#{noteable[id_name]}/notes", admin), params: params

          expect(response).to have_gitlab_http_status(:created)
          expect(json_response['body']).to eq('hi!')
          expect(json_response['author']['username']).to eq(admin.username)
          expect(Time.parse(json_response['created_at'])).to be_like_time(creation_time)
          expect(Time.parse(json_response['updated_at'])).to be_like_time(creation_time)
        end
      end

      if parent_type == 'projects'
        context 'by a project owner' do
          let(:user) { project.owner }

          it 'sets the creation time on the new note' do
            post api("/#{parent_type}/#{parent.id}/#{noteable_type}/#{noteable[id_name]}/notes", user), params: params

            expect(response).to have_gitlab_http_status(:created)
            expect(json_response['body']).to eq('hi!')
            expect(json_response['author']['username']).to eq(user.username)
            expect(Time.parse(json_response['created_at'])).to be_like_time(creation_time)
            expect(Time.parse(json_response['updated_at'])).to be_like_time(creation_time)
          end
        end

        context 'by a group owner' do
          it 'sets the creation time on the new note' do
            user2 = create(:user)
            group = create(:group)
            group.add_owner(user2)
            parent.update!(namespace: group)
            user2.refresh_authorized_projects

            post api("/#{parent_type}/#{parent.id}/#{noteable_type}/#{noteable[id_name]}/notes", user2), params: params

            expect(response).to have_gitlab_http_status(:created)
            expect(json_response['body']).to eq('hi!')
            expect(json_response['author']['username']).to eq(user2.username)
            expect(Time.parse(json_response['created_at'])).to be_like_time(creation_time)
            expect(Time.parse(json_response['updated_at'])).to be_like_time(creation_time)
          end
        end
      elsif parent_type == 'groups'
        context 'by a group owner' do
          it 'sets the creation time on the new note' do
            post api("/#{parent_type}/#{parent.id}/#{noteable_type}/#{noteable[id_name]}/notes", user), params: params

            expect(response).to have_gitlab_http_status(:created)
            expect(json_response['body']).to eq('hi!')
            expect(json_response['author']['username']).to eq(user.username)
            expect(Time.parse(json_response['created_at'])).to be_like_time(creation_time)
            expect(Time.parse(json_response['updated_at'])).to be_like_time(creation_time)
          end
        end
      end

      context 'by another user' do
        it 'ignores the given creation time' do
          user2 = create(:user)
          parent.add_developer(user2)
          post api("/#{parent_type}/#{parent.id}/#{noteable_type}/#{noteable[id_name]}/notes", user2), params: params

          expect(response).to have_gitlab_http_status(:created)
          expect(json_response['body']).to eq('hi!')
          expect(json_response['author']['username']).to eq(user2.username)
          expect(Time.parse(json_response['created_at'])).not_to be_like_time(creation_time)
          expect(Time.parse(json_response['updated_at'])).not_to be_like_time(creation_time)
        end
      end
    end

    context 'when the user is posting an award emoji on a noteable created by someone else' do
      it 'creates a new note' do
        parent.add_developer(private_user)
        post api("/#{parent_type}/#{parent.id}/#{noteable_type}/#{noteable[id_name]}/notes", private_user), params: { body: ':+1:' }

        expect(response).to have_gitlab_http_status(:created)
        expect(json_response['body']).to eq(':+1:')
      end
    end

    context 'when the user is posting an award emoji on their own noteable' do
      it 'creates a new note' do
        post api("/#{parent_type}/#{parent.id}/#{noteable_type}/#{noteable[id_name]}/notes", user), params: { body: ':+1:' }

        expect(response).to have_gitlab_http_status(:created)
        expect(json_response['body']).to eq(':+1:')
      end
    end

    context 'when user does not have access to read the noteable' do
      before do
        parent.update!(visibility_level: Gitlab::VisibilityLevel::PRIVATE)
      end

      it 'responds with 404' do
        post api("/#{parent_type}/#{parent.id}/#{noteable_type}/#{noteable[id_name]}/notes", private_user),
          params: { body: 'Foo' }

        expect(response).to have_gitlab_http_status(:not_found)
      end
    end
  end

  describe "PUT /#{parent_type}/:id/#{noteable_type}/:noteable_id/notes/:note_id" do
    let(:params) { { body: 'Hello!', confidential: false } }

    subject do
      put api("/#{parent_type}/#{parent.id}/#{noteable_type}/#{noteable[id_name]}/notes/#{note.id}", user), params: params
    end

    context 'when eveything is ok' do
      before do
        note.update!(confidential: true)
      end

      context 'with multiple params present' do
        before do
          subject
        end

        it 'returns modified note' do
          expect(response).to have_gitlab_http_status(:ok)
          expect(json_response['body']).to eq('Hello!')
          expect(json_response['confidential']).to be_falsey
        end

        it 'updates the note' do
          expect(note.reload.note).to eq('Hello!')
          expect(note.confidential).to be_falsey
        end
      end

      context 'when only body param is present' do
        let(:params) { { body: 'Hello!' } }

        it 'updates only the note text' do
          expect { subject }.not_to change { note.reload.confidential }

          expect(note.note).to eq('Hello!')
        end
      end

      context 'when only confidential param is present' do
        let(:params) { { confidential: false } }

        it 'updates only the note text' do
          expect { subject }.not_to change { note.reload.note }

          expect(note.confidential).to be_falsey
        end
      end
    end

    it 'returns a 404 error when note id not found' do
      put api("/#{parent_type}/#{parent.id}/#{noteable_type}/#{noteable[id_name]}/notes/#{non_existing_record_id}", user),
              params: { body: 'Hello!' }

      expect(response).to have_gitlab_http_status(:not_found)
    end

    it 'returns a 400 bad request error if body is empty' do
      put api("/#{parent_type}/#{parent.id}/#{noteable_type}/#{noteable[id_name]}/"\
                "notes/#{note.id}", user), params: { body: '' }

      expect(response).to have_gitlab_http_status(:bad_request)
    end
  end

  describe "DELETE /#{parent_type}/:id/#{noteable_type}/:noteable_id/notes/:note_id" do
    it 'deletes a note' do
      delete api("/#{parent_type}/#{parent.id}/#{noteable_type}/#{noteable[id_name]}/"\
                 "notes/#{note.id}", user)

      expect(response).to have_gitlab_http_status(:no_content)
      # Check if note is really deleted
      delete api("/#{parent_type}/#{parent.id}/#{noteable_type}/#{noteable[id_name]}/"\
                 "notes/#{note.id}", user)
      expect(response).to have_gitlab_http_status(:not_found)
    end

    it 'returns a 404 error when note id not found' do
      delete api("/#{parent_type}/#{parent.id}/#{noteable_type}/#{noteable[id_name]}/notes/#{non_existing_record_id}", user)

      expect(response).to have_gitlab_http_status(:not_found)
    end

    it_behaves_like '412 response' do
      let(:request) { api("/#{parent_type}/#{parent.id}/#{noteable_type}/#{noteable[id_name]}/notes/#{note.id}", user) }
    end
  end
end
