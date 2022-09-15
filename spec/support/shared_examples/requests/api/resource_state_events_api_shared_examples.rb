# frozen_string_literal: true

RSpec.shared_examples 'resource_state_events API' do |parent_type, eventable_type, id_name|
  let(:base_path) { "/#{parent_type}/#{parent.id}/#{eventable_type}/#{eventable[id_name]}" }

  describe "GET /#{parent_type}/:id/#{eventable_type}/:noteable_id/resource_state_events" do
    let!(:event) { create_event }

    it "returns an array of resource state events" do
      url = "#{base_path}/resource_state_events"
      get api(url, user)

      expect(response).to have_gitlab_http_status(:ok)
      expect(response).to include_pagination_headers
      expect(json_response).to be_an Array
      expect(json_response.first['id']).to eq(event.id)
      expect(json_response.first['state']).to eq(event.state.to_s)
    end

    it "returns a 404 error when eventable id not found" do
      get api("/#{parent_type}/#{parent.id}/#{eventable_type}/#{non_existing_record_id}/resource_state_events", user)

      expect(response).to have_gitlab_http_status(:not_found)
    end

    it "returns 404 when not authorized" do
      parent.update!(visibility_level: Gitlab::VisibilityLevel::PRIVATE)
      private_user = create(:user)

      get api("#{base_path}/resource_state_events", private_user)

      expect(response).to have_gitlab_http_status(:not_found)
    end
  end

  describe "GET /#{parent_type}/:id/#{eventable_type}/:noteable_id/resource_state_events/:event_id" do
    let!(:event) { create_event }

    it "returns a resource state event by id" do
      get api("#{base_path}/resource_state_events/#{event.id}", user)

      expect(response).to have_gitlab_http_status(:ok)
      expect(json_response['id']).to eq(event.id)
      expect(json_response['state']).to eq(event.state.to_s)
    end

    it "returns 404 when not authorized" do
      parent.update!(visibility_level: Gitlab::VisibilityLevel::PRIVATE)
      private_user = create(:user)

      get api("#{base_path}/resource_state_events/#{event.id}", private_user)

      expect(response).to have_gitlab_http_status(:not_found)
    end

    it "returns a 404 error if resource state event not found" do
      get api("#{base_path}/resource_state_events/#{non_existing_record_id}", user)

      expect(response).to have_gitlab_http_status(:not_found)
    end
  end

  describe 'pagination' do
    # https://gitlab.com/gitlab-org/gitlab/-/issues/220192
    it 'returns the second page' do
      create_event
      event2 = create_event

      get api("#{base_path}/resource_state_events?page=2&per_page=1", user)

      expect(response).to have_gitlab_http_status(:ok)
      expect(response).to include_pagination_headers
      expect(response.headers['X-Total']).to eq '2'
      expect(json_response.count).to eq(1)
      expect(json_response.first['id']).to eq(event2.id)
    end
  end

  def create_event(state: :opened)
    create(:resource_state_event, eventable.class.name.underscore => eventable, state: state)
  end
end
