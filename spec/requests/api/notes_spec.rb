require 'spec_helper'

describe API::API do
  include ApiHelpers

  let(:user) { create(:user) }
  let!(:project) { create(:project, namespace: user.namespace ) }
  let!(:issue) { create(:issue, project: project, author: user) }
  let!(:merge_request) { create(:merge_request, project: project, author: user) }
  let!(:snippet) { create(:project_snippet, project: project, author: user) }
  let!(:issue_note) { create(:note, noteable: issue, project: project, author: user) }
  let!(:merge_request_note) { create(:note, noteable: merge_request, project: project, author: user) }
  let!(:snippet_note) { create(:note, noteable: snippet, project: project, author: user) }
  let!(:wall_note) { create(:note, project: project, author: user) }
  before { project.team << [user, :reporter] }

  describe "GET /projects/:id/notes" do
    context "when unauthenticated" do
      it "should return authentication error" do
        get api("/projects/#{project.id}/notes")
        response.status.should == 401
      end
    end

    context "when authenticated" do
      it "should return project wall notes" do
        get api("/projects/#{project.id}/notes", user)
        response.status.should == 200
        json_response.should be_an Array
        json_response.first['body'].should == wall_note.note
      end
    end
  end

  describe "GET /projects/:id/notes/:note_id" do
    it "should return a wall note by id" do
      get api("/projects/#{project.id}/notes/#{wall_note.id}", user)
      response.status.should == 200
      json_response['body'].should == wall_note.note
    end

    it "should return a 404 error if note not found" do
      get api("/projects/#{project.id}/notes/123", user)
      response.status.should == 404
    end
  end

  describe "POST /projects/:id/notes" do
    it "should create a new wall note" do
      post api("/projects/#{project.id}/notes", user), body: 'hi!'
      response.status.should == 201
      json_response['body'].should == 'hi!'
    end

    it "should return 401 unauthorized error" do
      post api("/projects/#{project.id}/notes")
      response.status.should == 401
    end

    it "should return a 400 bad request if body is missing" do
      post api("/projects/#{project.id}/notes", user)
      response.status.should == 400
    end
  end

  describe "GET /projects/:id/noteable/:noteable_id/notes" do
    context "when noteable is an Issue" do
      it "should return an array of issue notes" do
        get api("/projects/#{project.id}/issues/#{issue.id}/notes", user)
        response.status.should == 200
        json_response.should be_an Array
        json_response.first['body'].should == issue_note.note
      end

      it "should return a 404 error when issue id not found" do
        get api("/projects/#{project.id}/issues/123/notes", user)
        response.status.should == 404
      end
    end

    context "when noteable is a Snippet" do
      it "should return an array of snippet notes" do
        get api("/projects/#{project.id}/snippets/#{snippet.id}/notes", user)
        response.status.should == 200
        json_response.should be_an Array
        json_response.first['body'].should == snippet_note.note
      end

      it "should return a 404 error when snippet id not found" do
        get api("/projects/#{project.id}/snippets/42/notes", user)
        response.status.should == 404
      end
    end

    context "when noteable is a Merge Request" do
      it "should return an array of merge_requests notes" do
        get api("/projects/#{project.id}/merge_requests/#{merge_request.id}/notes", user)
        response.status.should == 200
        json_response.should be_an Array
        json_response.first['body'].should == merge_request_note.note
      end

      it "should return a 404 error if merge request id not found" do
        get api("/projects/#{project.id}/merge_requests/4444/notes", user)
        response.status.should == 404
      end
    end
  end

  describe "GET /projects/:id/noteable/:noteable_id/notes/:note_id" do
    context "when noteable is an Issue" do
      it "should return an issue note by id" do
        get api("/projects/#{project.id}/issues/#{issue.id}/notes/#{issue_note.id}", user)
        response.status.should == 200
        json_response['body'].should == issue_note.note
      end

      it "should return a 404 error if issue note not found" do
        get api("/projects/#{project.id}/issues/#{issue.id}/notes/123", user)
        response.status.should == 404
      end
    end

    context "when noteable is a Snippet" do
      it "should return a snippet note by id" do
        get api("/projects/#{project.id}/snippets/#{snippet.id}/notes/#{snippet_note.id}", user)
        response.status.should == 200
        json_response['body'].should == snippet_note.note
      end

      it "should return a 404 error if snippet note not found" do
        get api("/projects/#{project.id}/snippets/#{snippet.id}/notes/123", user)
        response.status.should == 404
      end
    end
  end

  describe "POST /projects/:id/noteable/:noteable_id/notes" do
    context "when noteable is an Issue" do
      it "should create a new issue note" do
        post api("/projects/#{project.id}/issues/#{issue.id}/notes", user), body: 'hi!'
        response.status.should == 201
        json_response['body'].should == 'hi!'
        json_response['author']['email'].should == user.email
      end

      it "should return a 400 bad request error if body not given" do
        post api("/projects/#{project.id}/issues/#{issue.id}/notes", user)
        response.status.should == 400
      end

      it "should return a 401 unauthorized error if user not authenticated" do
        post api("/projects/#{project.id}/issues/#{issue.id}/notes"), body: 'hi!'
        response.status.should == 401
      end
    end

    context "when noteable is a Snippet" do
      it "should create a new snippet note" do
        post api("/projects/#{project.id}/snippets/#{snippet.id}/notes", user), body: 'hi!'
        response.status.should == 201
        json_response['body'].should == 'hi!'
        json_response['author']['email'].should == user.email
      end

      it "should return a 400 bad request error if body not given" do
        post api("/projects/#{project.id}/snippets/#{snippet.id}/notes", user)
        response.status.should == 400
      end

      it "should return a 401 unauthorized error if user not authenticated" do
        post api("/projects/#{project.id}/snippets/#{snippet.id}/notes"), body: 'hi!'
        response.status.should == 401
      end
    end
  end
end
