# frozen_string_literal: true

RSpec.shared_examples 'group and project boards' do |route_definition, ee = false|
  let(:root_url) { route_definition.gsub(":id", board_parent.id.to_s) }

  before do
    board_parent.add_reporter(user)
    board_parent.add_guest(guest)
  end

  def expect_schema_match_for(response, schema_file, ee)
    if ee
      expect(response).to match_response_schema(schema_file, dir: "ee")
    else
      expect(response).to match_response_schema(schema_file)
    end
  end

  it 'avoids N+1 queries' do
    pat = create(:personal_access_token, user: user)
    control = ActiveRecord::QueryRecorder.new { get api(root_url, personal_access_token: pat) }

    create(:milestone, "#{board_parent.class.name.underscore}": board_parent)
    create(:board, "#{board_parent.class.name.underscore}": board_parent)

    expect { get api(root_url, personal_access_token: pat) }.not_to exceed_query_limit(control)
  end

  describe "GET #{route_definition}" do
    context "when unauthenticated" do
      it "returns authentication error" do
        get api(root_url)

        expect(response).to have_gitlab_http_status(:unauthorized)
      end
    end

    context "when authenticated" do
      it "returns the issue boards" do
        get api(root_url, user)

        expect(response).to have_gitlab_http_status(:ok)
        expect(response).to include_pagination_headers

        expect_schema_match_for(response, 'public_api/v4/boards', ee)
      end
    end
  end

  describe "GET #{route_definition}/:board_id" do
    let(:url) { "#{root_url}/#{board.id}" }

    it 'get a single board by id' do
      get api(url, user)

      expect_schema_match_for(response, 'public_api/v4/board', ee)
    end
  end

  describe "PUT #{route_definition}/:board_id" do
    let(:url) { "#{root_url}/#{board.id}" }

    it 'updates the board name' do
      put api(url, user), params: { name: 'changed board name' }

      expect(response).to have_gitlab_http_status(:ok)
      expect(json_response['name']).to eq('changed board name')
    end

    it 'updates the issue board booleans' do
      put api(url, user), params: { hide_backlog_list: true, hide_closed_list: true }

      expect(response).to have_gitlab_http_status(:ok)
      expect(json_response['hide_backlog_list']).to eq(true)
      expect(json_response['hide_closed_list']).to eq(true)
    end
  end

  describe "GET #{route_definition}/:board_id/lists" do
    let(:url) { "#{root_url}/#{board.id}/lists" }

    it 'returns issue board lists' do
      get api(url, user)

      expect(response).to have_gitlab_http_status(:ok)
      expect(response).to include_pagination_headers
      expect(json_response).to be_an Array
      expect(json_response.length).to eq(2)
      expect(json_response.first['label']['name']).to eq(dev_label.title)
    end

    it 'returns 404 if board not found' do
      get api("#{root_url}/22343/lists", user)

      expect(response).to have_gitlab_http_status(:not_found)
    end
  end

  describe "GET #{route_definition}/:board_id/lists/:list_id" do
    let(:url) { "#{root_url}/#{board.id}/lists" }

    it 'returns a list' do
      get api("#{url}/#{dev_list.id}", user)

      expect(response).to have_gitlab_http_status(:ok)
      expect(json_response['id']).to eq(dev_list.id)
      expect(json_response['label']['name']).to eq(dev_label.title)
      expect(json_response['position']).to eq(1)
    end

    it 'returns 404 if list not found' do
      get api("#{url}/5324", user)

      expect(response).to have_gitlab_http_status(:not_found)
    end
  end

  describe "POST #{route_definition}/lists" do
    let(:url) { "#{root_url}/#{board.id}/lists" }

    it 'creates a new issue board list for labels' do
      post api(url, user), params: { label_id: ux_label.id }

      expect(response).to have_gitlab_http_status(:created)
      expect(json_response['label']['name']).to eq(ux_label.title)
      expect(json_response['position']).to eq(3)
    end

    it 'returns 400 when creating a new list if label_id is invalid' do
      post api(url, user), params: { label_id: 23423 }

      expect(response).to have_gitlab_http_status(:bad_request)
    end

    it 'returns 403 for members with guest role' do
      put api("#{url}/#{test_list.id}", guest), params: { position: 1 }

      expect(response).to have_gitlab_http_status(:forbidden)
    end
  end

  describe "PUT #{route_definition}/:board_id/lists/:list_id to update only position" do
    let(:url) { "#{root_url}/#{board.id}/lists" }

    it "updates a list" do
      put api("#{url}/#{test_list.id}", user), params: { position: 1 }

      expect(response).to have_gitlab_http_status(:ok)
      expect(json_response['position']).to eq(1)
    end

    it "returns 404 error if list id not found" do
      put api("#{url}/44444", user), params: { position: 1 }

      expect(response).to have_gitlab_http_status(:not_found)
    end

    it "returns 403 for members with guest role" do
      put api("#{url}/#{test_list.id}", guest), params: { position: 1 }

      expect(response).to have_gitlab_http_status(:forbidden)
    end
  end

  describe "DELETE #{route_definition}/lists/:list_id" do
    let(:url) { "#{root_url}/#{board.id}/lists" }

    it "rejects a non member from deleting a list" do
      delete api("#{url}/#{dev_list.id}", non_member)

      expect(response).to have_gitlab_http_status(:forbidden)
    end

    it "rejects a user with guest role from deleting a list" do
      delete api("#{url}/#{dev_list.id}", guest)

      expect(response).to have_gitlab_http_status(:forbidden)
    end

    it "returns 404 error if list id not found" do
      delete api("#{url}/44444", user)

      expect(response).to have_gitlab_http_status(:not_found)
    end

    context "when the user is parent owner" do
      let_it_be(:owner, reload: true) { create(:user) }

      before do
        if board_parent.try(:namespace)
          board_parent.update!(namespace: owner.namespace)
        else
          board.resource_parent.add_owner(owner)
        end
      end

      it "deletes the list if an admin requests it" do
        delete api("#{url}/#{dev_list.id}", owner)

        expect(response).to have_gitlab_http_status(:no_content)
      end

      it_behaves_like '412 response' do
        let(:request) { api("#{url}/#{dev_list.id}", owner) }
      end
    end
  end
end
