# frozen_string_literal: true

RSpec.shared_examples 'resource_label_events API' do |parent_type, eventable_type, id_name|
  describe "GET /#{parent_type}/:id/#{eventable_type}/:noteable_id/resource_label_events" do
    context "with local label reference" do
      let!(:event) { create_event(label) }

      it "returns an array of resource label events" do
        get api("/#{parent_type}/#{parent.id}/#{eventable_type}/#{eventable[id_name]}/resource_label_events", user)

        expect(response).to have_gitlab_http_status(:ok)
        expect(response).to include_pagination_headers
        expect(json_response).to be_an Array
        expect(json_response.first['id']).to eq(event.id)
      end

      it "returns a 404 error when eventable id not found" do
        get api("/#{parent_type}/#{parent.id}/#{eventable_type}/#{non_existing_record_id}/resource_label_events", user)

        expect(response).to have_gitlab_http_status(:not_found)
      end

      it "returns 404 when not authorized" do
        parent.update!(visibility_level: Gitlab::VisibilityLevel::PRIVATE)
        private_user = create(:user)

        get api("/#{parent_type}/#{parent.id}/#{eventable_type}/#{eventable[id_name]}/resource_label_events", private_user)

        expect(response).to have_gitlab_http_status(:not_found)
      end
    end

    context "with cross-project label reference" do
      let(:private_project) { create(:project, :private) }
      let(:project_label) { create(:label, project: private_project) }
      let!(:event) { create_event(project_label) }

      it "returns cross references accessible by user" do
        private_project.add_guest(user)

        get api("/#{parent_type}/#{parent.id}/#{eventable_type}/#{eventable[id_name]}/resource_label_events", user)

        expect(json_response).to be_an Array
        expect(json_response.first['id']).to eq(event.id)
      end

      it "does not return cross references not accessible by user" do
        get api("/#{parent_type}/#{parent.id}/#{eventable_type}/#{eventable[id_name]}/resource_label_events", user)

        expect(json_response).to be_an Array
        expect(json_response).to be_empty
      end
    end
  end

  describe "GET /#{parent_type}/:id/#{eventable_type}/:noteable_id/resource_label_events/:event_id" do
    context "with local label reference" do
      let!(:event) { create_event(label) }

      it "returns a resource label event by id" do
        get api("/#{parent_type}/#{parent.id}/#{eventable_type}/#{eventable[id_name]}/resource_label_events/#{event.id}", user)

        expect(response).to have_gitlab_http_status(:ok)
        expect(json_response['id']).to eq(event.id)
      end

      it "returns 404 when not authorized" do
        parent.update!(visibility_level: Gitlab::VisibilityLevel::PRIVATE)
        private_user = create(:user)

        get api("/#{parent_type}/#{parent.id}/#{eventable_type}/#{eventable[id_name]}/resource_label_events/#{event.id}", private_user)

        expect(response).to have_gitlab_http_status(:not_found)
      end

      it "returns a 404 error if resource label event not found" do
        get api("/#{parent_type}/#{parent.id}/#{eventable_type}/#{eventable[id_name]}/resource_label_events/#{non_existing_record_id}", user)

        expect(response).to have_gitlab_http_status(:not_found)
      end
    end

    context "with cross-project label reference" do
      let(:private_project) { create(:project, :private) }
      let(:project_label) { create(:label, project: private_project) }
      let!(:event) { create_event(project_label) }

      it "returns a 404 error if cross-reference project is not accessible" do
        get api("/#{parent_type}/#{parent.id}/#{eventable_type}/#{eventable[id_name]}/resource_label_events/#{event.id}", user)

        expect(response).to have_gitlab_http_status(:not_found)
      end
    end
  end

  describe 'pagination' do
    let!(:event1) { create_event(label) }
    let!(:event2) { create_event(label) }

    # https://gitlab.com/gitlab-org/gitlab/-/issues/220192
    it "returns the second page" do
      get api("/#{parent_type}/#{parent.id}/#{eventable_type}/#{eventable[id_name]}/resource_label_events?page=2&per_page=1", user)

      expect(response).to have_gitlab_http_status(:ok)
      expect(json_response.count).to eq(1)
      expect(json_response.first['id']).to eq(event2.id)
    end
  end

  def create_event(label)
    create(:resource_label_event, eventable.class.name.underscore => eventable, label: label)
  end
end
