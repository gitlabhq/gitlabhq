require 'spec_helper'

describe API::API, api: true  do
  include ApiHelpers

  let(:user)        { create(:user) }
  let(:user2)       { create(:user) }
  let(:non_member)  { create(:user) }
  let(:guest)       { create(:user) }
  let(:admin)       { create(:user, :admin) }
  let!(:project)    { create(:project, :public, creator_id: user.id, namespace: user.namespace ) }

  let!(:dev_label) do
    create(:label, title: 'Development', color: '#FFAABB', project: project)
  end

  let!(:test_label) do
    create(:label, title: 'Testing', color: '#FFAACC', project: project)
  end

  let!(:ux_label) do
    create(:label, title: 'UX', color: '#FF0000', project: project)
  end

  let!(:dev_list) do
    create(:list, label: dev_label, position: 1)
  end

  let!(:test_list) do
    create(:list, label: test_label, position: 2)
  end

  let!(:board) do
    create(:board, project: project, lists: [dev_list, test_list])
  end

  before do
    project.team << [user, :reporter]
    project.team << [guest, :guest]
  end

  describe "GET /projects/:id/boards" do
    let(:base_url) { "/projects/#{project.id}/boards" }

    context "when unauthenticated" do
      it "returns authentication error" do
        get api(base_url)

        expect(response).to have_http_status(401)
      end
    end

    context "when authenticated" do
      it "returns the project issue board" do
        get api(base_url, user)

        expect(response).to have_http_status(200)
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
      get api(base_url, user)

      expect(response).to have_http_status(200)
      expect(json_response).to be_an Array
      expect(json_response.length).to eq(2)
      expect(json_response.first['label']['name']).to eq(dev_label.title)
    end

    it 'returns 404 if board not found' do
      get api("/projects/#{project.id}/boards/22343/lists", user)

      expect(response).to have_http_status(404)
    end
  end

  describe "GET /projects/:id/boards/:board_id/lists/:list_id" do
    let(:base_url) { "/projects/#{project.id}/boards/#{board.id}/lists" }

    it 'returns a list' do
      get api("#{base_url}/#{dev_list.id}", user)

      expect(response).to have_http_status(200)
      expect(json_response['id']).to eq(dev_list.id)
      expect(json_response['label']['name']).to eq(dev_label.title)
      expect(json_response['position']).to eq(1)
    end

    it 'returns 404 if list not found' do
      get api("#{base_url}/5324", user)

      expect(response).to have_http_status(404)
    end
  end

  describe "POST /projects/:id/board/lists" do
    let(:base_url) { "/projects/#{project.id}/boards/#{board.id}/lists" }

    it 'creates a new issue board list' do
      post api(base_url, user),
        label_id: ux_label.id

      expect(response).to have_http_status(201)
      expect(json_response['label']['name']).to eq(ux_label.title)
      expect(json_response['position']).to eq(3)
    end

    it 'returns 400 when creating a new list if label_id is invalid' do
      post api(base_url, user),
        label_id: 23423

      expect(response).to have_http_status(400)
    end

    it "returns 403 for project members with guest role" do
      put api("#{base_url}/#{test_list.id}", guest),
        position: 1

      expect(response).to have_http_status(403)
    end
  end

  describe "PUT /projects/:id/boards/:board_id/lists/:list_id to update only position" do
    let(:base_url) { "/projects/#{project.id}/boards/#{board.id}/lists" }

    it "updates a list" do
      put api("#{base_url}/#{test_list.id}", user),
        position: 1

      expect(response).to have_http_status(200)
      expect(json_response['position']).to eq(1)
    end

    it "returns 404 error if list id not found" do
      put api("#{base_url}/44444", user),
        position: 1

      expect(response).to have_http_status(404)
    end

    it "returns 403 for project members with guest role" do
      put api("#{base_url}/#{test_list.id}", guest),
        position: 1

      expect(response).to have_http_status(403)
    end
  end

  describe "DELETE /projects/:id/board/lists/:list_id" do
    let(:base_url) { "/projects/#{project.id}/boards/#{board.id}/lists" }

    it "rejects a non member from deleting a list" do
      delete api("#{base_url}/#{dev_list.id}", non_member)

      expect(response).to have_http_status(403)
    end

    it "rejects a user with guest role from deleting a list" do
      delete api("#{base_url}/#{dev_list.id}", guest)

      expect(response).to have_http_status(403)
    end

    it "returns 404 error if list id not found" do
      delete api("#{base_url}/44444", user)

      expect(response).to have_http_status(404)
    end

    context "when the user is project owner" do
      let(:owner)     { create(:user) }
      let(:project)   { create(:project, namespace: owner.namespace) }

      it "deletes the list if an admin requests it" do
        delete api("#{base_url}/#{dev_list.id}", owner)

        expect(response).to have_http_status(200)
        expect(json_response['position']).to eq(1)
      end
    end
  end
end
