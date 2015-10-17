require "spec_helper"

describe API::API, api: true  do
  include ApiHelpers
  let(:base_time) { Time.now }
  let(:user) { create(:user) }
  let!(:project) {create(:project, creator_id: user.id, namespace: user.namespace) }
  let!(:merge_request) { create(:merge_request, :simple, author: user, assignee: user, source_project: project, target_project: project, title: "Test", created_at: base_time) }
  let!(:merge_request_closed) { create(:merge_request, state: "closed", author: user, assignee: user, source_project: project, target_project: project, title: "Closed test", created_at: base_time + 1.seconds) }
  let!(:merge_request_merged) { create(:merge_request, state: "merged", author: user, assignee: user, source_project: project, target_project: project, title: "Merged test", created_at: base_time + 2.seconds) }
  let!(:note) { create(:note_on_merge_request, author: user, project: project, noteable: merge_request, note: "a comment on a MR") }
  let!(:note2) { create(:note_on_merge_request, author: user, project: project, noteable: merge_request, note: "another comment on a MR") }

  before do
    project.team << [user, :reporters]
  end

  describe "GET /projects/:id/merge_requests" do
    context "when unauthenticated" do
      it "should return authentication error" do
        get api("/projects/#{project.id}/merge_requests")
        expect(response.status).to eq(401)
      end
    end

    context "when authenticated" do
      it "should return an array of all merge_requests" do
        get api("/projects/#{project.id}/merge_requests", user)
        expect(response.status).to eq(200)
        expect(json_response).to be_an Array
        expect(json_response.length).to eq(3)
        expect(json_response.last['title']).to eq(merge_request.title)
      end

      it "should return an array of all merge_requests" do
        get api("/projects/#{project.id}/merge_requests?state", user)
        expect(response.status).to eq(200)
        expect(json_response).to be_an Array
        expect(json_response.length).to eq(3)
        expect(json_response.last['title']).to eq(merge_request.title)
      end

      it "should return an array of open merge_requests" do
        get api("/projects/#{project.id}/merge_requests?state=opened", user)
        expect(response.status).to eq(200)
        expect(json_response).to be_an Array
        expect(json_response.length).to eq(1)
        expect(json_response.last['title']).to eq(merge_request.title)
      end

      it "should return an array of closed merge_requests" do
        get api("/projects/#{project.id}/merge_requests?state=closed", user)
        expect(response.status).to eq(200)
        expect(json_response).to be_an Array
        expect(json_response.length).to eq(1)
        expect(json_response.first['title']).to eq(merge_request_closed.title)
      end

      it "should return an array of merged merge_requests" do
        get api("/projects/#{project.id}/merge_requests?state=merged", user)
        expect(response.status).to eq(200)
        expect(json_response).to be_an Array
        expect(json_response.length).to eq(1)
        expect(json_response.first['title']).to eq(merge_request_merged.title)
      end

      context "with ordering" do
        before do
          @mr_later = mr_with_later_created_and_updated_at_time
          @mr_earlier = mr_with_earlier_created_and_updated_at_time
        end

        it "should return an array of merge_requests in ascending order" do
          get api("/projects/#{project.id}/merge_requests?sort=asc", user)
          expect(response.status).to eq(200)
          expect(json_response).to be_an Array
          expect(json_response.length).to eq(3)
          response_dates = json_response.map{ |merge_request| merge_request['created_at'] }
          expect(response_dates).to eq(response_dates.sort)
        end

        it "should return an array of merge_requests in descending order" do
          get api("/projects/#{project.id}/merge_requests?sort=desc", user)
          expect(response.status).to eq(200)
          expect(json_response).to be_an Array
          expect(json_response.length).to eq(3)
          response_dates = json_response.map{ |merge_request| merge_request['created_at'] }
          expect(response_dates).to eq(response_dates.sort.reverse)
        end

        it "should return an array of merge_requests ordered by updated_at" do
          get api("/projects/#{project.id}/merge_requests?order_by=updated_at", user)
          expect(response.status).to eq(200)
          expect(json_response).to be_an Array
          expect(json_response.length).to eq(3)
          response_dates = json_response.map{ |merge_request| merge_request['updated_at'] }
          expect(response_dates).to eq(response_dates.sort.reverse)
        end

        it "should return an array of merge_requests ordered by created_at" do
          get api("/projects/#{project.id}/merge_requests?order_by=created_at&sort=asc", user)
          expect(response.status).to eq(200)
          expect(json_response).to be_an Array
          expect(json_response.length).to eq(3)
          response_dates = json_response.map{ |merge_request| merge_request['created_at'] }
          expect(response_dates).to eq(response_dates.sort)
        end
      end
    end
  end

  describe "GET /projects/:id/merge_request/:merge_request_id" do
    it "should return merge_request" do
      get api("/projects/#{project.id}/merge_request/#{merge_request.id}", user)
      expect(response.status).to eq(200)
      expect(json_response['title']).to eq(merge_request.title)
      expect(json_response['iid']).to eq(merge_request.iid)
    end

    it 'should return merge_request by iid' do
      url = "/projects/#{project.id}/merge_requests?iid=#{merge_request.iid}"
      get api(url, user)
      expect(response.status).to eq 200
      expect(json_response.first['title']).to eq merge_request.title
      expect(json_response.first['id']).to eq merge_request.id
    end

    it "should return a 404 error if merge_request_id not found" do
      get api("/projects/#{project.id}/merge_request/999", user)
      expect(response.status).to eq(404)
    end
  end

  describe 'GET /projects/:id/merge_request/:merge_request_id/changes' do
    it 'should return the change information of the merge_request' do
      get api("/projects/#{project.id}/merge_request/#{merge_request.id}/changes", user)
      expect(response.status).to eq 200
      expect(json_response['changes'].size).to eq(merge_request.diffs.size)
    end

    it 'returns a 404 when merge_request_id not found' do
      get api("/projects/#{project.id}/merge_request/999/changes", user)
      expect(response.status).to eq(404)
    end
  end

  describe "POST /projects/:id/merge_requests" do
    context 'between branches projects' do
      it "should return merge_request" do
        post api("/projects/#{project.id}/merge_requests", user),
             title: 'Test merge_request',
             source_branch: 'feature_conflict',
             target_branch: 'master',
             author: user,
             labels: 'label, label2'
        expect(response.status).to eq(201)
        expect(json_response['title']).to eq('Test merge_request')
        expect(json_response['labels']).to eq(['label', 'label2'])
      end

      it "should return 422 when source_branch equals target_branch" do
        post api("/projects/#{project.id}/merge_requests", user),
        title: "Test merge_request", source_branch: "master", target_branch: "master", author: user
        expect(response.status).to eq(422)
      end

      it "should return 400 when source_branch is missing" do
        post api("/projects/#{project.id}/merge_requests", user),
        title: "Test merge_request", target_branch: "master", author: user
        expect(response.status).to eq(400)
      end

      it "should return 400 when target_branch is missing" do
        post api("/projects/#{project.id}/merge_requests", user),
        title: "Test merge_request", source_branch: "markdown", author: user
        expect(response.status).to eq(400)
      end

      it "should return 400 when title is missing" do
        post api("/projects/#{project.id}/merge_requests", user),
        target_branch: 'master', source_branch: 'markdown'
        expect(response.status).to eq(400)
      end

      it 'should return 400 on invalid label names' do
        post api("/projects/#{project.id}/merge_requests", user),
             title: 'Test merge_request',
             source_branch: 'markdown',
             target_branch: 'master',
             author: user,
             labels: 'label, ?'
        expect(response.status).to eq(400)
        expect(json_response['message']['labels']['?']['title']).to eq(
          ['is invalid']
        )
      end

      context 'with existing MR' do
        before do
          post api("/projects/#{project.id}/merge_requests", user),
               title: 'Test merge_request',
               source_branch: 'feature_conflict',
               target_branch: 'master',
               author: user
          @mr = MergeRequest.all.last
        end

        it 'should return 409 when MR already exists for source/target' do
          expect do
            post api("/projects/#{project.id}/merge_requests", user),
                 title: 'New test merge_request',
                 source_branch: 'feature_conflict',
                 target_branch: 'master',
                 author: user
          end.to change { MergeRequest.count }.by(0)
          expect(response.status).to eq(409)
        end
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
          title: 'Test merge_request', source_branch: "feature_conflict", target_branch: "master",
          author: user2, target_project_id: project.id, description: 'Test description for Test merge_request'
        expect(response.status).to eq(201)
        expect(json_response['title']).to eq('Test merge_request')
        expect(json_response['description']).to eq('Test description for Test merge_request')
      end

      it "should not return 422 when source_branch equals target_branch" do
        expect(project.id).not_to eq(fork_project.id)
        expect(fork_project.forked?).to be_truthy
        expect(fork_project.forked_from_project).to eq(project)
        post api("/projects/#{fork_project.id}/merge_requests", user2),
        title: 'Test merge_request', source_branch: "master", target_branch: "master", author: user2, target_project_id: project.id
        expect(response.status).to eq(201)
        expect(json_response['title']).to eq('Test merge_request')
      end

      it "should return 400 when source_branch is missing" do
        post api("/projects/#{fork_project.id}/merge_requests", user2),
        title: 'Test merge_request', target_branch: "master", author: user2, target_project_id: project.id
        expect(response.status).to eq(400)
      end

      it "should return 400 when target_branch is missing" do
        post api("/projects/#{fork_project.id}/merge_requests", user2),
        title: 'Test merge_request', target_branch: "master", author: user2, target_project_id: project.id
        expect(response.status).to eq(400)
      end

      it "should return 400 when title is missing" do
        post api("/projects/#{fork_project.id}/merge_requests", user2),
        target_branch: 'master', source_branch: 'markdown', author: user2, target_project_id: project.id
        expect(response.status).to eq(400)
      end

      context 'when target_branch is specified' do
        it 'should return 422 if not a forked project' do
          post api("/projects/#{project.id}/merge_requests", user),
               title: 'Test merge_request',
               target_branch: 'master',
               source_branch: 'markdown',
               author: user,
               target_project_id: fork_project.id
          expect(response.status).to eq(422)
        end

        it 'should return 422 if targeting a different fork' do
          post api("/projects/#{fork_project.id}/merge_requests", user2),
               title: 'Test merge_request',
               target_branch: 'master',
               source_branch: 'markdown',
               author: user2,
               target_project_id: unrelated_project.id
          expect(response.status).to eq(422)
        end
      end

      it "should return 201 when target_branch is specified and for the same project" do
        post api("/projects/#{fork_project.id}/merge_requests", user2),
        title: 'Test merge_request', target_branch: 'master', source_branch: 'markdown', author: user2, target_project_id: fork_project.id
        expect(response.status).to eq(201)
      end
    end
  end

  describe "PUT /projects/:id/merge_request/:merge_request_id to close MR" do
    it "should return merge_request" do
      put api("/projects/#{project.id}/merge_request/#{merge_request.id}", user), state_event: "close"
      expect(response.status).to eq(200)
      expect(json_response['state']).to eq('closed')
    end
  end

  describe "PUT /projects/:id/merge_request/:merge_request_id/merge" do
    it "should return merge_request in case of success" do
      put api("/projects/#{project.id}/merge_request/#{merge_request.id}/merge", user)

      expect(response.status).to eq(200)
    end

    it "should return 405 if branch can't be merged" do
      allow_any_instance_of(MergeRequest).
        to receive(:can_be_merged?).and_return(false)

      put api("/projects/#{project.id}/merge_request/#{merge_request.id}/merge", user)

      expect(response.status).to eq(405)
      expect(json_response['message']).to eq('Branch cannot be merged')
    end

    it "should return 405 if merge_request is not open" do
      merge_request.close
      put api("/projects/#{project.id}/merge_request/#{merge_request.id}/merge", user)
      expect(response.status).to eq(405)
      expect(json_response['message']).to eq('405 Method Not Allowed')
    end

    it "should return 405 if merge_request is a work in progress" do
      merge_request.update_attribute(:title, "WIP: #{merge_request.title}")
      put api("/projects/#{project.id}/merge_request/#{merge_request.id}/merge", user)
      expect(response.status).to eq(405)
      expect(json_response['message']).to eq('405 Method Not Allowed')
    end

    it "should return 401 if user has no permissions to merge" do
      user2 = create(:user)
      project.team << [user2, :reporter]
      put api("/projects/#{project.id}/merge_request/#{merge_request.id}/merge", user2)
      expect(response.status).to eq(401)
      expect(json_response['message']).to eq('401 Unauthorized')
    end
  end

  describe "PUT /projects/:id/merge_request/:merge_request_id" do
    it "should return merge_request" do
      put api("/projects/#{project.id}/merge_request/#{merge_request.id}", user), title: "New title"
      expect(response.status).to eq(200)
      expect(json_response['title']).to eq('New title')
    end

    it "should return merge_request" do
      put api("/projects/#{project.id}/merge_request/#{merge_request.id}", user), description: "New description"
      expect(response.status).to eq(200)
      expect(json_response['description']).to eq('New description')
    end

    it "should return 400 when source_branch is specified" do
      put api("/projects/#{project.id}/merge_request/#{merge_request.id}", user),
      source_branch: "master", target_branch: "master"
      expect(response.status).to eq(400)
    end

    it "should return merge_request with renamed target_branch" do
      put api("/projects/#{project.id}/merge_request/#{merge_request.id}", user), target_branch: "wiki"
      expect(response.status).to eq(200)
      expect(json_response['target_branch']).to eq('wiki')
    end

    it 'should return 400 on invalid label names' do
      put api("/projects/#{project.id}/merge_request/#{merge_request.id}",
              user),
          title: 'new issue',
          labels: 'label, ?'
      expect(response.status).to eq(400)
      expect(json_response['message']['labels']['?']['title']).to eq(['is invalid'])
    end
  end

  describe "POST /projects/:id/merge_request/:merge_request_id/comments" do
    it "should return comment" do
      original_count = merge_request.notes.size

      post api("/projects/#{project.id}/merge_request/#{merge_request.id}/comments", user), note: "My comment"
      expect(response.status).to eq(201)
      expect(json_response['note']).to eq('My comment')
      expect(json_response['author']['name']).to eq(user.name)
      expect(json_response['author']['username']).to eq(user.username)
      expect(merge_request.notes.size).to eq(original_count + 1)
    end

    it "should return 400 if note is missing" do
      post api("/projects/#{project.id}/merge_request/#{merge_request.id}/comments", user)
      expect(response.status).to eq(400)
    end

    it "should return 404 if note is attached to non existent merge request" do
      post api("/projects/#{project.id}/merge_request/404/comments", user),
           note: 'My comment'
      expect(response.status).to eq(404)
    end
  end

  describe "GET :id/merge_request/:merge_request_id/comments" do
    it "should return merge_request comments ordered by created_at" do
      get api("/projects/#{project.id}/merge_request/#{merge_request.id}/comments", user)
      expect(response.status).to eq(200)
      expect(json_response).to be_an Array
      expect(json_response.length).to eq(2)
      expect(json_response.first['note']).to eq("a comment on a MR")
      expect(json_response.first['author']['id']).to eq(user.id)
      expect(json_response.last['note']).to eq("another comment on a MR")
    end

    it "should return a 404 error if merge_request_id not found" do
      get api("/projects/#{project.id}/merge_request/999/comments", user)
      expect(response.status).to eq(404)
    end
  end

  def mr_with_later_created_and_updated_at_time
    merge_request
    merge_request.created_at += 1.hour
    merge_request.updated_at += 30.minutes
    merge_request.save
    merge_request
  end

  def mr_with_earlier_created_and_updated_at_time
    merge_request_closed
    merge_request_closed.created_at -= 1.hour
    merge_request_closed.updated_at -= 30.minutes
    merge_request_closed.save
    merge_request_closed
  end
end
