require 'spec_helper'

describe API::V3::Labels do
  let(:user) { create(:user) }
  let(:project) { create(:project, creator_id: user.id, namespace: user.namespace) }
  let!(:label1) { create(:label, title: 'label1', project: project) }
  let!(:priority_label) { create(:label, title: 'bug', project: project, priority: 3) }

  before do
    project.add_master(user)
  end

  describe 'GET /projects/:id/labels' do
    it 'returns all available labels to the project' do
      group = create(:group)
      group_label = create(:group_label, title: 'feature', group: group)
      project.update(group: group)
      create(:labeled_issue, project: project, labels: [group_label], author: user)
      create(:labeled_issue, project: project, labels: [label1], author: user, state: :closed)
      create(:labeled_merge_request, labels: [priority_label], author: user, source_project: project )

      expected_keys = %w(
        id name color description
        open_issues_count closed_issues_count open_merge_requests_count
        subscribed priority
      )

      get v3_api("/projects/#{project.id}/labels", user)

      expect(response).to have_gitlab_http_status(200)
      expect(json_response).to be_an Array
      expect(json_response.size).to eq(3)
      expect(json_response.first.keys).to match_array expected_keys
      expect(json_response.map { |l| l['name'] }).to match_array([group_label.name, priority_label.name, label1.name])

      label1_response = json_response.find { |l| l['name'] == label1.title }
      group_label_response = json_response.find { |l| l['name'] == group_label.title }
      priority_label_response = json_response.find { |l| l['name'] == priority_label.title }

      expect(label1_response['open_issues_count']).to eq(0)
      expect(label1_response['closed_issues_count']).to eq(1)
      expect(label1_response['open_merge_requests_count']).to eq(0)
      expect(label1_response['name']).to eq(label1.name)
      expect(label1_response['color']).to be_present
      expect(label1_response['description']).to be_nil
      expect(label1_response['priority']).to be_nil
      expect(label1_response['subscribed']).to be_falsey

      expect(group_label_response['open_issues_count']).to eq(1)
      expect(group_label_response['closed_issues_count']).to eq(0)
      expect(group_label_response['open_merge_requests_count']).to eq(0)
      expect(group_label_response['name']).to eq(group_label.name)
      expect(group_label_response['color']).to be_present
      expect(group_label_response['description']).to be_nil
      expect(group_label_response['priority']).to be_nil
      expect(group_label_response['subscribed']).to be_falsey

      expect(priority_label_response['open_issues_count']).to eq(0)
      expect(priority_label_response['closed_issues_count']).to eq(0)
      expect(priority_label_response['open_merge_requests_count']).to eq(1)
      expect(priority_label_response['name']).to eq(priority_label.name)
      expect(priority_label_response['color']).to be_present
      expect(priority_label_response['description']).to be_nil
      expect(priority_label_response['priority']).to eq(3)
      expect(priority_label_response['subscribed']).to be_falsey
    end
  end

  describe "POST /projects/:id/labels/:label_id/subscription" do
    context "when label_id is a label title" do
      it "subscribes to the label" do
        post v3_api("/projects/#{project.id}/labels/#{label1.title}/subscription", user)

        expect(response).to have_gitlab_http_status(201)
        expect(json_response["name"]).to eq(label1.title)
        expect(json_response["subscribed"]).to be_truthy
      end
    end

    context "when label_id is a label ID" do
      it "subscribes to the label" do
        post v3_api("/projects/#{project.id}/labels/#{label1.id}/subscription", user)

        expect(response).to have_gitlab_http_status(201)
        expect(json_response["name"]).to eq(label1.title)
        expect(json_response["subscribed"]).to be_truthy
      end
    end

    context "when user is already subscribed to label" do
      before { label1.subscribe(user, project) }

      it "returns 304" do
        post v3_api("/projects/#{project.id}/labels/#{label1.id}/subscription", user)

        expect(response).to have_gitlab_http_status(304)
      end
    end

    context "when label ID is not found" do
      it "returns 404 error" do
        post v3_api("/projects/#{project.id}/labels/1234/subscription", user)

        expect(response).to have_gitlab_http_status(404)
      end
    end
  end

  describe "DELETE /projects/:id/labels/:label_id/subscription" do
    before { label1.subscribe(user, project) }

    context "when label_id is a label title" do
      it "unsubscribes from the label" do
        delete v3_api("/projects/#{project.id}/labels/#{label1.title}/subscription", user)

        expect(response).to have_gitlab_http_status(200)
        expect(json_response["name"]).to eq(label1.title)
        expect(json_response["subscribed"]).to be_falsey
      end
    end

    context "when label_id is a label ID" do
      it "unsubscribes from the label" do
        delete v3_api("/projects/#{project.id}/labels/#{label1.id}/subscription", user)

        expect(response).to have_gitlab_http_status(200)
        expect(json_response["name"]).to eq(label1.title)
        expect(json_response["subscribed"]).to be_falsey
      end
    end

    context "when user is already unsubscribed from label" do
      before { label1.unsubscribe(user, project) }

      it "returns 304" do
        delete v3_api("/projects/#{project.id}/labels/#{label1.id}/subscription", user)

        expect(response).to have_gitlab_http_status(304)
      end
    end

    context "when label ID is not found" do
      it "returns 404 error" do
        delete v3_api("/projects/#{project.id}/labels/1234/subscription", user)

        expect(response).to have_gitlab_http_status(404)
      end
    end
  end

  describe 'DELETE /projects/:id/labels' do
    it 'returns 200 for existing label' do
      delete v3_api("/projects/#{project.id}/labels", user), name: 'label1'

      expect(response).to have_gitlab_http_status(200)
    end

    it 'returns 404 for non existing label' do
      delete v3_api("/projects/#{project.id}/labels", user), name: 'label2'
      expect(response).to have_gitlab_http_status(404)
      expect(json_response['message']).to eq('404 Label Not Found')
    end

    it 'returns 400 for wrong parameters' do
      delete v3_api("/projects/#{project.id}/labels", user)
      expect(response).to have_gitlab_http_status(400)
    end
  end
end
