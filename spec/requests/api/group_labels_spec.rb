# frozen_string_literal: true

require 'spec_helper'

describe API::GroupLabels do
  let(:user) { create(:user) }
  let(:group) { create(:group) }
  let!(:group_member) { create(:group_member, group: group, user: user) }
  let!(:label1) { create(:group_label, title: 'feature', group: group) }
  let!(:label2) { create(:group_label, title: 'bug', group: group) }

  describe 'GET :id/labels' do
    it 'returns all available labels for the group' do
      get api("/groups/#{group.id}/labels", user)

      expect(response).to have_gitlab_http_status(200)
      expect(response).to match_response_schema('public_api/v4/group_labels')
      expect(response).to include_pagination_headers
      expect(json_response).to be_an Array
      expect(json_response.size).to eq(2)
      expect(json_response.map {|r| r['name'] }).to contain_exactly('feature', 'bug')
    end
  end

  describe 'POST /groups/:id/labels' do
    it 'returns created label when all params are given' do
      post api("/groups/#{group.id}/labels", user),
           params: {
             name: 'Foo',
             color: '#FFAABB',
             description: 'test'
           }

      expect(response).to have_gitlab_http_status(201)
      expect(json_response['name']).to eq('Foo')
      expect(json_response['color']).to eq('#FFAABB')
      expect(json_response['description']).to eq('test')
    end

    it 'returns created label when only required params are given' do
      post api("/groups/#{group.id}/labels", user),
           params: {
             name: 'Foo & Bar',
             color: '#FFAABB'
           }

      expect(response.status).to eq(201)
      expect(json_response['name']).to eq('Foo & Bar')
      expect(json_response['color']).to eq('#FFAABB')
      expect(json_response['description']).to be_nil
    end

    it 'returns a 400 bad request if name not given' do
      post api("/groups/#{group.id}/labels", user), params: { color: '#FFAABB' }

      expect(response).to have_gitlab_http_status(400)
    end

    it 'returns a 400 bad request if color is not given' do
      post api("/groups/#{group.id}/labels", user), params: { name: 'Foobar' }

      expect(response).to have_gitlab_http_status(400)
    end

    it 'returns 409 if label already exists' do
      post api("/groups/#{group.id}/labels", user),
           params: {
             name: label1.name,
             color: '#FFAABB'
           }

      expect(response).to have_gitlab_http_status(409)
      expect(json_response['message']).to eq('Label already exists')
    end
  end

  describe 'DELETE /groups/:id/labels' do
    it 'returns 204 for existing label' do
      delete api("/groups/#{group.id}/labels", user), params: { name: label1.name }

      expect(response).to have_gitlab_http_status(204)
    end

    it 'returns 404 for non existing label' do
      delete api("/groups/#{group.id}/labels", user), params: { name: 'label2' }

      expect(response).to have_gitlab_http_status(404)
      expect(json_response['message']).to eq('404 Label Not Found')
    end

    it 'returns 400 for wrong parameters' do
      delete api("/groups/#{group.id}/labels", user)

      expect(response).to have_gitlab_http_status(400)
    end

    it "does not delete parent's group labels" do
      subgroup = create(:group, parent: group)
      subgroup_label = create(:group_label, title: 'feature', group: subgroup)

      delete api("/groups/#{subgroup.id}/labels", user), params: { name: subgroup_label.name }

      expect(response).to have_gitlab_http_status(204)
      expect(subgroup.labels.size).to eq(0)
      expect(group.labels).to include(label1)
    end

    it_behaves_like '412 response' do
      let(:request) { api("/groups/#{group.id}/labels", user) }
      let(:params) { { name: label1.name } }
    end
  end

  describe 'PUT /groups/:id/labels' do
    it 'returns 200 if name and colors and description are changed' do
      put api("/groups/#{group.id}/labels", user),
          params: {
            name: label1.name,
            new_name: 'New Label',
            color: '#FFFFFF',
            description: 'test'
          }

      expect(response).to have_gitlab_http_status(200)
      expect(json_response['name']).to eq('New Label')
      expect(json_response['color']).to eq('#FFFFFF')
      expect(json_response['description']).to eq('test')
    end

    it "does not update parent's group label" do
      subgroup = create(:group, parent: group)
      subgroup_label = create(:group_label, title: 'feature', group: subgroup)

      put api("/groups/#{subgroup.id}/labels", user),
          params: {
            name: subgroup_label.name,
            new_name: 'New Label'
          }

      expect(response).to have_gitlab_http_status(200)
      expect(subgroup.labels[0].name).to eq('New Label')
      expect(label1.name).to eq('feature')
    end

    it 'returns 404 if label does not exist' do
      put api("/groups/#{group.id}/labels", user),
          params: {
            name: 'label2',
            new_name: 'label3'
          }

      expect(response).to have_gitlab_http_status(404)
    end

    it 'returns 400 if no label name given' do
      put api("/groups/#{group.id}/labels", user), params: { new_name: label1.name }

      expect(response).to have_gitlab_http_status(400)
      expect(json_response['error']).to eq('name is missing')
    end

    it 'returns 400 if no new parameters given' do
      put api("/groups/#{group.id}/labels", user), params: { name: label1.name }

      expect(response).to have_gitlab_http_status(400)
      expect(json_response['error']).to eq('new_name, color, description are missing, '\
                                           'at least one parameter must be provided')
    end
  end

  describe 'POST /groups/:id/labels/:label_id/subscribe' do
    context 'when label_id is a label title' do
      it 'subscribes to the label' do
        post api("/groups/#{group.id}/labels/#{label1.title}/subscribe", user)

        expect(response).to have_gitlab_http_status(201)
        expect(json_response['name']).to eq(label1.title)
        expect(json_response['subscribed']).to be_truthy
      end
    end

    context 'when label_id is a label ID' do
      it 'subscribes to the label' do
        post api("/groups/#{group.id}/labels/#{label1.id}/subscribe", user)

        expect(response).to have_gitlab_http_status(201)
        expect(json_response['name']).to eq(label1.title)
        expect(json_response['subscribed']).to be_truthy
      end
    end

    context 'when user is already subscribed to label' do
      before do
        label1.subscribe(user)
      end

      it 'returns 304' do
        post api("/groups/#{group.id}/labels/#{label1.id}/subscribe", user)

        expect(response).to have_gitlab_http_status(304)
      end
    end

    context 'when label ID is not found' do
      it 'returns 404 error' do
        post api("/groups/#{group.id}/labels/1234/subscribe", user)

        expect(response).to have_gitlab_http_status(404)
      end
    end
  end

  describe 'POST /groups/:id/labels/:label_id/unsubscribe' do
    before do
      label1.subscribe(user)
    end

    context 'when label_id is a label title' do
      it 'unsubscribes from the label' do
        post api("/groups/#{group.id}/labels/#{label1.title}/unsubscribe", user)

        expect(response).to have_gitlab_http_status(201)
        expect(json_response['name']).to eq(label1.title)
        expect(json_response['subscribed']).to be_falsey
      end
    end

    context 'when label_id is a label ID' do
      it 'unsubscribes from the label' do
        post api("/groups/#{group.id}/labels/#{label1.id}/unsubscribe", user)

        expect(response).to have_gitlab_http_status(201)
        expect(json_response['name']).to eq(label1.title)
        expect(json_response['subscribed']).to be_falsey
      end
    end

    context 'when user is already unsubscribed from label' do
      before do
        label1.unsubscribe(user)
      end

      it 'returns 304' do
        post api("/groups/#{group.id}/labels/#{label1.id}/unsubscribe", user)

        expect(response).to have_gitlab_http_status(304)
      end
    end

    context 'when label ID is not found' do
      it 'returns 404 error' do
        post api("/groups/#{group.id}/labels/1234/unsubscribe", user)

        expect(response).to have_gitlab_http_status(404)
      end
    end
  end
end
