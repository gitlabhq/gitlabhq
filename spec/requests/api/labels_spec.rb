require 'spec_helper'

describe API::Labels do
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

      get api("/projects/#{project.id}/labels", user)

      expect(response).to have_gitlab_http_status(200)
      expect(response).to include_pagination_headers
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

  describe 'POST /projects/:id/labels' do
    it 'returns created label when all params' do
      post api("/projects/#{project.id}/labels", user),
           name: 'Foo',
           color: '#FFAABB',
           description: 'test',
           priority: 2

      expect(response).to have_gitlab_http_status(201)
      expect(json_response['name']).to eq('Foo')
      expect(json_response['color']).to eq('#FFAABB')
      expect(json_response['description']).to eq('test')
      expect(json_response['priority']).to eq(2)
    end

    it 'returns created label when only required params' do
      post api("/projects/#{project.id}/labels", user),
           name: 'Foo & Bar',
           color: '#FFAABB'

      expect(response.status).to eq(201)
      expect(json_response['name']).to eq('Foo & Bar')
      expect(json_response['color']).to eq('#FFAABB')
      expect(json_response['description']).to be_nil
      expect(json_response['priority']).to be_nil
    end

    it 'creates a prioritized label' do
      post api("/projects/#{project.id}/labels", user),
           name: 'Foo & Bar',
           color: '#FFAABB',
           priority: 3

      expect(response.status).to eq(201)
      expect(json_response['name']).to eq('Foo & Bar')
      expect(json_response['color']).to eq('#FFAABB')
      expect(json_response['description']).to be_nil
      expect(json_response['priority']).to eq(3)
    end

    it 'returns a 400 bad request if name not given' do
      post api("/projects/#{project.id}/labels", user), color: '#FFAABB'
      expect(response).to have_gitlab_http_status(400)
    end

    it 'returns a 400 bad request if color not given' do
      post api("/projects/#{project.id}/labels", user), name: 'Foobar'
      expect(response).to have_gitlab_http_status(400)
    end

    it 'returns 400 for invalid color' do
      post api("/projects/#{project.id}/labels", user),
           name: 'Foo',
           color: '#FFAA'
      expect(response).to have_gitlab_http_status(400)
      expect(json_response['message']['color']).to eq(['must be a valid color code'])
    end

    it 'returns 400 for too long color code' do
      post api("/projects/#{project.id}/labels", user),
           name: 'Foo',
           color: '#FFAAFFFF'
      expect(response).to have_gitlab_http_status(400)
      expect(json_response['message']['color']).to eq(['must be a valid color code'])
    end

    it 'returns 400 for invalid name' do
      post api("/projects/#{project.id}/labels", user),
           name: ',',
           color: '#FFAABB'
      expect(response).to have_gitlab_http_status(400)
      expect(json_response['message']['title']).to eq(['is invalid'])
    end

    it 'returns 409 if label already exists in group' do
      group = create(:group)
      group_label = create(:group_label, group: group)
      project.update(group: group)

      post api("/projects/#{project.id}/labels", user),
           name: group_label.name,
           color: '#FFAABB'

      expect(response).to have_gitlab_http_status(409)
      expect(json_response['message']).to eq('Label already exists')
    end

    it 'returns 400 for invalid priority' do
      post api("/projects/#{project.id}/labels", user),
           name: 'Foo',
           color: '#FFAAFFFF',
           priority: 'foo'

      expect(response).to have_gitlab_http_status(400)
    end

    it 'returns 409 if label already exists in project' do
      post api("/projects/#{project.id}/labels", user),
           name: 'label1',
           color: '#FFAABB'
      expect(response).to have_gitlab_http_status(409)
      expect(json_response['message']).to eq('Label already exists')
    end
  end

  describe 'DELETE /projects/:id/labels' do
    it 'returns 204 for existing label' do
      delete api("/projects/#{project.id}/labels", user), name: 'label1'

      expect(response).to have_gitlab_http_status(204)
    end

    it 'returns 404 for non existing label' do
      delete api("/projects/#{project.id}/labels", user), name: 'label2'
      expect(response).to have_gitlab_http_status(404)
      expect(json_response['message']).to eq('404 Label Not Found')
    end

    it 'returns 400 for wrong parameters' do
      delete api("/projects/#{project.id}/labels", user)
      expect(response).to have_gitlab_http_status(400)
    end

    it_behaves_like '412 response' do
      let(:request) { api("/projects/#{project.id}/labels", user) }
      let(:params) { { name: 'label1' } }
    end
  end

  describe 'PUT /projects/:id/labels' do
    it 'returns 200 if name and colors and description are changed' do
      put api("/projects/#{project.id}/labels", user),
          name: 'label1',
          new_name: 'New Label',
          color: '#FFFFFF',
          description: 'test'
      expect(response).to have_gitlab_http_status(200)
      expect(json_response['name']).to eq('New Label')
      expect(json_response['color']).to eq('#FFFFFF')
      expect(json_response['description']).to eq('test')
    end

    it 'returns 200 if name is changed' do
      put api("/projects/#{project.id}/labels", user),
          name: 'label1',
          new_name: 'New Label'
      expect(response).to have_gitlab_http_status(200)
      expect(json_response['name']).to eq('New Label')
      expect(json_response['color']).to eq(label1.color)
    end

    it 'returns 200 if colors is changed' do
      put api("/projects/#{project.id}/labels", user),
          name: 'label1',
          color: '#FFFFFF'
      expect(response).to have_gitlab_http_status(200)
      expect(json_response['name']).to eq(label1.name)
      expect(json_response['color']).to eq('#FFFFFF')
    end

    it 'returns 200 if description is changed' do
      put api("/projects/#{project.id}/labels", user),
          name: 'bug',
          description: 'test'

      expect(response).to have_gitlab_http_status(200)
      expect(json_response['name']).to eq(priority_label.name)
      expect(json_response['description']).to eq('test')
      expect(json_response['priority']).to eq(3)
    end

    it 'returns 200 if priority is changed' do
      put api("/projects/#{project.id}/labels", user),
           name: 'bug',
           priority: 10

      expect(response.status).to eq(200)
      expect(json_response['name']).to eq(priority_label.name)
      expect(json_response['priority']).to eq(10)
    end

    it 'returns 200 if a priority is added' do
      put api("/projects/#{project.id}/labels", user),
           name: 'label1',
           priority: 3

      expect(response.status).to eq(200)
      expect(json_response['name']).to eq(label1.name)
      expect(json_response['priority']).to eq(3)
    end

    it 'returns 200 if the priority is removed' do
      put api("/projects/#{project.id}/labels", user),
          name: priority_label.name,
          priority: nil

      expect(response.status).to eq(200)
      expect(json_response['name']).to eq(priority_label.name)
      expect(json_response['priority']).to be_nil
    end

    it 'returns 404 if label does not exist' do
      put api("/projects/#{project.id}/labels", user),
          name: 'label2',
          new_name: 'label3'
      expect(response).to have_gitlab_http_status(404)
    end

    it 'returns 400 if no label name given' do
      put api("/projects/#{project.id}/labels", user), new_name: 'label2'
      expect(response).to have_gitlab_http_status(400)
      expect(json_response['error']).to eq('name is missing')
    end

    it 'returns 400 if no new parameters given' do
      put api("/projects/#{project.id}/labels", user), name: 'label1'
      expect(response).to have_gitlab_http_status(400)
      expect(json_response['error']).to eq('new_name, color, description, priority are missing, '\
                                           'at least one parameter must be provided')
    end

    it 'returns 400 for invalid name' do
      put api("/projects/#{project.id}/labels", user),
          name: 'label1',
          new_name: ',',
          color: '#FFFFFF'
      expect(response).to have_gitlab_http_status(400)
      expect(json_response['message']['title']).to eq(['is invalid'])
    end

    it 'returns 400 when color code is too short' do
      put api("/projects/#{project.id}/labels", user),
          name: 'label1',
          color: '#FF'
      expect(response).to have_gitlab_http_status(400)
      expect(json_response['message']['color']).to eq(['must be a valid color code'])
    end

    it 'returns 400 for too long color code' do
      post api("/projects/#{project.id}/labels", user),
           name: 'Foo',
           color: '#FFAAFFFF'
      expect(response).to have_gitlab_http_status(400)
      expect(json_response['message']['color']).to eq(['must be a valid color code'])
    end

    it 'returns 400 for invalid priority' do
      post api("/projects/#{project.id}/labels", user),
           name: 'Foo',
           priority: 'foo'

      expect(response).to have_gitlab_http_status(400)
    end
  end

  describe "POST /projects/:id/labels/:label_id/subscribe" do
    context "when label_id is a label title" do
      it "subscribes to the label" do
        post api("/projects/#{project.id}/labels/#{label1.title}/subscribe", user)

        expect(response).to have_gitlab_http_status(201)
        expect(json_response["name"]).to eq(label1.title)
        expect(json_response["subscribed"]).to be_truthy
      end
    end

    context "when label_id is a label ID" do
      it "subscribes to the label" do
        post api("/projects/#{project.id}/labels/#{label1.id}/subscribe", user)

        expect(response).to have_gitlab_http_status(201)
        expect(json_response["name"]).to eq(label1.title)
        expect(json_response["subscribed"]).to be_truthy
      end
    end

    context "when user is already subscribed to label" do
      before do
        label1.subscribe(user, project)
      end

      it "returns 304" do
        post api("/projects/#{project.id}/labels/#{label1.id}/subscribe", user)

        expect(response).to have_gitlab_http_status(304)
      end
    end

    context "when label ID is not found" do
      it "returns 404 error" do
        post api("/projects/#{project.id}/labels/1234/subscribe", user)

        expect(response).to have_gitlab_http_status(404)
      end
    end
  end

  describe "POST /projects/:id/labels/:label_id/unsubscribe" do
    before do
      label1.subscribe(user, project)
    end

    context "when label_id is a label title" do
      it "unsubscribes from the label" do
        post api("/projects/#{project.id}/labels/#{label1.title}/unsubscribe", user)

        expect(response).to have_gitlab_http_status(201)
        expect(json_response["name"]).to eq(label1.title)
        expect(json_response["subscribed"]).to be_falsey
      end
    end

    context "when label_id is a label ID" do
      it "unsubscribes from the label" do
        post api("/projects/#{project.id}/labels/#{label1.id}/unsubscribe", user)

        expect(response).to have_gitlab_http_status(201)
        expect(json_response["name"]).to eq(label1.title)
        expect(json_response["subscribed"]).to be_falsey
      end
    end

    context "when user is already unsubscribed from label" do
      before do
        label1.unsubscribe(user, project)
      end

      it "returns 304" do
        post api("/projects/#{project.id}/labels/#{label1.id}/unsubscribe", user)

        expect(response).to have_gitlab_http_status(304)
      end
    end

    context "when label ID is not found" do
      it "returns 404 error" do
        post api("/projects/#{project.id}/labels/1234/unsubscribe", user)

        expect(response).to have_gitlab_http_status(404)
      end
    end
  end
end
