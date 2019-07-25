# frozen_string_literal: true

shared_examples 'resource_label_events API' do |parent_type, eventable_type, id_name|
  describe "GET /#{parent_type}/:id/#{eventable_type}/:noteable_id/resource_label_events" do
    it "returns an array of resource label events" do
      get api("/#{parent_type}/#{parent.id}/#{eventable_type}/#{eventable[id_name]}/resource_label_events", user)

      expect(response).to have_gitlab_http_status(200)
      expect(response).to include_pagination_headers
      expect(json_response).to be_an Array
      expect(json_response.first['id']).to eq(event.id)
    end

    it "returns a 404 error when eventable id not found" do
      get api("/#{parent_type}/#{parent.id}/#{eventable_type}/12345/resource_label_events", user)

      expect(response).to have_gitlab_http_status(404)
    end

    it "returns 404 when not authorized" do
      parent.update!(visibility_level: Gitlab::VisibilityLevel::PRIVATE)

      get api("/#{parent_type}/#{parent.id}/#{eventable_type}/#{eventable[id_name]}/resource_label_events", private_user)

      expect(response).to have_gitlab_http_status(404)
    end
  end

  describe "GET /#{parent_type}/:id/#{eventable_type}/:noteable_id/resource_label_events/:event_id" do
    it "returns a resource label event by id" do
      get api("/#{parent_type}/#{parent.id}/#{eventable_type}/#{eventable[id_name]}/resource_label_events/#{event.id}", user)

      expect(response).to have_gitlab_http_status(200)
      expect(json_response['id']).to eq(event.id)
    end

    it "returns a 404 error if resource label event not found" do
      get api("/#{parent_type}/#{parent.id}/#{eventable_type}/#{eventable[id_name]}/resource_label_events/12345", user)

      expect(response).to have_gitlab_http_status(404)
    end
  end
end
