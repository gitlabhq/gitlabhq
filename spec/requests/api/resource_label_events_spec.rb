# frozen_string_literal: true

require 'spec_helper'

describe API::ResourceLabelEvents do
  set(:user) { create(:user) }
  set(:project) { create(:project, :public, :repository, namespace: user.namespace) }
  set(:private_user)    { create(:user) }

  before do
    project.add_developer(user)
  end

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

  context 'when eventable is an Issue' do
    let(:issue) { create(:issue, project: project, author: user) }

    it_behaves_like 'resource_label_events API', 'projects', 'issues', 'iid' do
      let(:parent) { project }
      let(:eventable) { issue }
      let!(:event) { create(:resource_label_event, issue: issue) }
    end
  end

<<<<<<< HEAD
  context 'when eventable is an Epic' do
    let(:group) { create(:group, :public) }
    let(:epic) { create(:epic, group: group, author: user) }

    before do
      group.add_owner(user)
      stub_licensed_features(epics: true)
    end

    it_behaves_like 'resource_label_events API', 'groups', 'epics', 'id' do
      let(:parent) { group }
      let(:eventable) { epic }
      let!(:event) { create(:resource_label_event, epic: epic) }
    end
  end

=======
>>>>>>> upstream/master
  context 'when eventable is a Merge Request' do
    let(:merge_request) { create(:merge_request, source_project: project, target_project: project, author: user) }

    it_behaves_like 'resource_label_events API', 'projects', 'merge_requests', 'iid' do
      let(:parent) { project }
      let(:eventable) { merge_request }
      let!(:event) { create(:resource_label_event, merge_request: merge_request) }
    end
  end
end
