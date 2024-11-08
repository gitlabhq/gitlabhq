# frozen_string_literal: true

require 'spec_helper'

RSpec.describe API::AwardEmoji, feature_category: :shared do
  let_it_be_with_reload(:project) { create(:project, :private) }
  let_it_be(:user)        { create(:user) }
  let_it_be(:issue)       { create(:issue, project: project) }
  let_it_be(:award_emoji) { create(:award_emoji, awardable: issue, user: user) }
  let_it_be(:note)        { create(:note, project: project, noteable: issue) }

  let!(:merge_request)    { create(:merge_request, source_project: project, target_project: project) }
  let!(:downvote)         { create(:award_emoji, :downvote, awardable: merge_request, user: user) }

  before do
    project.add_maintainer(user)
  end

  shared_examples 'request with insufficient permissions' do |request_method|
    let(:request_params) { {} }

    context 'when user is not signed in' do
      it 'returns 404' do
        process request_method, api(request_path), params: request_params

        expect(response).to have_gitlab_http_status(:not_found)
      end
    end

    context 'when user does not have access' do
      it 'returns 404' do
        other_user = create(:user)

        process request_method, api(request_path, other_user), params: request_params

        expect(response).to have_gitlab_http_status(:not_found)
      end
    end
  end

  shared_examples 'unauthenticated request to public awardable' do
    before do
      project.update!(visibility_level: Gitlab::VisibilityLevel::PUBLIC)
    end

    it 'returns the awarded emoji' do
      get api(request_path)

      expect(response).to have_gitlab_http_status(:ok)
    end
  end

  describe "GET /projects/:id/awardable/:awardable_id/award_emoji" do
    context 'on an issue' do
      let(:request_path) { "/projects/#{project.id}/issues/#{issue.iid}/award_emoji" }

      it "returns an array of award_emoji" do
        get api(request_path, user)

        expect(response).to have_gitlab_http_status(:ok)
        expect(json_response).to be_an Array
        expect(json_response.first['name']).to eq(award_emoji.name)
      end

      it "includes custom emoji attributes" do
        group = create(:group)
        group.add_maintainer(user)

        project = create(:project, namespace: group)
        custom_emoji = create(:custom_emoji, name: 'partyparrot', namespace: group)
        issue = create(:issue, project: project)
        create(:award_emoji, awardable: issue, user: user, name: custom_emoji.name)

        get api("/projects/#{project.id}/issues/#{issue.iid}/award_emoji", user)

        expect(response).to have_gitlab_http_status(:ok)
        expect(json_response).to be_an Array
        expect(json_response.first['name']).to eq(custom_emoji.name)
        expect(json_response.first['url']).to eq(custom_emoji.file)
      end

      it "returns a 404 error when issue id not found" do
        get api("/projects/#{project.id}/issues/#{non_existing_record_iid}/award_emoji", user)

        expect(response).to have_gitlab_http_status(:not_found)
      end

      it_behaves_like 'unauthenticated request to public awardable'
      it_behaves_like 'request with insufficient permissions', :get
    end

    context 'on a merge request' do
      it "returns an array of award_emoji" do
        get api("/projects/#{project.id}/merge_requests/#{merge_request.iid}/award_emoji", user)

        expect(response).to have_gitlab_http_status(:ok)
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

        expect(response).to have_gitlab_http_status(:ok)
        expect(json_response).to be_an Array
        expect(json_response.first['name']).to eq(award.name)
      end
    end
  end

  describe 'GET /projects/:id/awardable/:awardable_id/notes/:note_id/award_emoji' do
    let!(:rocket) { create(:award_emoji, awardable: note, name: 'rocket') }
    let(:request_path) { "/projects/#{project.id}/issues/#{issue.iid}/notes/#{note.id}/award_emoji" }

    it 'returns an array of award emoji' do
      get api(request_path, user)

      expect(response).to have_gitlab_http_status(:ok)
      expect(json_response).to be_an Array
      expect(json_response.first['name']).to eq(rocket.name)
    end

    it_behaves_like 'unauthenticated request to public awardable'
    it_behaves_like 'request with insufficient permissions', :get
  end

  describe "GET /projects/:id/awardable/:awardable_id/award_emoji/:award_id" do
    context 'on an issue' do
      let(:request_path) { "/projects/#{project.id}/issues/#{issue.iid}/award_emoji/#{award_emoji.id}" }

      it "returns the award emoji" do
        get api(request_path, user)

        expect(response).to have_gitlab_http_status(:ok)
        expect(json_response['name']).to eq(award_emoji.name)
        expect(json_response['awardable_id']).to eq(issue.id)
        expect(json_response['awardable_type']).to eq("Issue")
      end

      it "returns a 404 error if the award is not found" do
        get api("/projects/#{project.id}/issues/#{issue.iid}/award_emoji/#{non_existing_record_id}", user)

        expect(response).to have_gitlab_http_status(:not_found)
      end

      it_behaves_like 'unauthenticated request to public awardable'
      it_behaves_like 'request with insufficient permissions', :get
    end

    context 'on a merge request' do
      it 'returns the award emoji' do
        get api("/projects/#{project.id}/merge_requests/#{merge_request.iid}/award_emoji/#{downvote.id}", user)

        expect(response).to have_gitlab_http_status(:ok)
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

        expect(response).to have_gitlab_http_status(:ok)
        expect(json_response['name']).to eq(award.name)
        expect(json_response['awardable_id']).to eq(snippet.id)
        expect(json_response['awardable_type']).to eq("Snippet")
      end
    end
  end

  describe 'GET /projects/:id/awardable/:awardable_id/notes/:note_id/award_emoji/:award_id' do
    let!(:rocket) { create(:award_emoji, awardable: note, name: 'rocket') }
    let(:request_path) { "/projects/#{project.id}/issues/#{issue.iid}/notes/#{note.id}/award_emoji/#{rocket.id}" }

    it 'returns an award emoji' do
      get api(request_path, user)

      expect(response).to have_gitlab_http_status(:ok)
      expect(json_response).not_to be_an Array
      expect(json_response['name']).to eq(rocket.name)
    end

    context 'when a confidential note' do
      subject(:perform_request) { get api(request_path, current_user) }

      let_it_be(:group) { create(:group) }
      let_it_be(:project) { create(:project, :public, namespace: group) }
      let_it_be(:issue) { create(:issue, project: project) }
      let_it_be(:note) { create(:note, :confidential, project: project, noteable: issue, author: user) }

      context 'with sufficient persmissions' do
        let(:current_user) { user }

        it 'returns an award emoji' do
          perform_request

          expect(response).to have_gitlab_http_status(:ok)
          expect(json_response['name']).to eq(rocket.name)
        end
      end

      context 'with insufficient permissions' do
        let(:current_user) { nil }

        it 'returns 404' do
          perform_request

          expect(response).to have_gitlab_http_status(:not_found)
        end
      end
    end

    it_behaves_like 'unauthenticated request to public awardable'
    it_behaves_like 'request with insufficient permissions', :get
  end

  describe "POST /projects/:id/awardable/:awardable_id/award_emoji" do
    let(:issue2) { create(:issue, project: project, author: user) }

    context "on an issue" do
      it "creates a new award emoji" do
        post api("/projects/#{project.id}/issues/#{issue.iid}/award_emoji", user), params: { name: 'blowfish' }

        expect(response).to have_gitlab_http_status(:created)
        expect(json_response['name']).to eq('blowfish')
        expect(json_response['user']['username']).to eq(user.username)
      end

      it 'marks Todos on the Issue as done' do
        todo = create(:todo, target: issue, project: project, user: user)

        post api("/projects/#{project.id}/issues/#{issue.iid}/award_emoji", user), params: { name: '8ball' }

        expect(todo.reload).to be_done
      end

      it "returns a 400 bad request error if the name is not given" do
        post api("/projects/#{project.id}/issues/#{issue.iid}/award_emoji", user)

        expect(response).to have_gitlab_http_status(:bad_request)
      end

      it "normalizes +1 as thumbsup award" do
        post api("/projects/#{project.id}/issues/#{issue.iid}/award_emoji", user), params: { name: '+1' }

        expect(issue.award_emoji.last.name).to eq(AwardEmoji::THUMBS_UP)
      end

      context 'when the emoji already has been awarded' do
        it 'returns a 404 status code' do
          post api("/projects/#{project.id}/issues/#{issue.iid}/award_emoji", user), params: { name: AwardEmoji::THUMBS_UP }
          post api("/projects/#{project.id}/issues/#{issue.iid}/award_emoji", user), params: { name: AwardEmoji::THUMBS_UP }

          expect(response).to have_gitlab_http_status(:not_found)
          expect(json_response["message"]).to match("has already been taken")
        end
      end
    end

    context 'on a snippet' do
      it 'creates a new award emoji' do
        snippet = create(:project_snippet, :public, project: project)

        post api("/projects/#{project.id}/snippets/#{snippet.id}/award_emoji", user), params: { name: 'blowfish' }

        expect(response).to have_gitlab_http_status(:created)
        expect(json_response['name']).to eq('blowfish')
        expect(json_response['user']['username']).to eq(user.username)
      end
    end

    it_behaves_like 'request with insufficient permissions', :post do
      let(:request_path) { "/projects/#{project.id}/issues/#{issue.iid}/award_emoji" }
      let(:request_params) { { name: 'blowfish' } }
    end
  end

  describe "POST /projects/:id/awardable/:awardable_id/notes/:note_id/award_emoji" do
    let(:note2)  { create(:note, project: project, noteable: issue, author: user) }

    it 'creates a new award emoji' do
      expect do
        post api("/projects/#{project.id}/issues/#{issue.iid}/notes/#{note.id}/award_emoji", user), params: { name: 'rocket' }
      end.to change { note.award_emoji.count }.from(0).to(1)

      expect(response).to have_gitlab_http_status(:created)
      expect(json_response['user']['username']).to eq(user.username)
    end

    it 'marks Todos on the Noteable as done' do
      todo = create(:todo, target: note2.noteable, project: project, user: user)

      post api("/projects/#{project.id}/issues/#{issue.iid}/notes/#{note.id}/award_emoji", user), params: { name: 'rocket' }

      expect(todo.reload).to be_done
    end

    it "normalizes +1 as thumbsup award" do
      post api("/projects/#{project.id}/issues/#{issue.iid}/notes/#{note.id}/award_emoji", user), params: { name: '+1' }

      expect(note.award_emoji.last.name).to eq(AwardEmoji::THUMBS_UP)
    end

    context 'when the emoji already has been awarded' do
      it 'returns a 404 status code' do
        post api("/projects/#{project.id}/issues/#{issue.iid}/notes/#{note.id}/award_emoji", user), params: { name: 'rocket' }
        post api("/projects/#{project.id}/issues/#{issue.iid}/notes/#{note.id}/award_emoji", user), params: { name: 'rocket' }

        expect(response).to have_gitlab_http_status(:not_found)
        expect(json_response["message"]).to match("has already been taken")
      end
    end

    it_behaves_like 'request with insufficient permissions', :post do
      let(:request_path) { "/projects/#{project.id}/issues/#{issue.iid}/notes/#{note.id}/award_emoji" }
      let(:request_params) { { name: 'rocket' } }
    end
  end

  describe 'DELETE /projects/:id/awardable/:awardable_id/award_emoji/:award_id' do
    context 'when the awardable is an Issue' do
      it 'deletes the award' do
        expect do
          delete api("/projects/#{project.id}/issues/#{issue.iid}/award_emoji/#{award_emoji.id}", user)

          expect(response).to have_gitlab_http_status(:no_content)
        end.to change { issue.award_emoji.count }.from(1).to(0)
      end

      it 'returns a 404 error when the award emoji can not be found' do
        delete api("/projects/#{project.id}/issues/#{issue.iid}/award_emoji/#{non_existing_record_id}", user)

        expect(response).to have_gitlab_http_status(:not_found)
      end

      it_behaves_like '412 response' do
        let(:request) { api("/projects/#{project.id}/issues/#{issue.iid}/award_emoji/#{award_emoji.id}", user) }
      end
    end

    context 'when the awardable is a Merge Request' do
      it 'deletes the award' do
        expect do
          delete api("/projects/#{project.id}/merge_requests/#{merge_request.iid}/award_emoji/#{downvote.id}", user)

          expect(response).to have_gitlab_http_status(:no_content)
        end.to change { merge_request.award_emoji.count }.from(1).to(0)
      end

      it 'returns a 404 error when note id not found' do
        delete api("/projects/#{project.id}/merge_requests/#{merge_request.iid}/notes/#{non_existing_record_id}", user)

        expect(response).to have_gitlab_http_status(:not_found)
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

          expect(response).to have_gitlab_http_status(:no_content)
        end.to change { snippet.award_emoji.count }.from(1).to(0)
      end

      it_behaves_like '412 response' do
        let(:request) { api("/projects/#{project.id}/snippets/#{snippet.id}/award_emoji/#{award.id}", user) }
      end
    end

    it_behaves_like 'request with insufficient permissions', :delete do
      let(:request_path) { "/projects/#{project.id}/issues/#{issue.iid}/award_emoji/#{award_emoji.id}" }
    end
  end

  describe 'DELETE /projects/:id/awardable/:awardable_id/notes/:note_id/award_emoji/:award_id' do
    let!(:rocket)  { create(:award_emoji, awardable: note, name: 'rocket', user: user) }

    it 'deletes the award' do
      expect do
        delete api("/projects/#{project.id}/issues/#{issue.iid}/notes/#{note.id}/award_emoji/#{rocket.id}", user)

        expect(response).to have_gitlab_http_status(:no_content)
      end.to change { note.award_emoji.count }.from(1).to(0)
    end

    it_behaves_like '412 response' do
      let(:request) { api("/projects/#{project.id}/issues/#{issue.iid}/notes/#{note.id}/award_emoji/#{rocket.id}", user) }
    end

    it_behaves_like 'request with insufficient permissions', :delete do
      let(:request_path) { "/projects/#{project.id}/issues/#{issue.iid}/notes/#{note.id}/award_emoji/#{rocket.id}" }
    end
  end
end
