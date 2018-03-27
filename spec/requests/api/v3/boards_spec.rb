require 'spec_helper'

describe API::V3::Boards do
  set(:user)        { create(:user) }
  set(:guest)       { create(:user) }
  set(:non_member)  { create(:user) }
  set(:project)    { create(:project, :public, creator_id: user.id, namespace: user.namespace ) }

  set(:dev_label) do
    create(:label, title: 'Development', color: '#FFAABB', project: project)
  end

  set(:test_label) do
    create(:label, title: 'Testing', color: '#FFAACC', project: project)
  end

  set(:dev_list) do
    create(:list, label: dev_label, position: 1)
  end

  set(:test_list) do
    create(:list, label: test_label, position: 2)
  end

  set(:board) do
    create(:board, project: project, lists: [dev_list, test_list])
  end

  before do
    project.add_reporter(user)
    project.add_guest(guest)
  end

  describe "GET /projects/:id/boards" do
    let(:base_url) { "/projects/#{project.id}/boards" }

    context "when unauthenticated" do
      it "returns authentication error" do
        get v3_api(base_url)

        expect(response).to have_gitlab_http_status(401)
      end
    end

    context "when authenticated" do
      it "returns the project issue board" do
        get v3_api(base_url, user)

        expect(response).to have_gitlab_http_status(200)
        expect(json_response).to be_an Array
        expect(json_response.length).to eq(1)
        expect(json_response.first['id']).to eq(board.id)
        expect(json_response.first['lists']).to be_an Array
        expect(json_response.first['lists'].length).to eq(2)
        expect(json_response.first['lists'].last).to have_key('position')
      end
    end
  end

  describe "GET /projects/:id/boards/:board_id/lists" do
    let(:base_url) { "/projects/#{project.id}/boards/#{board.id}/lists" }

    it 'returns issue board lists' do
      get v3_api(base_url, user)

      expect(response).to have_gitlab_http_status(200)
      expect(json_response).to be_an Array
      expect(json_response.length).to eq(2)
      expect(json_response.first['label']['name']).to eq(dev_label.title)
    end

    it 'returns 404 if board not found' do
      get v3_api("/projects/#{project.id}/boards/22343/lists", user)

      expect(response).to have_gitlab_http_status(404)
    end
  end

  describe "DELETE /projects/:id/board/lists/:list_id" do
    let(:base_url) { "/projects/#{project.id}/boards/#{board.id}/lists" }

    it "rejects a non member from deleting a list" do
      delete v3_api("#{base_url}/#{dev_list.id}", non_member)

      expect(response).to have_gitlab_http_status(403)
    end

    it "rejects a user with guest role from deleting a list" do
      delete v3_api("#{base_url}/#{dev_list.id}", guest)

      expect(response).to have_gitlab_http_status(403)
    end

    it "returns 404 error if list id not found" do
      delete v3_api("#{base_url}/44444", user)

      expect(response).to have_gitlab_http_status(404)
    end

    context "when the user is project owner" do
      set(:owner) { create(:user) }

      before do
        project.update(namespace: owner.namespace)
      end

      it "deletes the list if an admin requests it" do
        delete v3_api("#{base_url}/#{dev_list.id}", owner)

        expect(response).to have_gitlab_http_status(200)
      end
    end
  end
end
