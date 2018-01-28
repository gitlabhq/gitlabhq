require 'spec_helper'

describe API::Notes do
  let(:user) { create(:user) }
  let!(:project) { create(:project, :public, namespace: user.namespace) }
  let!(:issue) { create(:issue, project: project, author: user) }
  let!(:merge_request) { create(:merge_request, source_project: project, target_project: project, author: user) }
  let!(:snippet) { create(:project_snippet, project: project, author: user) }
  let!(:issue_note) { create(:note, noteable: issue, project: project, author: user) }
  let!(:merge_request_note) { create(:note, noteable: merge_request, project: project, author: user) }
  let!(:snippet_note) { create(:note, noteable: snippet, project: project, author: user) }

  # For testing the cross-reference of a private issue in a public issue
  let(:private_user)    { create(:user) }
  let(:private_project) do
    create(:project, namespace: private_user.namespace)
    .tap { |p| p.add_master(private_user) }
  end
  let(:private_issue)    { create(:issue, project: private_project) }

  let(:ext_proj)  { create(:project, :public) }
  let(:ext_issue) { create(:issue, project: ext_proj) }

  let!(:cross_reference_note) do
    create :note,
    noteable: ext_issue, project: ext_proj,
    note: "mentioned in issue #{private_issue.to_reference(ext_proj)}",
    system: true
  end

  before do
    project.add_reporter(user)
  end

  describe "GET /projects/:id/noteable/:noteable_id/notes" do
    context "when noteable is an Issue" do
      context 'sorting' do
        before do
          create_list(:note, 3, noteable: issue, project: project, author: user)
        end

        it 'sorts by created_at in descending order by default' do
          get api("/projects/#{project.id}/issues/#{issue.iid}/notes", user)

          response_dates = json_response.map { |noteable| noteable['created_at'] }

          expect(json_response.length).to eq(4)
          expect(response_dates).to eq(response_dates.sort.reverse)
        end

        it 'sorts by ascending order when requested' do
          get api("/projects/#{project.id}/issues/#{issue.iid}/notes?sort=asc", user)

          response_dates = json_response.map { |noteable| noteable['created_at'] }

          expect(json_response.length).to eq(4)
          expect(response_dates).to eq(response_dates.sort)
        end

        it 'sorts by updated_at in descending order when requested' do
          get api("/projects/#{project.id}/issues/#{issue.iid}/notes?order_by=updated_at", user)

          response_dates = json_response.map { |noteable| noteable['updated_at'] }

          expect(json_response.length).to eq(4)
          expect(response_dates).to eq(response_dates.sort.reverse)
        end

        it 'sorts by updated_at in ascending order when requested' do
          get api("/projects/#{project.id}/issues/#{issue.iid}/notes??order_by=updated_at&sort=asc", user)

          response_dates = json_response.map { |noteable| noteable['updated_at'] }

          expect(json_response.length).to eq(4)
          expect(response_dates).to eq(response_dates.sort)
        end
      end

      it "returns an array of issue notes" do
        get api("/projects/#{project.id}/issues/#{issue.iid}/notes", user)

        expect(response).to have_gitlab_http_status(200)
        expect(response).to include_pagination_headers
        expect(json_response).to be_an Array
        expect(json_response.first['body']).to eq(issue_note.note)
      end

      it "returns a 404 error when issue id not found" do
        get api("/projects/#{project.id}/issues/12345/notes", user)

        expect(response).to have_gitlab_http_status(404)
      end

      context "and current user cannot view the notes" do
        it "returns an empty array" do
          get api("/projects/#{ext_proj.id}/issues/#{ext_issue.iid}/notes", user)

          expect(response).to have_gitlab_http_status(200)
          expect(response).to include_pagination_headers
          expect(json_response).to be_an Array
          expect(json_response).to be_empty
        end

        context "and issue is confidential" do
          before do
            ext_issue.update_attributes(confidential: true)
          end

          it "returns 404" do
            get api("/projects/#{ext_proj.id}/issues/#{ext_issue.iid}/notes", user)

            expect(response).to have_gitlab_http_status(404)
          end
        end

        context "and current user can view the note" do
          it "returns an empty array" do
            get api("/projects/#{ext_proj.id}/issues/#{ext_issue.iid}/notes", private_user)

            expect(response).to have_gitlab_http_status(200)
            expect(response).to include_pagination_headers
            expect(json_response).to be_an Array
            expect(json_response.first['body']).to eq(cross_reference_note.note)
          end
        end
      end
    end

    context "when noteable is a Snippet" do
      context 'sorting' do
        before do
          create_list(:note, 3, noteable: snippet, project: project, author: user)
        end

        it 'sorts by created_at in descending order by default' do
          get api("/projects/#{project.id}/snippets/#{snippet.id}/notes", user)

          response_dates = json_response.map { |noteable| noteable['created_at'] }

          expect(json_response.length).to eq(4)
          expect(response_dates).to eq(response_dates.sort.reverse)
        end

        it 'sorts by ascending order when requested' do
          get api("/projects/#{project.id}/snippets/#{snippet.id}/notes?sort=asc", user)

          response_dates = json_response.map { |noteable| noteable['created_at'] }

          expect(json_response.length).to eq(4)
          expect(response_dates).to eq(response_dates.sort)
        end

        it 'sorts by updated_at in descending order when requested' do
          get api("/projects/#{project.id}/snippets/#{snippet.id}/notes?order_by=updated_at", user)

          response_dates = json_response.map { |noteable| noteable['updated_at'] }

          expect(json_response.length).to eq(4)
          expect(response_dates).to eq(response_dates.sort.reverse)
        end

        it 'sorts by updated_at in ascending order when requested' do
          get api("/projects/#{project.id}/snippets/#{snippet.id}/notes??order_by=updated_at&sort=asc", user)

          response_dates = json_response.map { |noteable| noteable['updated_at'] }

          expect(json_response.length).to eq(4)
          expect(response_dates).to eq(response_dates.sort)
        end
      end
      it "returns an array of snippet notes" do
        get api("/projects/#{project.id}/snippets/#{snippet.id}/notes", user)

        expect(response).to have_gitlab_http_status(200)
        expect(response).to include_pagination_headers
        expect(json_response).to be_an Array
        expect(json_response.first['body']).to eq(snippet_note.note)
      end

      it "returns a 404 error when snippet id not found" do
        get api("/projects/#{project.id}/snippets/42/notes", user)

        expect(response).to have_gitlab_http_status(404)
      end

      it "returns 404 when not authorized" do
        get api("/projects/#{project.id}/snippets/#{snippet.id}/notes", private_user)

        expect(response).to have_gitlab_http_status(404)
      end
    end

    context "when noteable is a Merge Request" do
      context 'sorting' do
        before do
          create_list(:note, 3, noteable: merge_request, project: project, author: user)
        end

        it 'sorts by created_at in descending order by default' do
          get api("/projects/#{project.id}/merge_requests/#{merge_request.iid}/notes", user)

          response_dates = json_response.map { |noteable| noteable['created_at'] }

          expect(json_response.length).to eq(4)
          expect(response_dates).to eq(response_dates.sort.reverse)
        end

        it 'sorts by ascending order when requested' do
          get api("/projects/#{project.id}/merge_requests/#{merge_request.iid}/notes?sort=asc", user)

          response_dates = json_response.map { |noteable| noteable['created_at'] }

          expect(json_response.length).to eq(4)
          expect(response_dates).to eq(response_dates.sort)
        end

        it 'sorts by updated_at in descending order when requested' do
          get api("/projects/#{project.id}/merge_requests/#{merge_request.iid}/notes?order_by=updated_at", user)

          response_dates = json_response.map { |noteable| noteable['updated_at'] }

          expect(json_response.length).to eq(4)
          expect(response_dates).to eq(response_dates.sort.reverse)
        end

        it 'sorts by updated_at in ascending order when requested' do
          get api("/projects/#{project.id}/merge_requests/#{merge_request.iid}/notes??order_by=updated_at&sort=asc", user)

          response_dates = json_response.map { |noteable| noteable['updated_at'] }

          expect(json_response.length).to eq(4)
          expect(response_dates).to eq(response_dates.sort)
        end
      end
      it "returns an array of merge_requests notes" do
        get api("/projects/#{project.id}/merge_requests/#{merge_request.iid}/notes", user)

        expect(response).to have_gitlab_http_status(200)
        expect(response).to include_pagination_headers
        expect(json_response).to be_an Array
        expect(json_response.first['body']).to eq(merge_request_note.note)
      end

      it "returns a 404 error if merge request id not found" do
        get api("/projects/#{project.id}/merge_requests/4444/notes", user)

        expect(response).to have_gitlab_http_status(404)
      end

      it "returns 404 when not authorized" do
        get api("/projects/#{project.id}/merge_requests/4444/notes", private_user)

        expect(response).to have_gitlab_http_status(404)
      end
    end
  end

  describe "GET /projects/:id/noteable/:noteable_id/notes/:note_id" do
    context "when noteable is an Issue" do
      it "returns an issue note by id" do
        get api("/projects/#{project.id}/issues/#{issue.iid}/notes/#{issue_note.id}", user)

        expect(response).to have_gitlab_http_status(200)
        expect(json_response['body']).to eq(issue_note.note)
      end

      it "returns a 404 error if issue note not found" do
        get api("/projects/#{project.id}/issues/#{issue.iid}/notes/12345", user)

        expect(response).to have_gitlab_http_status(404)
      end

      context "and current user cannot view the note" do
        it "returns a 404 error" do
          get api("/projects/#{ext_proj.id}/issues/#{ext_issue.iid}/notes/#{cross_reference_note.id}", user)

          expect(response).to have_gitlab_http_status(404)
        end

        context "when issue is confidential" do
          before do
            issue.update_attributes(confidential: true)
          end

          it "returns 404" do
            get api("/projects/#{project.id}/issues/#{issue.iid}/notes/#{issue_note.id}", private_user)

            expect(response).to have_gitlab_http_status(404)
          end
        end

        context "and current user can view the note" do
          it "returns an issue note by id" do
            get api("/projects/#{ext_proj.id}/issues/#{ext_issue.iid}/notes/#{cross_reference_note.id}", private_user)

            expect(response).to have_gitlab_http_status(200)
            expect(json_response['body']).to eq(cross_reference_note.note)
          end
        end
      end
    end

    context "when noteable is a Snippet" do
      it "returns a snippet note by id" do
        get api("/projects/#{project.id}/snippets/#{snippet.id}/notes/#{snippet_note.id}", user)

        expect(response).to have_gitlab_http_status(200)
        expect(json_response['body']).to eq(snippet_note.note)
      end

      it "returns a 404 error if snippet note not found" do
        get api("/projects/#{project.id}/snippets/#{snippet.id}/notes/12345", user)

        expect(response).to have_gitlab_http_status(404)
      end
    end
  end

  describe "POST /projects/:id/noteable/:noteable_id/notes" do
    context "when noteable is an Issue" do
      it "creates a new issue note" do
        post api("/projects/#{project.id}/issues/#{issue.iid}/notes", user), body: 'hi!'

        expect(response).to have_gitlab_http_status(201)
        expect(json_response['body']).to eq('hi!')
        expect(json_response['author']['username']).to eq(user.username)
      end

      it "returns a 400 bad request error if body not given" do
        post api("/projects/#{project.id}/issues/#{issue.iid}/notes", user)

        expect(response).to have_gitlab_http_status(400)
      end

      it "returns a 401 unauthorized error if user not authenticated" do
        post api("/projects/#{project.id}/issues/#{issue.iid}/notes"), body: 'hi!'

        expect(response).to have_gitlab_http_status(401)
      end

      context 'when an admin or owner makes the request' do
        it 'accepts the creation date to be set' do
          creation_time = 2.weeks.ago
          post api("/projects/#{project.id}/issues/#{issue.iid}/notes", user),
            body: 'hi!', created_at: creation_time

          expect(response).to have_gitlab_http_status(201)
          expect(json_response['body']).to eq('hi!')
          expect(json_response['author']['username']).to eq(user.username)
          expect(Time.parse(json_response['created_at'])).to be_like_time(creation_time)
        end
      end

      context 'when the user is posting an award emoji on an issue created by someone else' do
        let(:issue2) { create(:issue, project: project) }

        it 'creates a new issue note' do
          post api("/projects/#{project.id}/issues/#{issue2.iid}/notes", user), body: ':+1:'

          expect(response).to have_gitlab_http_status(201)
          expect(json_response['body']).to eq(':+1:')
        end
      end

      context 'when the user is posting an award emoji on his/her own issue' do
        it 'creates a new issue note' do
          post api("/projects/#{project.id}/issues/#{issue.iid}/notes", user), body: ':+1:'

          expect(response).to have_gitlab_http_status(201)
          expect(json_response['body']).to eq(':+1:')
        end
      end
    end

    context "when noteable is a Snippet" do
      it "creates a new snippet note" do
        post api("/projects/#{project.id}/snippets/#{snippet.id}/notes", user), body: 'hi!'

        expect(response).to have_gitlab_http_status(201)
        expect(json_response['body']).to eq('hi!')
        expect(json_response['author']['username']).to eq(user.username)
      end

      it "returns a 400 bad request error if body not given" do
        post api("/projects/#{project.id}/snippets/#{snippet.id}/notes", user)

        expect(response).to have_gitlab_http_status(400)
      end

      it "returns a 401 unauthorized error if user not authenticated" do
        post api("/projects/#{project.id}/snippets/#{snippet.id}/notes"), body: 'hi!'

        expect(response).to have_gitlab_http_status(401)
      end
    end

    context 'when user does not have access to read the noteable' do
      it 'responds with 404' do
        project = create(:project, :private) { |p| p.add_guest(user) }
        issue = create(:issue, :confidential, project: project)

        post api("/projects/#{project.id}/issues/#{issue.iid}/notes", user),
          body: 'Foo'

        expect(response).to have_gitlab_http_status(404)
      end
    end

    context 'when user does not have access to create noteable' do
      let(:private_issue) { create(:issue, project: create(:project, :private)) }

      ##
      # We are posting to project user has access to, but we use issue id
      # from a different project, see #15577
      #
      before do
        post api("/projects/#{private_issue.project.id}/issues/#{private_issue.iid}/notes", user),
             body: 'Hi!'
      end

      it 'responds with resource not found error' do
        expect(response.status).to eq 404
      end

      it 'does not create new note' do
        expect(private_issue.notes.reload).to be_empty
      end
    end

    context 'when the merge request discussion is locked' do
      before do
        merge_request.update_attribute(:discussion_locked, true)
      end

      context 'when a user is a team member' do
        subject { post api("/projects/#{project.id}/merge_requests/#{merge_request.iid}/notes", user), body: 'Hi!' }

        it 'returns 200 status' do
          subject

          expect(response).to have_gitlab_http_status(201)
        end

        it 'creates a new note' do
          expect { subject }.to change { Note.count }.by(1)
        end
      end

      context 'when a user is not a team member' do
        subject { post api("/projects/#{project.id}/merge_requests/#{merge_request.iid}/notes", private_user), body: 'Hi!' }

        it 'returns 403 status' do
          subject

          expect(response).to have_gitlab_http_status(403)
        end

        it 'does not create a new note' do
          expect { subject }.not_to change { Note.count }
        end
      end
    end
  end

  describe "POST /projects/:id/noteable/:noteable_id/notes to test observer on create" do
    it "creates an activity event when an issue note is created" do
      expect(Event).to receive(:create!)

      post api("/projects/#{project.id}/issues/#{issue.iid}/notes", user), body: 'hi!'
    end
  end

  describe 'PUT /projects/:id/noteable/:noteable_id/notes/:note_id' do
    context 'when noteable is an Issue' do
      it 'returns modified note' do
        put api("/projects/#{project.id}/issues/#{issue.iid}/"\
                  "notes/#{issue_note.id}", user), body: 'Hello!'

        expect(response).to have_gitlab_http_status(200)
        expect(json_response['body']).to eq('Hello!')
      end

      it 'returns a 404 error when note id not found' do
        put api("/projects/#{project.id}/issues/#{issue.iid}/notes/12345", user),
                body: 'Hello!'

        expect(response).to have_gitlab_http_status(404)
      end

      it 'returns a 400 bad request error if body not given' do
        put api("/projects/#{project.id}/issues/#{issue.iid}/"\
                  "notes/#{issue_note.id}", user)

        expect(response).to have_gitlab_http_status(400)
      end
    end

    context 'when noteable is a Snippet' do
      it 'returns modified note' do
        put api("/projects/#{project.id}/snippets/#{snippet.id}/"\
                  "notes/#{snippet_note.id}", user), body: 'Hello!'

        expect(response).to have_gitlab_http_status(200)
        expect(json_response['body']).to eq('Hello!')
      end

      it 'returns a 404 error when note id not found' do
        put api("/projects/#{project.id}/snippets/#{snippet.id}/"\
                  "notes/12345", user), body: "Hello!"

        expect(response).to have_gitlab_http_status(404)
      end
    end

    context 'when noteable is a Merge Request' do
      it 'returns modified note' do
        put api("/projects/#{project.id}/merge_requests/#{merge_request.iid}/"\
                  "notes/#{merge_request_note.id}", user), body: 'Hello!'

        expect(response).to have_gitlab_http_status(200)
        expect(json_response['body']).to eq('Hello!')
      end

      it 'returns a 404 error when note id not found' do
        put api("/projects/#{project.id}/merge_requests/#{merge_request.iid}/"\
                  "notes/12345", user), body: "Hello!"

        expect(response).to have_gitlab_http_status(404)
      end
    end
  end

  describe 'DELETE /projects/:id/noteable/:noteable_id/notes/:note_id' do
    context 'when noteable is an Issue' do
      it 'deletes a note' do
        delete api("/projects/#{project.id}/issues/#{issue.iid}/"\
                   "notes/#{issue_note.id}", user)

        expect(response).to have_gitlab_http_status(204)
        # Check if note is really deleted
        delete api("/projects/#{project.id}/issues/#{issue.iid}/"\
                   "notes/#{issue_note.id}", user)
        expect(response).to have_gitlab_http_status(404)
      end

      it 'returns a 404 error when note id not found' do
        delete api("/projects/#{project.id}/issues/#{issue.iid}/notes/12345", user)

        expect(response).to have_gitlab_http_status(404)
      end

      it_behaves_like '412 response' do
        let(:request) { api("/projects/#{project.id}/issues/#{issue.iid}/notes/#{issue_note.id}", user) }
      end
    end

    context 'when noteable is a Snippet' do
      it 'deletes a note' do
        delete api("/projects/#{project.id}/snippets/#{snippet.id}/"\
                   "notes/#{snippet_note.id}", user)

        expect(response).to have_gitlab_http_status(204)
        # Check if note is really deleted
        delete api("/projects/#{project.id}/snippets/#{snippet.id}/"\
                   "notes/#{snippet_note.id}", user)
        expect(response).to have_gitlab_http_status(404)
      end

      it 'returns a 404 error when note id not found' do
        delete api("/projects/#{project.id}/snippets/#{snippet.id}/"\
                   "notes/12345", user)

        expect(response).to have_gitlab_http_status(404)
      end

      it_behaves_like '412 response' do
        let(:request) { api("/projects/#{project.id}/snippets/#{snippet.id}/notes/#{snippet_note.id}", user) }
      end
    end

    context 'when noteable is a Merge Request' do
      it 'deletes a note' do
        delete api("/projects/#{project.id}/merge_requests/"\
                   "#{merge_request.iid}/notes/#{merge_request_note.id}", user)

        expect(response).to have_gitlab_http_status(204)
        # Check if note is really deleted
        delete api("/projects/#{project.id}/merge_requests/"\
                   "#{merge_request.iid}/notes/#{merge_request_note.id}", user)
        expect(response).to have_gitlab_http_status(404)
      end

      it 'returns a 404 error when note id not found' do
        delete api("/projects/#{project.id}/merge_requests/"\
                   "#{merge_request.iid}/notes/12345", user)

        expect(response).to have_gitlab_http_status(404)
      end

      it_behaves_like '412 response' do
        let(:request) { api("/projects/#{project.id}/merge_requests/#{merge_request.iid}/notes/#{merge_request_note.id}", user) }
      end
    end
  end
end
