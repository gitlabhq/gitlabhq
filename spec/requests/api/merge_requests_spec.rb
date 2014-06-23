require "spec_helper"

describe API::API, api: true  do
  include ApiHelpers
  let(:user) { create(:user) }
  let!(:project) {create(:project, creator_id: user.id, namespace: user.namespace) }
  let!(:merge_request) { create(:merge_request, :simple, author: user, assignee: user, source_project: project, target_project: project, title: "Test") }
  let!(:merge_request_closed) { create(:merge_request, state: "closed", author: user, assignee: user, source_project: project, target_project: project, title: "Closed test") }
  let!(:merge_request_merged) { create(:merge_request, state: "merged", author: user, assignee: user, source_project: project, target_project: project, title: "Merged test") }
  let!(:note) { create(:note_on_merge_request, author: user, project: project, noteable: merge_request, note: "a comment on a MR") }
  before {
    project.team << [user, :reporters]
  }

  describe "GET /projects/:id/merge_requests" do
    context "when unauthenticated" do
      it "should return authentication error" do
        get api("/projects/#{project.id}/merge_requests")
        response.status.should == 401
      end
    end

    context "when authenticated" do
      it "should return an array of all merge_requests" do
        get api("/projects/#{project.id}/merge_requests", user)
        response.status.should == 200
        json_response.should be_an Array
        json_response.length.should == 3
        json_response.first['title'].should == merge_request.title
      end
      it "should return an array of all merge_requests" do
        get api("/projects/#{project.id}/merge_requests?state", user)
        response.status.should == 200
        json_response.should be_an Array
        json_response.length.should == 3
        json_response.first['title'].should == merge_request.title
      end
      it "should return an array of open merge_requests" do
        get api("/projects/#{project.id}/merge_requests?state=opened", user)
        response.status.should == 200
        json_response.should be_an Array
        json_response.length.should == 1
        json_response.first['title'].should == merge_request.title
      end
      it "should return an array of closed merge_requests" do
        get api("/projects/#{project.id}/merge_requests?state=closed", user)
        response.status.should == 200
        json_response.should be_an Array
        json_response.length.should == 2
        json_response.first['title'].should == merge_request_closed.title
        json_response.second['title'].should == merge_request_merged.title
      end
      it "should return an array of merged merge_requests" do
        get api("/projects/#{project.id}/merge_requests?state=merged", user)
        response.status.should == 200
        json_response.should be_an Array
        json_response.length.should == 1
        json_response.first['title'].should == merge_request_merged.title
      end
    end
  end

  describe "GET /projects/:id/merge_request/:merge_request_id" do
    it "should return merge_request" do
      get api("/projects/#{project.id}/merge_request/#{merge_request.id}", user)
      response.status.should == 200
      json_response['title'].should == merge_request.title
      json_response['iid'].should == merge_request.iid
    end

    it "should return a 404 error if merge_request_id not found" do
      get api("/projects/#{project.id}/merge_request/999", user)
      response.status.should == 404
    end
  end

  describe "POST /projects/:id/merge_requests" do
    context 'between branches projects' do
      it "should return merge_request" do
        post api("/projects/#{project.id}/merge_requests", user),
        title: 'Test merge_request', source_branch: "stable", target_branch: "master", author: user
        response.status.should == 201
        json_response['title'].should == 'Test merge_request'
      end

      it "should return 422 when source_branch equals target_branch" do
        post api("/projects/#{project.id}/merge_requests", user),
        title: "Test merge_request", source_branch: "master", target_branch: "master", author: user
        response.status.should == 422
      end

      it "should return 400 when source_branch is missing" do
        post api("/projects/#{project.id}/merge_requests", user),
        title: "Test merge_request", target_branch: "master", author: user
        response.status.should == 400
      end

      it "should return 400 when target_branch is missing" do
        post api("/projects/#{project.id}/merge_requests", user),
        title: "Test merge_request", source_branch: "stable", author: user
        response.status.should == 400
      end

      it "should return 400 when title is missing" do
        post api("/projects/#{project.id}/merge_requests", user),
        target_branch: 'master', source_branch: 'stable'
        response.status.should == 400
      end
    end

    context 'forked projects' do
      let!(:user2) { create(:user) }
      let!(:fork_project) { create(:project, forked_from_project: project,  namespace: user2.namespace, creator_id: user2.id) }
      let!(:unrelated_project) { create(:project,  namespace: create(:user).namespace, creator_id: user2.id) }

      before :each do |each|
        fork_project.team << [user2, :reporters]
      end

      it "should return merge_request" do
        post api("/projects/#{fork_project.id}/merge_requests", user2),
        title: 'Test merge_request', source_branch: "stable", target_branch: "master", author: user2, target_project_id: project.id, description: 'Test description for Test merge_request'
        response.status.should == 201
        json_response['title'].should == 'Test merge_request'
        json_response['description'].should == 'Test description for Test merge_request'
      end

      it "should not return 422 when source_branch equals target_branch" do
        project.id.should_not == fork_project.id
        fork_project.forked?.should be_true
        fork_project.forked_from_project.should == project
        post api("/projects/#{fork_project.id}/merge_requests", user2),
        title: 'Test merge_request', source_branch: "master", target_branch: "master", author: user2, target_project_id: project.id
        response.status.should == 201
        json_response['title'].should == 'Test merge_request'
      end

      it "should return 400 when source_branch is missing" do
        post api("/projects/#{fork_project.id}/merge_requests", user2),
        title: 'Test merge_request', target_branch: "master", author: user2, target_project_id: project.id
        response.status.should == 400
      end

      it "should return 400 when target_branch is missing" do
        post api("/projects/#{fork_project.id}/merge_requests", user2),
        title: 'Test merge_request', target_branch: "master", author: user2, target_project_id: project.id
        response.status.should == 400
      end

      it "should return 400 when title is missing" do
        post api("/projects/#{fork_project.id}/merge_requests", user2),
        target_branch: 'master', source_branch: 'stable', author: user2, target_project_id: project.id
        response.status.should == 400
      end

      it "should return 404 when target_branch is specified and not a forked project" do
        post api("/projects/#{project.id}/merge_requests", user),
        title: 'Test merge_request', target_branch: 'master', source_branch: 'stable', author: user, target_project_id: fork_project.id
        response.status.should == 404
      end

      it "should return 404 when target_branch is specified and for a different fork" do
        post api("/projects/#{fork_project.id}/merge_requests", user2),
        title: 'Test merge_request', target_branch: 'master', source_branch: 'stable', author: user2, target_project_id: unrelated_project.id
        response.status.should == 404
      end

      it "should return 201 when target_branch is specified and for the same project" do
        post api("/projects/#{fork_project.id}/merge_requests", user2),
        title: 'Test merge_request', target_branch: 'master', source_branch: 'stable', author: user2, target_project_id: fork_project.id
        response.status.should == 201
      end
    end
  end

  describe "PUT /projects/:id/merge_request/:merge_request_id to close MR" do
    it "should return merge_request" do
      put api("/projects/#{project.id}/merge_request/#{merge_request.id}", user), state_event: "close"
      response.status.should == 200
      json_response['state'].should == 'closed'
    end
  end

  describe "PUT /projects/:id/merge_request/:merge_request_id/merge" do
    it "should return merge_request in case of success" do
      MergeRequest.any_instance.stub(can_be_merged?: true, automerge!: true)
      put api("/projects/#{project.id}/merge_request/#{merge_request.id}/merge", user)
      response.status.should == 200
    end

    it "should return 405 if branch can't be merged" do
      MergeRequest.any_instance.stub(can_be_merged?: false)
      put api("/projects/#{project.id}/merge_request/#{merge_request.id}/merge", user)
      response.status.should == 405
      json_response['message'].should == 'Branch cannot be merged'
    end

    it "should return 405 if merge_request is not open" do
      merge_request.close
      put api("/projects/#{project.id}/merge_request/#{merge_request.id}/merge", user)
      response.status.should == 405
      json_response['message'].should == 'Method Not Allowed'
    end

    it "should return 401 if user has no permissions to merge" do
      user2 = create(:user)
      project.team << [user2, :reporter]
      put api("/projects/#{project.id}/merge_request/#{merge_request.id}/merge", user2)
      response.status.should == 401
      json_response['message'].should == '401 Unauthorized'
    end
  end

  describe "PUT /projects/:id/merge_request/:merge_request_id" do
    it "should return merge_request" do
      put api("/projects/#{project.id}/merge_request/#{merge_request.id}", user), title: "New title"
      response.status.should == 200
      json_response['title'].should == 'New title'
    end

    it "should return merge_request" do
      put api("/projects/#{project.id}/merge_request/#{merge_request.id}", user), description: "New description"
      response.status.should == 200
      json_response['description'].should == 'New description'
    end

    it "should return 422 when source_branch and target_branch are renamed the same" do
      put api("/projects/#{project.id}/merge_request/#{merge_request.id}", user),
      source_branch: "master", target_branch: "master"
      response.status.should == 422
    end

    it "should return merge_request with renamed target_branch" do
      put api("/projects/#{project.id}/merge_request/#{merge_request.id}", user), target_branch: "wiki"
      response.status.should == 200
      json_response['target_branch'].should == 'wiki'
    end
  end

  describe "POST /projects/:id/merge_request/:merge_request_id/comments" do
    it "should return comment" do
      post api("/projects/#{project.id}/merge_request/#{merge_request.id}/comments", user), note: "My comment"
      response.status.should == 201
      json_response['note'].should == 'My comment'
    end

    it "should return 400 if note is missing" do
      post api("/projects/#{project.id}/merge_request/#{merge_request.id}/comments", user)
      response.status.should == 400
    end

    it "should return 404 if note is attached to non existent merge request" do
      post api("/projects/#{project.id}/merge_request/111/comments", user), note: "My comment"
      response.status.should == 404
    end
  end

  describe "GET :id/merge_request/:merge_request_id/comments" do
    it "should return merge_request comments" do
      get api("/projects/#{project.id}/merge_request/#{merge_request.id}/comments", user)
      response.status.should == 200
      json_response.should be_an Array
      json_response.length.should == 1
      json_response.first['note'].should == "a comment on a MR"
      json_response.first['author']['id'].should == user.id
    end

    it "should return a 404 error if merge_request_id not found" do
      get api("/projects/#{project.id}/merge_request/999/comments", user)
      response.status.should == 404
    end
  end
end
