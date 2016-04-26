require 'spec_helper'

describe API::API, api: true  do
  include ApiHelpers
  let(:user) { create(:user) }
  let!(:project) { create(:project, namespace: user.namespace) }
  let!(:issue) { create(:issue, project: project, author: user) }
  let!(:merge_request) { create(:merge_request, source_project: project, target_project: project, author: user) }
  let!(:snippet) { create(:project_snippet, project: project, author: user) }
  let!(:issue_note) { create(:note, noteable: issue, project: project, author: user) }
  let!(:merge_request_note) { create(:note, noteable: merge_request, project: project, author: user) }
  let!(:snippet_note) { create(:note, noteable: snippet, project: project, author: user) }
  before { project.team << [user, :reporter] }

  describe "GET /projects/:id/noteable/:noteable_id/notes" do
    context "when noteable is an Issue" do
      it "should return an array of issue notes" do
        get api("/projects/#{project.id}/issues/#{issue.id}/notes", user)
        expect(response.status).to eq(200)
        expect(json_response).to be_an Array
        expect(json_response.first['body']).to eq(issue_note.note)
      end

      it "should return a 404 error when issue id not found" do
        get api("/projects/#{project.id}/issues/12345/notes", user)
        expect(response.status).to eq(404)
      end
    end

    context "when noteable is a Snippet" do
      it "should return an array of snippet notes" do
        get api("/projects/#{project.id}/snippets/#{snippet.id}/notes", user)
        expect(response.status).to eq(200)
        expect(json_response).to be_an Array
        expect(json_response.first['body']).to eq(snippet_note.note)
      end

      it "should return a 404 error when snippet id not found" do
        get api("/projects/#{project.id}/snippets/42/notes", user)
        expect(response.status).to eq(404)
      end
    end

    context "when noteable is a Merge Request" do
      it "should return an array of merge_requests notes" do
        get api("/projects/#{project.id}/merge_requests/#{merge_request.id}/notes", user)
        expect(response.status).to eq(200)
        expect(json_response).to be_an Array
        expect(json_response.first['body']).to eq(merge_request_note.note)
      end

      it "should return a 404 error if merge request id not found" do
        get api("/projects/#{project.id}/merge_requests/4444/notes", user)
        expect(response.status).to eq(404)
      end
    end
  end

  describe "GET /projects/:id/noteable/:noteable_id/notes/:note_id" do
    context "when noteable is an Issue" do
      it "should return an issue note by id" do
        get api("/projects/#{project.id}/issues/#{issue.id}/notes/#{issue_note.id}", user)
        expect(response.status).to eq(200)
        expect(json_response['body']).to eq(issue_note.note)
      end

      it "should return a 404 error if issue note not found" do
        get api("/projects/#{project.id}/issues/#{issue.id}/notes/12345", user)
        expect(response.status).to eq(404)
      end
    end

    context "when noteable is a Snippet" do
      it "should return a snippet note by id" do
        get api("/projects/#{project.id}/snippets/#{snippet.id}/notes/#{snippet_note.id}", user)
        expect(response.status).to eq(200)
        expect(json_response['body']).to eq(snippet_note.note)
      end

      it "should return a 404 error if snippet note not found" do
        get api("/projects/#{project.id}/snippets/#{snippet.id}/notes/12345", user)
        expect(response.status).to eq(404)
      end
    end
  end

  describe "POST /projects/:id/noteable/:noteable_id/notes" do
    context "when noteable is an Issue" do
      it "should create a new issue note" do
        post api("/projects/#{project.id}/issues/#{issue.id}/notes", user), body: 'hi!'
        expect(response.status).to eq(201)
        expect(json_response['body']).to eq('hi!')
        expect(json_response['author']['username']).to eq(user.username)
      end

      it "should return a 400 bad request error if body not given" do
        post api("/projects/#{project.id}/issues/#{issue.id}/notes", user)
        expect(response.status).to eq(400)
      end

      it "should return a 401 unauthorized error if user not authenticated" do
        post api("/projects/#{project.id}/issues/#{issue.id}/notes"), body: 'hi!'
        expect(response.status).to eq(401)
      end
    end

    context "when noteable is a Snippet" do
      it "should create a new snippet note" do
        post api("/projects/#{project.id}/snippets/#{snippet.id}/notes", user), body: 'hi!'
        expect(response.status).to eq(201)
        expect(json_response['body']).to eq('hi!')
        expect(json_response['author']['username']).to eq(user.username)
      end

      it "should return a 400 bad request error if body not given" do
        post api("/projects/#{project.id}/snippets/#{snippet.id}/notes", user)
        expect(response.status).to eq(400)
      end

      it "should return a 401 unauthorized error if user not authenticated" do
        post api("/projects/#{project.id}/snippets/#{snippet.id}/notes"), body: 'hi!'
        expect(response.status).to eq(401)
      end
    end

    context 'when user does not have access to create noteable' do
      let(:private_issue) { create(:issue, project: create(:project, :private)) }

      ##
      # We are posting to project user has access to, but we use issue id
      # from a different project, see #15577
      #
      before do
        post api("/projects/#{project.id}/issues/#{private_issue.id}/notes", user),
             body: 'Hi!'
      end

      it 'responds with 500' do
        expect(response.status).to eq 500
      end

      it 'does not create new note' do
        expect(private_issue.notes.reload).to be_empty
      end
    end
  end

  describe "POST /projects/:id/noteable/:noteable_id/notes to test observer on create" do
    it "should create an activity event when an issue note is created" do
      expect(Event).to receive(:create)

      post api("/projects/#{project.id}/issues/#{issue.id}/notes", user), body: 'hi!'
    end
  end

  describe 'PUT /projects/:id/noteable/:noteable_id/notes/:note_id' do
    context 'when noteable is an Issue' do
      it 'should return modified note' do
        put api("/projects/#{project.id}/issues/#{issue.id}/"\
                  "notes/#{issue_note.id}", user), body: 'Hello!'
        expect(response.status).to eq(200)
        expect(json_response['body']).to eq('Hello!')
      end

      it 'should return a 404 error when note id not found' do
        put api("/projects/#{project.id}/issues/#{issue.id}/notes/12345", user),
                body: 'Hello!'
        expect(response.status).to eq(404)
      end

      it 'should return a 400 bad request error if body not given' do
        put api("/projects/#{project.id}/issues/#{issue.id}/"\
                  "notes/#{issue_note.id}", user)
        expect(response.status).to eq(400)
      end
    end

    context 'when noteable is a Snippet' do
      it 'should return modified note' do
        put api("/projects/#{project.id}/snippets/#{snippet.id}/"\
                  "notes/#{snippet_note.id}", user), body: 'Hello!'
        expect(response.status).to eq(200)
        expect(json_response['body']).to eq('Hello!')
      end

      it 'should return a 404 error when note id not found' do
        put api("/projects/#{project.id}/snippets/#{snippet.id}/"\
                  "notes/12345", user), body: "Hello!"
        expect(response.status).to eq(404)
      end
    end

    context 'when noteable is a Merge Request' do
      it 'should return modified note' do
        put api("/projects/#{project.id}/merge_requests/#{merge_request.id}/"\
                  "notes/#{merge_request_note.id}", user), body: 'Hello!'
        expect(response.status).to eq(200)
        expect(json_response['body']).to eq('Hello!')
      end

      it 'should return a 404 error when note id not found' do
        put api("/projects/#{project.id}/merge_requests/#{merge_request.id}/"\
                  "notes/12345", user), body: "Hello!"
        expect(response.status).to eq(404)
      end
    end
  end
end
