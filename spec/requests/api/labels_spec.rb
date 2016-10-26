require 'spec_helper'

describe API::API, api: true  do
  include ApiHelpers

  let(:user) { create(:user) }
  let(:project) { create(:project, creator_id: user.id, namespace: user.namespace) }
  let!(:label1) { create(:label, title: 'label1', project: project) }

  before do
    project.team << [user, :master]
  end

  describe 'GET /projects/:id/labels' do
    it 'returns all available labels to the project' do
      group = create(:group)
      group_label = create(:group_label, group: group)
      project.update(group: group)

      get api("/projects/#{project.id}/labels", user)

      expect(response).to have_http_status(200)
      expect(json_response).to be_an Array
      expect(json_response.size).to eq(2)
      expect(json_response.map { |l| l['name'] }).to match_array([group_label.name, label1.name])
    end
  end

  describe 'POST /projects/:id/labels' do
    it 'returns created label when all params' do
      post api("/projects/#{project.id}/labels", user),
           name: 'Foo',
           color: '#FFAABB',
           description: 'test'
      expect(response).to have_http_status(201)
      expect(json_response['name']).to eq('Foo')
      expect(json_response['color']).to eq('#FFAABB')
      expect(json_response['description']).to eq('test')
    end

    it 'returns created label when only required params' do
      post api("/projects/#{project.id}/labels", user),
           name: 'Foo & Bar',
           color: '#FFAABB'
      expect(response.status).to eq(201)
      expect(json_response['name']).to eq('Foo & Bar')
      expect(json_response['color']).to eq('#FFAABB')
      expect(json_response['description']).to be_nil
    end

    it 'returns a 400 bad request if name not given' do
      post api("/projects/#{project.id}/labels", user), color: '#FFAABB'
      expect(response).to have_http_status(400)
    end

    it 'returns a 400 bad request if color not given' do
      post api("/projects/#{project.id}/labels", user), name: 'Foobar'
      expect(response).to have_http_status(400)
    end

    it 'returns 400 for invalid color' do
      post api("/projects/#{project.id}/labels", user),
           name: 'Foo',
           color: '#FFAA'
      expect(response).to have_http_status(400)
      expect(json_response['message']['color']).to eq(['must be a valid color code'])
    end

    it 'returns 400 for too long color code' do
      post api("/projects/#{project.id}/labels", user),
           name: 'Foo',
           color: '#FFAAFFFF'
      expect(response).to have_http_status(400)
      expect(json_response['message']['color']).to eq(['must be a valid color code'])
    end

    it 'returns 400 for invalid name' do
      post api("/projects/#{project.id}/labels", user),
           name: ',',
           color: '#FFAABB'
      expect(response).to have_http_status(400)
      expect(json_response['message']['title']).to eq(['is invalid'])
    end

    it 'returns 409 if label already exists' do
      post api("/projects/#{project.id}/labels", user),
           name: 'label1',
           color: '#FFAABB'
      expect(response).to have_http_status(409)
      expect(json_response['message']).to eq('Label already exists')
    end
  end

  describe 'DELETE /projects/:id/labels' do
    it 'returns 200 for existing label' do
      delete api("/projects/#{project.id}/labels", user), name: 'label1'
      expect(response).to have_http_status(200)
    end

    it 'returns 404 for non existing label' do
      delete api("/projects/#{project.id}/labels", user), name: 'label2'
      expect(response).to have_http_status(404)
      expect(json_response['message']).to eq('404 Label Not Found')
    end

    it 'returns 400 for wrong parameters' do
      delete api("/projects/#{project.id}/labels", user)
      expect(response).to have_http_status(400)
    end
  end

  describe 'PUT /projects/:id/labels' do
    it 'returns 200 if name and colors and description are changed' do
      put api("/projects/#{project.id}/labels", user),
          name: 'label1',
          new_name: 'New Label',
          color: '#FFFFFF',
          description: 'test'
      expect(response).to have_http_status(200)
      expect(json_response['name']).to eq('New Label')
      expect(json_response['color']).to eq('#FFFFFF')
      expect(json_response['description']).to eq('test')
    end

    it 'returns 200 if name is changed' do
      put api("/projects/#{project.id}/labels", user),
          name: 'label1',
          new_name: 'New Label'
      expect(response).to have_http_status(200)
      expect(json_response['name']).to eq('New Label')
      expect(json_response['color']).to eq(label1.color)
    end

    it 'returns 200 if colors is changed' do
      put api("/projects/#{project.id}/labels", user),
          name: 'label1',
          color: '#FFFFFF'
      expect(response).to have_http_status(200)
      expect(json_response['name']).to eq(label1.name)
      expect(json_response['color']).to eq('#FFFFFF')
    end

    it 'returns 200 if description is changed' do
      put api("/projects/#{project.id}/labels", user),
          name: 'label1',
          description: 'test'
      expect(response).to have_http_status(200)
      expect(json_response['name']).to eq(label1.name)
      expect(json_response['description']).to eq('test')
    end

    it 'returns 404 if label does not exist' do
      put api("/projects/#{project.id}/labels", user),
          name: 'label2',
          new_name: 'label3'
      expect(response).to have_http_status(404)
    end

    it 'returns 400 if no label name given' do
      put api("/projects/#{project.id}/labels", user), new_name: 'label2'
      expect(response).to have_http_status(400)
      expect(json_response['error']).to eq('name is missing')
    end

    it 'returns 400 if no new parameters given' do
      put api("/projects/#{project.id}/labels", user), name: 'label1'
      expect(response).to have_http_status(400)
      expect(json_response['error']).to eq('new_name, color, description are missing, '\
                                           'at least one parameter must be provided')
    end

    it 'returns 400 for invalid name' do
      put api("/projects/#{project.id}/labels", user),
          name: 'label1',
          new_name: ',',
          color: '#FFFFFF'
      expect(response).to have_http_status(400)
      expect(json_response['message']['title']).to eq(['is invalid'])
    end

    it 'returns 400 when color code is too short' do
      put api("/projects/#{project.id}/labels", user),
          name: 'label1',
          color: '#FF'
      expect(response).to have_http_status(400)
      expect(json_response['message']['color']).to eq(['must be a valid color code'])
    end

    it 'returns 400 for too long color code' do
      post api("/projects/#{project.id}/labels", user),
           name: 'Foo',
           color: '#FFAAFFFF'
      expect(response).to have_http_status(400)
      expect(json_response['message']['color']).to eq(['must be a valid color code'])
    end
  end

  describe "POST /projects/:id/labels/:label_id/subscription" do
    context "when label_id is a label title" do
      it "subscribes to the label" do
        post api("/projects/#{project.id}/labels/#{label1.title}/subscription", user)

        expect(response).to have_http_status(201)
        expect(json_response["name"]).to eq(label1.title)
        expect(json_response["subscribed"]).to be_truthy
      end
    end

    context "when label_id is a label ID" do
      it "subscribes to the label" do
        post api("/projects/#{project.id}/labels/#{label1.id}/subscription", user)

        expect(response).to have_http_status(201)
        expect(json_response["name"]).to eq(label1.title)
        expect(json_response["subscribed"]).to be_truthy
      end
    end

    context "when user is already subscribed to label" do
      before { label1.subscribe(user) }

      it "returns 304" do
        post api("/projects/#{project.id}/labels/#{label1.id}/subscription", user)

        expect(response).to have_http_status(304)
      end
    end

    context "when label ID is not found" do
      it "returns 404 error" do
        post api("/projects/#{project.id}/labels/1234/subscription", user)

        expect(response).to have_http_status(404)
      end
    end
  end

  describe "DELETE /projects/:id/labels/:label_id/subscription" do
    before { label1.subscribe(user) }

    context "when label_id is a label title" do
      it "unsubscribes from the label" do
        delete api("/projects/#{project.id}/labels/#{label1.title}/subscription", user)

        expect(response).to have_http_status(200)
        expect(json_response["name"]).to eq(label1.title)
        expect(json_response["subscribed"]).to be_falsey
      end
    end

    context "when label_id is a label ID" do
      it "unsubscribes from the label" do
        delete api("/projects/#{project.id}/labels/#{label1.id}/subscription", user)

        expect(response).to have_http_status(200)
        expect(json_response["name"]).to eq(label1.title)
        expect(json_response["subscribed"]).to be_falsey
      end
    end

    context "when user is already unsubscribed from label" do
      before { label1.unsubscribe(user) }

      it "returns 304" do
        delete api("/projects/#{project.id}/labels/#{label1.id}/subscription", user)

        expect(response).to have_http_status(304)
      end
    end

    context "when label ID is not found" do
      it "returns 404 error" do
        delete api("/projects/#{project.id}/labels/1234/subscription", user)

        expect(response).to have_http_status(404)
      end
    end
  end
end
