# frozen_string_literal: true

RSpec.shared_examples 'with cross-reference system notes' do
  let_it_be(:user) { create(:user) }
  let_it_be(:pat) { create(:personal_access_token, user: user) }
  let_it_be(:project) { create(:project, :small_repo, developers: user) }
  let_it_be(:project2) { create(:project, :small_repo, developers: user) }
  let_it_be(:project3) { create(:project, :small_repo) }

  let_it_be(:merge_request) { create(:merge_request, source_project: project) }
  let_it_be(:new_merge_request) { create(:merge_request, source_project: project2) }
  let_it_be(:hidden_merge_request) { create(:merge_request, source_project: project3) }

  let!(:note) { create(:system_note, noteable: merge_request, project: project, note: cross_reference) }
  let!(:note_metadata) { create(:system_note_metadata, note: note, action: 'cross_reference') }
  let(:cross_reference) { "test commit #{commit.to_reference(project)}" }
  let(:commit) { new_merge_request.project.commit }

  let!(:new_note) { create(:system_note, noteable: merge_request, project: project, note: hidden_cross_reference) }
  let!(:new_note_metadata) { create(:system_note_metadata, note: new_note, action: 'cross_reference') }
  let(:hidden_cross_reference) { "test commit #{hidden_commit.to_reference(project)}" }
  let(:hidden_commit) { hidden_merge_request.project.commit }

  it 'returns only the note that the user should see' do
    get api(url, user, personal_access_token: pat)

    expect(response).to have_gitlab_http_status(:ok)
    expect(json_response.count).to eq(1)
    expect(notes_in_response.count).to eq(1)

    parsed_note = notes_in_response.first
    expect(parsed_note['id']).to eq(note.id)
    expect(parsed_note['body']).to eq(cross_reference)
    expect(parsed_note['system']).to be true
  end

  it 'avoids Git calls and N+1 SQL queries', :request_store do
    expect_any_instance_of(Repository).not_to receive(:find_commit).with(commit.id)

    # Ensure last_used_at doesn't get updated later to skew the results
    get api(url, user, personal_access_token: pat)
    # Clear cached permission checks so the control doesn't have skewed results
    RequestStore.clear!

    control = ActiveRecord::QueryRecorder.new do
      get api(url, user, personal_access_token: pat)
    end

    expect(response).to have_gitlab_http_status(:ok)

    RequestStore.clear!

    new_note = create(:system_note, noteable: merge_request, project: project, note: cross_reference)
    create(:system_note_metadata, note: new_note, action: 'cross_reference')

    RequestStore.clear!

    expect { get api(url, user, personal_access_token: pat) }.not_to exceed_query_limit(control)
    expect(response).to have_gitlab_http_status(:ok)
  end
end

RSpec.shared_examples 'discussions API' do |parent_type, noteable_type, id_name, can_reply_to_individual_notes: false|
  describe "GET /#{parent_type}/:id/#{noteable_type}/:noteable_id/discussions" do
    it "returns an array of discussions" do
      get api("/#{parent_type}/#{parent.id}/#{noteable_type}/#{noteable[id_name]}/discussions", user)

      expect(response).to have_gitlab_http_status(:ok)
      expect(response).to include_pagination_headers
      expect(json_response).to be_an Array
      expect(json_response.first['id']).to eq(note.discussion_id)
    end

    it "returns a 404 error when noteable id not found" do
      get api("/#{parent_type}/#{parent.id}/#{noteable_type}/#{non_existing_record_iid}/discussions", user)

      expect(response).to have_gitlab_http_status(:not_found)
    end

    it "returns 404 when not authorized" do
      parent.update!(visibility_level: Gitlab::VisibilityLevel::PRIVATE)

      get api("/#{parent_type}/#{parent.id}/#{noteable_type}/#{noteable[id_name]}/discussions", private_user)

      expect(response).to have_gitlab_http_status(:not_found)
    end
  end

  describe "GET /#{parent_type}/:id/#{noteable_type}/:noteable_id/discussions/:discussion_id" do
    it "returns a discussion by id" do
      get api("/#{parent_type}/#{parent.id}/#{noteable_type}/#{noteable[id_name]}/discussions/#{note.discussion_id}", user)

      expect(response).to have_gitlab_http_status(:ok)
      expect(json_response['id']).to eq(note.discussion_id)
      expect(json_response['notes'].first['body']).to eq(note.note)
    end

    it "returns a 404 error if discussion not found" do
      get api("/#{parent_type}/#{parent.id}/#{noteable_type}/#{noteable[id_name]}/discussions/#{non_existing_record_id}", user)

      expect(response).to have_gitlab_http_status(:not_found)
    end
  end

  describe "POST /#{parent_type}/:id/#{noteable_type}/:noteable_id/discussions" do
    it "creates a new note" do
      post api("/#{parent_type}/#{parent.id}/#{noteable_type}/#{noteable[id_name]}/discussions", user), params: { body: 'hi!' }

      expect(response).to have_gitlab_http_status(:created)
      expect(json_response['notes'].first['body']).to eq('hi!')
      expect(json_response['notes'].first['author']['username']).to eq(user.username)
    end

    it "creates a quick action" do
      next unless %w[issues merge_requests].include?(noteable_type)

      post api("/#{parent_type}/#{parent.id}/#{noteable_type}/#{noteable[id_name]}/discussions", user), params: { body: '/spend 1d' }

      expect(response).to have_gitlab_http_status(:accepted)
      expect(json_response['commands_changes']).to be_present
      expect(json_response['commands_changes']).to include('spend_time')
      expect(json_response['summary']).to eq(['Added 1d spent time.'])
    end

    it "returns a 400 bad request error if quick action is invalid" do
      next unless %w[issues merge_requests].include?(noteable_type)

      post api("/#{parent_type}/#{parent.id}/#{noteable_type}/#{noteable[id_name]}/discussions", user), params: { body: '/spend something' }

      expect(response).to have_gitlab_http_status(:bad_request)
      expect(json_response['message']).to eq('400 Bad request - Failed to apply commands.')
    end

    it "returns a 400 bad request error if body not given" do
      post api("/#{parent_type}/#{parent.id}/#{noteable_type}/#{noteable[id_name]}/discussions", user)

      expect(response).to have_gitlab_http_status(:bad_request)
    end

    it "returns a 401 unauthorized error if user not authenticated" do
      post api("/#{parent_type}/#{parent.id}/#{noteable_type}/#{noteable[id_name]}/discussions"), params: { body: 'hi!' }

      expect(response).to have_gitlab_http_status(:unauthorized)
    end

    context 'when an admin or owner makes the request' do
      it 'accepts the creation date to be set' do
        creation_time = 2.weeks.ago
        post api("/#{parent_type}/#{parent.id}/#{noteable_type}/#{noteable[id_name]}/discussions", user),
          params: { body: 'hi!', created_at: creation_time }

        expect(response).to have_gitlab_http_status(:created)
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
          params: { body: 'Foo' }

        expect(response).to have_gitlab_http_status(:not_found)
      end
    end

    context 'when a project is public with private repo access' do
      let!(:parent) { create(:project, :public, :repository, :repository_private, :snippets_private) }
      let!(:user_without_access) { create(:user) }

      context 'when user is not a team member of private repo' do
        before do
          project.team.truncate
        end

        context "creating a new note" do
          before do
            post api("/#{parent_type}/#{parent.id}/#{noteable_type}/#{noteable[id_name]}/discussions", user_without_access), params: { body: 'hi!' }
          end

          it 'raises 404 error' do
            expect(response).to have_gitlab_http_status(:not_found)
          end
        end

        context "fetching a discussion" do
          before do
            get api("/#{parent_type}/#{parent.id}/#{noteable_type}/#{noteable[id_name]}/discussions/#{note.discussion_id}", user_without_access)
          end

          it 'raises 404 error' do
            expect(response).to have_gitlab_http_status(:not_found)
          end
        end
      end
    end
  end

  describe "POST /#{parent_type}/:id/#{noteable_type}/:noteable_id/discussions/:discussion_id/notes" do
    it 'adds a new note to the discussion' do
      post api("/#{parent_type}/#{parent.id}/#{noteable_type}/#{noteable[id_name]}/"\
               "discussions/#{note.discussion_id}/notes", user), params: { body: 'Hello!' }

      expect(response).to have_gitlab_http_status(:created)
      expect(json_response['body']).to eq('Hello!')
      expect(json_response['type']).to eq('DiscussionNote')
    end

    it 'adds a quick-action only note to the discussion' do
      next unless %w[issues merge_requests].include?(noteable_type)

      post api("/#{parent_type}/#{parent.id}/#{noteable_type}/#{noteable[id_name]}/"\
               "discussions/#{note.discussion_id}/notes", user), params: { body: '/spend 1d' }

      expect(response).to have_gitlab_http_status(:accepted)
      expect(json_response['commands_changes']).to be_present
      expect(json_response['commands_changes']).to include('spend_time')
      expect(json_response['summary']).to eq(['Added 1d spent time.'])
    end

    it 'returns a 400 bad request error if body not given' do
      post api("/#{parent_type}/#{parent.id}/#{noteable_type}/#{noteable[id_name]}/"\
               "discussions/#{note.discussion_id}/notes", user)

      expect(response).to have_gitlab_http_status(:bad_request)
    end

    context 'when the discussion is an individual note' do
      before do
        note.update!(type: nil)

        post api("/#{parent_type}/#{parent.id}/#{noteable_type}/#{noteable[id_name]}/"\
                 "discussions/#{note.discussion_id}/notes", user), params: { body: 'hi!' }
      end

      if can_reply_to_individual_notes
        it 'creates a new discussion' do
          expect(response).to have_gitlab_http_status(:created)
          expect(json_response['body']).to eq('hi!')
          expect(json_response['type']).to eq('DiscussionNote')
        end
      else
        it 'returns 400 bad request' do
          expect(response).to have_gitlab_http_status(:bad_request)
        end
      end
    end
  end

  describe "PUT /#{parent_type}/:id/#{noteable_type}/:noteable_id/discussions/:discussion_id/notes/:note_id" do
    it 'returns modified note' do
      put api("/#{parent_type}/#{parent.id}/#{noteable_type}/#{noteable[id_name]}/"\
              "discussions/#{note.discussion_id}/notes/#{note.id}", user), params: { body: 'Hello!' }

      expect(response).to have_gitlab_http_status(:ok)
      expect(json_response['body']).to eq('Hello!')
    end

    it 'returns a 404 error when note id not found' do
      put api("/#{parent_type}/#{parent.id}/#{noteable_type}/#{noteable[id_name]}/"\
              "discussions/#{note.discussion_id}/notes/#{non_existing_record_id}", user), params: { body: 'Hello!' }

      expect(response).to have_gitlab_http_status(:not_found)
    end

    it 'returns a 202 if note is modified with only quick actions' do
      next unless %w[issues merge_requests].include?(noteable_type)

      put api("/#{parent_type}/#{parent.id}/#{noteable_type}/#{noteable[id_name]}/"\
              "discussions/#{note.discussion_id}/notes/#{note.id}", user), params: { body: '/spend 1d' }

      expect(response).to have_gitlab_http_status(:accepted)
      expect(json_response['commands_changes']).to be_present
      expect(json_response['commands_changes']).to include('spend_time')
      expect(json_response['summary']).to eq(['Added 1d spent time.'])
    end

    it 'returns a 400 bad request error if body not given' do
      put api("/#{parent_type}/#{parent.id}/#{noteable_type}/#{noteable[id_name]}/"\
              "discussions/#{note.discussion_id}/notes/#{note.id}", user)

      expect(response).to have_gitlab_http_status(:bad_request)
    end
  end

  describe "DELETE /#{parent_type}/:id/#{noteable_type}/:noteable_id/discussions/:discussion_id/notes/:note_id" do
    it 'deletes a note' do
      delete api("/#{parent_type}/#{parent.id}/#{noteable_type}/#{noteable[id_name]}/"\
                 "discussions/#{note.discussion_id}/notes/#{note.id}", user)

      expect(response).to have_gitlab_http_status(:no_content)
      # Check if note is really deleted
      delete api("/#{parent_type}/#{parent.id}/#{noteable_type}/#{noteable[id_name]}/"\
                 "discussions/#{note.discussion_id}/notes/#{note.id}", user)
      expect(response).to have_gitlab_http_status(:not_found)
    end

    it 'returns a 404 error when note id not found' do
      delete api("/#{parent_type}/#{parent.id}/#{noteable_type}/#{noteable[id_name]}/"\
                 "discussions/#{note.discussion_id}/notes/#{non_existing_record_id}", user)

      expect(response).to have_gitlab_http_status(:not_found)
    end

    it_behaves_like '412 response' do
      let(:request) do
        api("/#{parent_type}/#{parent.id}/#{noteable_type}/#{noteable[id_name]}/"\
            "discussions/#{note.discussion_id}/notes/#{note.id}", user)
      end
    end
  end
end
