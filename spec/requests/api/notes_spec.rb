require 'spec_helper'

describe API::API, api: true  do
  include ApiHelpers
  let(:user) { create(:user) }
  let!(:project) { create(:project, namespace: user.namespace ) }
  let!(:issue) { create(:issue, project: project, author: user) }
  let!(:merge_request) { create(:merge_request, source_project: project, target_project: project, author: user) }
  let!(:snippet) { create(:project_snippet, project: project, author: user) }
  let!(:issue_note) { create(:note, noteable: issue, project: project, author: user) }
  let!(:merge_request_note) { create(:note, noteable: merge_request, project: project, author: user) }
  let!(:snippet_note) { create(:note, noteable: snippet, project: project, author: user) }

  # For testing the cross-reference of a private issue in a public issue
  let(:private_user)    { create(:user) }
  let(:private_project) do
    create(:project, namespace: private_user.namespace).
    tap { |p| p.team << [private_user, :master] }
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

  before { project.team << [user, :reporter] }

  describe "GET /projects/:id/noteable/:noteable_id/notes" do
    it_behaves_like 'a paginated resources' do
      let(:request) { get api("/projects/#{project.id}/issues/#{issue.id}/notes", user) }
    end

    context "when noteable is an Issue" do
      it "should return an array of issue notes" do
        get api("/projects/#{project.id}/issues/#{issue.id}/notes", user)
        expect(response.status).to eq(200)
        expect(json_response).to be_an Array
        expect(json_response.first['body']).to eq(issue_note.note)
      end

      it "should return a 404 error when issue id not found" do
        get api("/projects/#{project.id}/issues/123/notes", user)
        expect(response.status).to eq(404)
      end

      context "that references a private issue" do
        it "should return an empty array" do
          get api("/projects/#{ext_proj.id}/issues/#{ext_issue.id}/notes", user)
          expect(response.status).to eq(200)
          expect(json_response).to be_an Array
          expect(json_response).to be_empty
        end

        context "and current user can view the note" do
          it "should return an empty array" do
            get api("/projects/#{ext_proj.id}/issues/#{ext_issue.id}/notes", private_user)
            expect(response.status).to eq(200)
            expect(json_response).to be_an Array
            expect(json_response.first['body']).to eq(cross_reference_note.note)
          end
        end
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
        get api("/projects/#{project.id}/issues/#{issue.id}/notes/123", user)
        expect(response.status).to eq(404)
      end

      context "that references a private issue" do
        it "should return a 404 error" do
          get api("/projects/#{ext_proj.id}/issues/#{ext_issue.id}/notes/#{cross_reference_note.id}", user)
          expect(response.status).to eq(404)
        end

        context "and current user can view the note" do
          it "should return an issue note by id" do
            get api("/projects/#{ext_proj.id}/issues/#{ext_issue.id}/notes/#{cross_reference_note.id}", private_user)
            expect(response.status).to eq(200)
            expect(json_response['body']).to eq(cross_reference_note.note)
          end
        end
      end
    end

    context "when noteable is a Snippet" do
      it "should return a snippet note by id" do
        get api("/projects/#{project.id}/snippets/#{snippet.id}/notes/#{snippet_note.id}", user)
        expect(response.status).to eq(200)
        expect(json_response['body']).to eq(snippet_note.note)
      end

      it "should return a 404 error if snippet note not found" do
        get api("/projects/#{project.id}/snippets/#{snippet.id}/notes/123", user)
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
        put api("/projects/#{project.id}/issues/#{issue.id}/notes/123", user),
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
                  "notes/123", user), body: "Hello!"
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
                  "notes/123", user), body: "Hello!"
        expect(response.status).to eq(404)
      end
    end
  end

end
