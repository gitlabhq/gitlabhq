# frozen_string_literal: true

RSpec.shared_examples 'resource_milestone_events API' do |parent_type, eventable_type, id_name|
  describe "GET /#{parent_type}/:id/#{eventable_type}/:noteable_id/resource_milestone_events" do
    let!(:event) { create_event(milestone) }

    it "returns an array of resource milestone events" do
      url = "/#{parent_type}/#{parent.id}/#{eventable_type}/#{eventable[id_name]}/resource_milestone_events"
      get api(url, user)

      expect(response).to have_gitlab_http_status(:ok)
      expect(response).to include_pagination_headers
      expect(json_response).to be_an Array
      expect(json_response.first['id']).to eq(event.id)
      expect(json_response.first['milestone']['id']).to eq(event.milestone.id)
      expect(json_response.first['action']).to eq(event.action)
    end

    it "returns a 404 error when eventable id not found" do
      get api("/#{parent_type}/#{parent.id}/#{eventable_type}/#{non_existing_record_id}/resource_milestone_events", user)

      expect(response).to have_gitlab_http_status(:not_found)
    end

    it "returns 404 when not authorized" do
      parent.update!(visibility_level: Gitlab::VisibilityLevel::PRIVATE)
      private_user = create(:user)

      get api("/#{parent_type}/#{parent.id}/#{eventable_type}/#{eventable[id_name]}/resource_milestone_events", private_user)

      expect(response).to have_gitlab_http_status(:not_found)
    end
  end

  describe "GET /#{parent_type}/:id/#{eventable_type}/:noteable_id/resource_milestone_events/:event_id" do
    let!(:event) { create_event(milestone) }

    it "returns a resource milestone event by id" do
      get api("/#{parent_type}/#{parent.id}/#{eventable_type}/#{eventable[id_name]}/resource_milestone_events/#{event.id}", user)

      expect(response).to have_gitlab_http_status(:ok)
      expect(json_response['id']).to eq(event.id)
      expect(json_response['milestone']['id']).to eq(event.milestone.id)
      expect(json_response['action']).to eq(event.action)
    end

    it "returns 404 when not authorized" do
      parent.update!(visibility_level: Gitlab::VisibilityLevel::PRIVATE)
      private_user = create(:user)

      get api("/#{parent_type}/#{parent.id}/#{eventable_type}/#{eventable[id_name]}/resource_milestone_events/#{event.id}", private_user)

      expect(response).to have_gitlab_http_status(:not_found)
    end

    it "returns a 404 error if resource milestone event not found" do
      get api("/#{parent_type}/#{parent.id}/#{eventable_type}/#{eventable[id_name]}/resource_milestone_events/#{non_existing_record_id}", user)

      expect(response).to have_gitlab_http_status(:not_found)
    end
  end

  def create_event(milestone, action: :add)
    create(:resource_milestone_event, eventable.class.name.underscore => eventable, milestone: milestone, action: action)
  end
end
