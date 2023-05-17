# frozen_string_literal: true

RSpec.shared_examples 'noteable API' do |parent_type, noteable_type, id_name|
  describe "GET /#{parent_type}/:id/#{noteable_type}/:noteable_id/notes", :aggregate_failures do
    context 'sorting' do
      before do
        params = { noteable: noteable, author: user }
        params[:project] = parent if parent.is_a?(Project)

        create_list(:note, 3, params)
      end

      context 'without sort params' do
        it 'sorts by created_at in descending order by default' do
          get api("/#{parent_type}/#{parent.id}/#{noteable_type}/#{noteable[id_name]}/notes", user, admin_mode: user.admin?)

          response_dates = json_response.pluck('created_at')

          expect(json_response.length).to eq(4)
          expect(response_dates).to eq(response_dates.sort.reverse)
        end

        it 'fetches notes using parent path as id paremeter' do
          parent_id = CGI.escape(parent.full_path)

          get api("/#{parent_type}/#{parent_id}/#{noteable_type}/#{noteable[id_name]}/notes", user, admin_mode: user.admin?)

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
            get api("/#{parent_type}/#{parent.id}/#{noteable_type}/#{noteable[id_name]}/notes?per_page=4", user, admin_mode: user.admin?)

            response_ids = json_response.pluck('id')

            expect(response_ids).to include(@note2.id)
            expect(response_ids).not_to include(@first_note.id)
          end

          it 'page breaks second page correctly' do
            get api("/#{parent_type}/#{parent.id}/#{noteable_type}/#{noteable[id_name]}/notes?per_page=4&page=2", user, admin_mode: user.admin?)

            response_ids = json_response.pluck('id')

            expect(response_ids).not_to include(@note2.id)
            expect(response_ids).to include(@first_note.id)
          end
        end
      end

      it 'sorts by ascending order when requested' do
        get api("/#{parent_type}/#{parent.id}/#{noteable_type}/#{noteable[id_name]}/notes?sort=asc", user, admin_mode: user.admin?)

        response_dates = json_response.pluck('created_at')

        expect(json_response.length).to eq(4)
        expect(response_dates).to eq(response_dates.sort)
      end

      it 'sorts by updated_at in descending order when requested' do
        get api("/#{parent_type}/#{parent.id}/#{noteable_type}/#{noteable[id_name]}/notes?order_by=updated_at", user, admin_mode: user.admin?)

        response_dates = json_response.pluck('updated_at')

        expect(json_response.length).to eq(4)
        expect(response_dates).to eq(response_dates.sort.reverse)
      end

      it 'sorts by updated_at in ascending order when requested' do
        get api("/#{parent_type}/#{parent.id}/#{noteable_type}/#{noteable[id_name]}/notes?order_by=updated_at&sort=asc", user, admin_mode: user.admin?)

        response_dates = json_response.pluck('updated_at')

        expect(json_response.length).to eq(4)
        expect(response_dates).to eq(response_dates.sort)
      end
    end

    it "returns an array of notes" do
      get api("/#{parent_type}/#{parent.id}/#{noteable_type}/#{noteable[id_name]}/notes", user, admin_mode: user.admin?)

      expect(response).to have_gitlab_http_status(:ok)
      expect(response).to include_pagination_headers
      expect(json_response).to be_an Array
      expect(json_response.first['body']).to eq(note.note)
    end

    it "returns a 404 error when noteable id not found" do
      get api("/#{parent_type}/#{parent.id}/#{noteable_type}/#{non_existing_record_id}/notes", user, admin_mode: user.admin?)

      expect(response).to have_gitlab_http_status(:not_found)
    end

    it "returns 404 when not authorized" do
      parent.update!(visibility_level: Gitlab::VisibilityLevel::PRIVATE)

      get api("/#{parent_type}/#{parent.id}/#{noteable_type}/#{noteable[id_name]}/notes", private_user, admin_mode: private_user.admin?)

      expect(response).to have_gitlab_http_status(:not_found)
    end
  end

  describe "GET /#{parent_type}/:id/#{noteable_type}/:noteable_id/notes/:note_id", :aggregate_failures do
    it "returns a note by id" do
      get api("/#{parent_type}/#{parent.id}/#{noteable_type}/#{noteable[id_name]}/notes/#{note.id}", user, admin_mode: user.admin?)

      expect(response).to have_gitlab_http_status(:ok)
      expect(json_response['body']).to eq(note.note)
    end

    it "returns a 404 error if note not found" do
      get api("/#{parent_type}/#{parent.id}/#{noteable_type}/#{noteable[id_name]}/notes/#{non_existing_record_id}", user, admin_mode: user.admin?)

      expect(response).to have_gitlab_http_status(:not_found)
    end
  end

  describe "POST /#{parent_type}/:id/#{noteable_type}/:noteable_id/notes", :aggregate_failures do
    let(:params) { { body: 'hi!' } }

    subject do
      post api("/#{parent_type}/#{parent.id}/#{noteable_type}/#{noteable[id_name]}/notes", user, admin_mode: user.admin?), params: params
    end

    it "creates a new note" do
      post api("/#{parent_type}/#{parent.id}/#{noteable_type}/#{noteable[id_name]}/notes", user, admin_mode: user.admin?), params: { body: 'hi!' }

      expect(response).to have_gitlab_http_status(:created)
      expect(json_response['body']).to eq('hi!')
      expect(json_response['confidential']).to be_falsey
      expect(json_response['author']['username']).to eq(user.username)
    end

    it "returns a 400 bad request error if body not given" do
      post api("/#{parent_type}/#{parent.id}/#{noteable_type}/#{noteable[id_name]}/notes", user, admin_mode: user.admin?)

      expect(response).to have_gitlab_http_status(:bad_request)
    end

    it "returns a 401 unauthorized error if user not authenticated" do
      post api("/#{parent_type}/#{parent.id}/#{noteable_type}/#{noteable[id_name]}/notes"), params: { body: 'hi!' }

      expect(response).to have_gitlab_http_status(:unauthorized)
    end

    it "creates an activity event when a note is created", :sidekiq_might_not_need_inline do
      uri = "/#{parent_type}/#{parent.id}/#{noteable_type}/#{noteable[id_name]}/notes"

      expect do
        post api(uri, user, admin_mode: user.admin?), params: { body: 'hi!' }
      end.to change { Event.count }.by(1)
    end

    context 'setting created_at' do
      let(:creation_time) { 2.weeks.ago }
      let(:params) { { body: 'hi!', created_at: creation_time } }

      context 'by an admin' do
        it 'sets the creation time on the new note' do
          admin = create(:admin)
          post api("/#{parent_type}/#{parent.id}/#{noteable_type}/#{noteable[id_name]}/notes", admin, admin_mode: true), params: params

          expect(response).to have_gitlab_http_status(:created)
          expect(json_response['body']).to eq('hi!')
          expect(json_response['author']['username']).to eq(admin.username)
          expect(Time.parse(json_response['created_at'])).to be_like_time(creation_time)
          expect(Time.parse(json_response['updated_at'])).to be_like_time(creation_time)
        end
      end

      case parent_type
      when 'projects'
        context 'by a project owner' do
          let(:user) { project.first_owner }

          it 'sets the creation time on the new note' do
            post api("/#{parent_type}/#{parent.id}/#{noteable_type}/#{noteable[id_name]}/notes", user, admin_mode: user.admin?), params: params

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
      when 'groups'
        context 'by a group owner' do
          it 'sets the creation time on the new note' do
            post api("/#{parent_type}/#{parent.id}/#{noteable_type}/#{noteable[id_name]}/notes", user, admin_mode: user.admin?), params: params

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
        post api("/#{parent_type}/#{parent.id}/#{noteable_type}/#{noteable[id_name]}/notes", user, admin_mode: user.admin?), params: { body: ':+1:' }

        expect(response).to have_gitlab_http_status(:created)
        expect(json_response['body']).to eq(':+1:')
      end
    end

    context 'when user does not have access to read the noteable' do
      before do
        parent.update!(visibility_level: Gitlab::VisibilityLevel::PRIVATE)
      end

      it 'responds with 404' do
        post api("/#{parent_type}/#{parent.id}/#{noteable_type}/#{noteable[id_name]}/notes", private_user, admin_mode: private_user.admin?),
          params: { body: 'Foo' }

        expect(response).to have_gitlab_http_status(:not_found)
      end
    end

    context 'when request exceeds the rate limit', :freeze_time, :clean_gitlab_redis_rate_limiting do
      before do
        stub_application_setting(notes_create_limit: 1)
        allow_next_instance_of(Gitlab::ApplicationRateLimiter::BaseStrategy) do |strategy|
          allow(strategy).to receive(:increment).and_return(2)
        end
      end

      it 'prevents user from creating more notes' do
        subject

        expect(response).to have_gitlab_http_status(:too_many_requests)
        expect(json_response['message']['error']).to eq('This endpoint has been requested too many times. Try again later.')
      end

      it 'allows user in allow-list to create notes' do
        stub_application_setting(notes_create_limit_allowlist: [user.username.to_s])
        subject

        expect(response).to have_gitlab_http_status(:created)
        expect(json_response['body']).to eq('hi!')
        expect(json_response['author']['username']).to eq(user.username)
      end
    end
  end

  describe "PUT /#{parent_type}/:id/#{noteable_type}/:noteable_id/notes/:note_id", :aggregate_failures do
    let(:params) { { body: 'Hello!' } }

    subject do
      put api("/#{parent_type}/#{parent.id}/#{noteable_type}/#{noteable[id_name]}/notes/#{note.id}", user, admin_mode: user.admin?), params: params
    end

    context 'when only body param is present' do
      let(:params) { { body: 'Hello!' } }

      it 'updates the note text' do
        subject

        expect(note.reload.note).to eq('Hello!')
        expect(response).to have_gitlab_http_status(:ok)
        expect(json_response['body']).to eq('Hello!')
      end
    end

    context 'when confidential param is present' do
      let(:params) { { confidential: true } }

      it 'does not allow to change confidentiality' do
        expect { subject }.not_to change { note.reload.note }

        expect(response).to have_gitlab_http_status(:bad_request)
      end
    end

    it 'returns a 404 error when note id not found' do
      put api("/#{parent_type}/#{parent.id}/#{noteable_type}/#{noteable[id_name]}/notes/#{non_existing_record_id}", user, admin_mode: user.admin?),
        params: { body: 'Hello!' }

      expect(response).to have_gitlab_http_status(:not_found)
    end

    it 'returns a 400 bad request error if body is empty' do
      put api("/#{parent_type}/#{parent.id}/#{noteable_type}/#{noteable[id_name]}/"\
                "notes/#{note.id}", user, admin_mode: user.admin?), params: { body: '' }

      expect(response).to have_gitlab_http_status(:bad_request)
    end
  end

  describe "DELETE /#{parent_type}/:id/#{noteable_type}/:noteable_id/notes/:note_id", :aggregate_failures do
    it 'deletes a note' do
      delete api("/#{parent_type}/#{parent.id}/#{noteable_type}/#{noteable[id_name]}/"\
                 "notes/#{note.id}", user, admin_mode: user.admin?)

      expect(response).to have_gitlab_http_status(:no_content)
      # Check if note is really deleted
      delete api("/#{parent_type}/#{parent.id}/#{noteable_type}/#{noteable[id_name]}/"\
                 "notes/#{note.id}", user, admin_mode: user.admin?)
      expect(response).to have_gitlab_http_status(:not_found)
    end

    it 'returns a 404 error when note id not found' do
      delete api("/#{parent_type}/#{parent.id}/#{noteable_type}/#{noteable[id_name]}/notes/#{non_existing_record_id}", user, admin_mode: user.admin?)

      expect(response).to have_gitlab_http_status(:not_found)
    end

    it_behaves_like '412 response' do
      let(:request) { api("/#{parent_type}/#{parent.id}/#{noteable_type}/#{noteable[id_name]}/notes/#{note.id}", user, admin_mode: user.admin?) }
    end
  end
end

RSpec.shared_examples 'noteable API with confidential notes' do |parent_type, noteable_type, id_name|
  it_behaves_like 'noteable API', parent_type, noteable_type, id_name

  describe "POST /#{parent_type}/:id/#{noteable_type}/:noteable_id/notes", :aggregate_failures do
    let(:params) { { body: 'hi!' } }

    subject do
      post api("/#{parent_type}/#{parent.id}/#{noteable_type}/#{noteable[id_name]}/notes", user, admin_mode: user.admin?), params: params
    end

    context 'with internal param' do
      it "creates a confidential note if internal is set to true" do
        post api("/#{parent_type}/#{parent.id}/#{noteable_type}/#{noteable[id_name]}/notes", user, admin_mode: user.admin?), params: params.merge(internal: true)

        expect(response).to have_gitlab_http_status(:created)
        expect(json_response['body']).to eq('hi!')
        expect(json_response['confidential']).to be_truthy
        expect(json_response['internal']).to be_truthy
        expect(json_response['author']['username']).to eq(user.username)
      end
    end

    context 'with deprecated confidential param' do
      it "creates a confidential note if confidential is set to true" do
        post api("/#{parent_type}/#{parent.id}/#{noteable_type}/#{noteable[id_name]}/notes", user, admin_mode: user.admin?), params: params.merge(confidential: true)

        expect(response).to have_gitlab_http_status(:created)
        expect(json_response['body']).to eq('hi!')
        expect(json_response['confidential']).to be_truthy
        expect(json_response['internal']).to be_truthy
        expect(json_response['author']['username']).to eq(user.username)
      end
    end
  end
end
