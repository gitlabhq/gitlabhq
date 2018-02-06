require 'spec_helper'

describe API::AwardEmoji do
  set(:user)           { create(:user) }
  set(:project)        { create(:project) }
  set(:issue)          { create(:issue, project: project) }
  set(:award_emoji)    { create(:award_emoji, awardable: issue, user: user) }
  let!(:merge_request) { create(:merge_request, source_project: project, target_project: project) }
  let!(:downvote)      { create(:award_emoji, :downvote, awardable: merge_request, user: user) }
  set(:note)          { create(:note, project: project, noteable: issue) }

  before do
    project.add_master(user)
  end

  describe "GET /projects/:id/awardable/:awardable_id/award_emoji" do
    context 'on an issue' do
      it "returns an array of award_emoji" do
        get api("/projects/#{project.id}/issues/#{issue.iid}/award_emoji", user)

        expect(response).to have_gitlab_http_status(200)
        expect(json_response).to be_an Array
        expect(json_response.first['name']).to eq(award_emoji.name)
      end

      it "returns a 404 error when issue id not found" do
        get api("/projects/#{project.id}/issues/12345/award_emoji", user)

        expect(response).to have_gitlab_http_status(404)
      end
    end

    context 'on a merge request' do
      it "returns an array of award_emoji" do
        get api("/projects/#{project.id}/merge_requests/#{merge_request.iid}/award_emoji", user)

        expect(response).to have_gitlab_http_status(200)
        expect(response).to include_pagination_headers
        expect(json_response).to be_an Array
        expect(json_response.first['name']).to eq(downvote.name)
      end
    end

    context 'on a snippet' do
      let(:snippet) { create(:project_snippet, :public, project: project) }
      let!(:award)  { create(:award_emoji, awardable: snippet) }

      it 'returns the awarded emoji' do
        get api("/projects/#{project.id}/snippets/#{snippet.id}/award_emoji", user)

        expect(response).to have_gitlab_http_status(200)
        expect(json_response).to be_an Array
        expect(json_response.first['name']).to eq(award.name)
      end
    end

    context 'when the user has no access' do
      it 'returns a status code 404' do
        user1 = create(:user)

        get api("/projects/#{project.id}/merge_requests/#{merge_request.iid}/award_emoji", user1)

        expect(response).to have_gitlab_http_status(404)
      end
    end
  end

  describe 'GET /projects/:id/awardable/:awardable_id/notes/:note_id/award_emoji' do
    let!(:rocket)  { create(:award_emoji, awardable: note, name: 'rocket') }

    it 'returns an array of award emoji' do
      get api("/projects/#{project.id}/issues/#{issue.iid}/notes/#{note.id}/award_emoji", user)

      expect(response).to have_gitlab_http_status(200)
      expect(json_response).to be_an Array
      expect(json_response.first['name']).to eq(rocket.name)
    end
  end

  describe "GET /projects/:id/awardable/:awardable_id/award_emoji/:award_id" do
    context 'on an issue' do
      it "returns the award emoji" do
        get api("/projects/#{project.id}/issues/#{issue.iid}/award_emoji/#{award_emoji.id}", user)

        expect(response).to have_gitlab_http_status(200)
        expect(json_response['name']).to eq(award_emoji.name)
        expect(json_response['awardable_id']).to eq(issue.id)
        expect(json_response['awardable_type']).to eq("Issue")
      end

      it "returns a 404 error if the award is not found" do
        get api("/projects/#{project.id}/issues/#{issue.iid}/award_emoji/12345", user)

        expect(response).to have_gitlab_http_status(404)
      end
    end

    context 'on a merge request' do
      it 'returns the award emoji' do
        get api("/projects/#{project.id}/merge_requests/#{merge_request.iid}/award_emoji/#{downvote.id}", user)

        expect(response).to have_gitlab_http_status(200)
        expect(json_response['name']).to eq(downvote.name)
        expect(json_response['awardable_id']).to eq(merge_request.id)
        expect(json_response['awardable_type']).to eq("MergeRequest")
      end
    end

    context 'on a snippet' do
      let(:snippet) { create(:project_snippet, :public, project: project) }
      let!(:award)  { create(:award_emoji, awardable: snippet) }

      it 'returns the awarded emoji' do
        get api("/projects/#{project.id}/snippets/#{snippet.id}/award_emoji/#{award.id}", user)

        expect(response).to have_gitlab_http_status(200)
        expect(json_response['name']).to eq(award.name)
        expect(json_response['awardable_id']).to eq(snippet.id)
        expect(json_response['awardable_type']).to eq("Snippet")
      end
    end

    context 'when the user has no access' do
      it 'returns a status code 404' do
        user1 = create(:user)

        get api("/projects/#{project.id}/merge_requests/#{merge_request.iid}/award_emoji/#{downvote.id}", user1)

        expect(response).to have_gitlab_http_status(404)
      end
    end
  end

  describe 'GET /projects/:id/awardable/:awardable_id/notes/:note_id/award_emoji/:award_id' do
    let!(:rocket)  { create(:award_emoji, awardable: note, name: 'rocket') }

    it 'returns an award emoji' do
      get api("/projects/#{project.id}/issues/#{issue.iid}/notes/#{note.id}/award_emoji/#{rocket.id}", user)

      expect(response).to have_gitlab_http_status(200)
      expect(json_response).not_to be_an Array
      expect(json_response['name']).to eq(rocket.name)
    end
  end

  describe "POST /projects/:id/awardable/:awardable_id/award_emoji" do
    let(:issue2)  { create(:issue, project: project, author: user) }

    context "on an issue" do
      it "creates a new award emoji" do
        post api("/projects/#{project.id}/issues/#{issue.iid}/award_emoji", user), name: 'blowfish'

        expect(response).to have_gitlab_http_status(201)
        expect(json_response['name']).to eq('blowfish')
        expect(json_response['user']['username']).to eq(user.username)
      end

      it "returns a 400 bad request error if the name is not given" do
        post api("/projects/#{project.id}/issues/#{issue.iid}/award_emoji", user)

        expect(response).to have_gitlab_http_status(400)
      end

      it "returns a 401 unauthorized error if the user is not authenticated" do
        post api("/projects/#{project.id}/issues/#{issue.iid}/award_emoji"), name: 'thumbsup'

        expect(response).to have_gitlab_http_status(401)
      end

      it "returns a 404 error if the user authored issue" do
        post api("/projects/#{project.id}/issues/#{issue2.id}/award_emoji", user), name: 'thumbsup'

        expect(response).to have_gitlab_http_status(404)
      end

      it "normalizes +1 as thumbsup award" do
        post api("/projects/#{project.id}/issues/#{issue.iid}/award_emoji", user), name: '+1'

        expect(issue.award_emoji.last.name).to eq("thumbsup")
      end

      context 'when the emoji already has been awarded' do
        it 'returns a 404 status code' do
          post api("/projects/#{project.id}/issues/#{issue.iid}/award_emoji", user), name: 'thumbsup'
          post api("/projects/#{project.id}/issues/#{issue.iid}/award_emoji", user), name: 'thumbsup'

          expect(response).to have_gitlab_http_status(404)
          expect(json_response["message"]).to match("has already been taken")
        end
      end
    end

    context 'on a snippet' do
      it 'creates a new award emoji' do
        snippet = create(:project_snippet, :public, project: project)

        post api("/projects/#{project.id}/snippets/#{snippet.id}/award_emoji", user), name: 'blowfish'

        expect(response).to have_gitlab_http_status(201)
        expect(json_response['name']).to eq('blowfish')
        expect(json_response['user']['username']).to eq(user.username)
      end
    end
  end

  describe "POST /projects/:id/awardable/:awardable_id/notes/:note_id/award_emoji" do
    let(:note2)  { create(:note, project: project, noteable: issue, author: user) }

    it 'creates a new award emoji' do
      expect do
        post api("/projects/#{project.id}/issues/#{issue.iid}/notes/#{note.id}/award_emoji", user), name: 'rocket'
      end.to change { note.award_emoji.count }.from(0).to(1)

      expect(response).to have_gitlab_http_status(201)
      expect(json_response['user']['username']).to eq(user.username)
    end

    it "it returns 404 error when user authored note" do
      post api("/projects/#{project.id}/issues/#{issue.iid}/notes/#{note2.id}/award_emoji", user), name: 'thumbsup'

      expect(response).to have_gitlab_http_status(404)
    end

    it "normalizes +1 as thumbsup award" do
      post api("/projects/#{project.id}/issues/#{issue.iid}/notes/#{note.id}/award_emoji", user), name: '+1'

      expect(note.award_emoji.last.name).to eq("thumbsup")
    end

    context 'when the emoji already has been awarded' do
      it 'returns a 404 status code' do
        post api("/projects/#{project.id}/issues/#{issue.iid}/notes/#{note.id}/award_emoji", user), name: 'rocket'
        post api("/projects/#{project.id}/issues/#{issue.iid}/notes/#{note.id}/award_emoji", user), name: 'rocket'

        expect(response).to have_gitlab_http_status(404)
        expect(json_response["message"]).to match("has already been taken")
      end
    end
  end

  describe 'DELETE /projects/:id/awardable/:awardable_id/award_emoji/:award_id' do
    context 'when the awardable is an Issue' do
      it 'deletes the award' do
        expect do
          delete api("/projects/#{project.id}/issues/#{issue.iid}/award_emoji/#{award_emoji.id}", user)

          expect(response).to have_gitlab_http_status(204)
        end.to change { issue.award_emoji.count }.from(1).to(0)
      end

      it 'returns a 404 error when the award emoji can not be found' do
        delete api("/projects/#{project.id}/issues/#{issue.iid}/award_emoji/12345", user)

        expect(response).to have_gitlab_http_status(404)
      end

      it_behaves_like '412 response' do
        let(:request) { api("/projects/#{project.id}/issues/#{issue.iid}/award_emoji/#{award_emoji.id}", user) }
      end
    end

    context 'when the awardable is a Merge Request' do
      it 'deletes the award' do
        expect do
          delete api("/projects/#{project.id}/merge_requests/#{merge_request.iid}/award_emoji/#{downvote.id}", user)

          expect(response).to have_gitlab_http_status(204)
        end.to change { merge_request.award_emoji.count }.from(1).to(0)
      end

      it 'returns a 404 error when note id not found' do
        delete api("/projects/#{project.id}/merge_requests/#{merge_request.iid}/notes/12345", user)

        expect(response).to have_gitlab_http_status(404)
      end

      it_behaves_like '412 response' do
        let(:request) { api("/projects/#{project.id}/merge_requests/#{merge_request.iid}/award_emoji/#{downvote.id}", user) }
      end
    end

    context 'when the awardable is a Snippet' do
      let(:snippet) { create(:project_snippet, :public, project: project) }
      let!(:award)  { create(:award_emoji, awardable: snippet, user: user) }

      it 'deletes the award' do
        expect do
          delete api("/projects/#{project.id}/snippets/#{snippet.id}/award_emoji/#{award.id}", user)

          expect(response).to have_gitlab_http_status(204)
        end.to change { snippet.award_emoji.count }.from(1).to(0)
      end

      it_behaves_like '412 response' do
        let(:request) { api("/projects/#{project.id}/snippets/#{snippet.id}/award_emoji/#{award.id}", user) }
      end
    end
  end

  describe 'DELETE /projects/:id/awardable/:awardable_id/award_emoji/:award_emoji_id' do
    let!(:rocket)  { create(:award_emoji, awardable: note, name: 'rocket', user: user) }

    it 'deletes the award' do
      expect do
        delete api("/projects/#{project.id}/issues/#{issue.iid}/notes/#{note.id}/award_emoji/#{rocket.id}", user)

        expect(response).to have_gitlab_http_status(204)
      end.to change { note.award_emoji.count }.from(1).to(0)
    end

    it_behaves_like '412 response' do
      let(:request) { api("/projects/#{project.id}/issues/#{issue.iid}/notes/#{note.id}/award_emoji/#{rocket.id}", user) }
    end
  end
end
