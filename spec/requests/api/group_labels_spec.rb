# frozen_string_literal: true

require 'spec_helper'

RSpec.describe API::GroupLabels do
  let(:user) { create(:user) }
  let(:group) { create(:group) }
  let(:subgroup) { create(:group, parent: group) }
  let!(:group_member) { create(:group_member, group: group, user: user) }
  let!(:group_label1) { create(:group_label, title: 'feature', group: group) }
  let!(:group_label2) { create(:group_label, title: 'bug', group: group) }
  let!(:subgroup_label) { create(:group_label, title: 'support', group: subgroup) }

  describe 'GET :id/labels' do
    it 'returns all available labels for the group' do
      get api("/groups/#{group.id}/labels", user)

      expect(response).to have_gitlab_http_status(:ok)
      expect(response).to include_pagination_headers
      expect(json_response).to be_an Array
      expect(json_response).to all(match_schema('public_api/v4/labels/label'))
      expect(json_response.size).to eq(2)
      expect(json_response.map {|r| r['name'] }).to contain_exactly('feature', 'bug')
    end

    context 'when the with_counts parameter is set' do
      it 'includes counts in the response' do
        get api("/groups/#{group.id}/labels", user), params: { with_counts: true }

        expect(response).to have_gitlab_http_status(:ok)
        expect(response).to include_pagination_headers
        expect(json_response).to be_an Array
        expect(json_response).to all(match_schema('public_api/v4/labels/label_with_counts'))
        expect(json_response.size).to eq(2)
        expect(json_response.map { |r| r['open_issues_count'] }).to contain_exactly(0, 0)
      end
    end
  end

  describe 'GET :subgroup_id/labels' do
    context 'when the include_ancestor_groups parameter is not set' do
      it 'returns all available labels for the group and ancestor groups' do
        get api("/groups/#{subgroup.id}/labels", user)

        expect(response).to have_gitlab_http_status(:ok)
        expect(response).to include_pagination_headers
        expect(json_response).to be_an Array
        expect(json_response).to all(match_schema('public_api/v4/labels/label'))
        expect(json_response.size).to eq(3)
        expect(json_response.map {|r| r['name'] }).to contain_exactly('feature', 'bug', 'support')
      end
    end

    context 'when the include_ancestor_groups parameter is set to false' do
      it 'returns all available labels for the group but not for ancestor groups' do
        get api("/groups/#{subgroup.id}/labels", user), params: { include_ancestor_groups: false }

        expect(response).to have_gitlab_http_status(:ok)
        expect(response).to include_pagination_headers
        expect(json_response).to be_an Array
        expect(json_response).to all(match_schema('public_api/v4/labels/label'))
        expect(json_response.size).to eq(1)
        expect(json_response.map {|r| r['name'] }).to contain_exactly('support')
      end
    end
  end

  describe 'GET :id/labels/:label_id' do
    it 'returns a single label for the group' do
      get api("/groups/#{group.id}/labels/#{group_label1.name}", user)

      expect(response).to have_gitlab_http_status(:ok)
      expect(json_response['name']).to eq(group_label1.name)
      expect(json_response['color']).to eq(group_label1.color)
      expect(json_response['description']).to eq(group_label1.description)
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

      expect(response).to have_gitlab_http_status(:created)
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

      expect(response).to have_gitlab_http_status(:created)
      expect(json_response['name']).to eq('Foo & Bar')
      expect(json_response['color']).to eq('#FFAABB')
      expect(json_response['description']).to be_nil
    end

    it 'returns a 400 bad request if name not given' do
      post api("/groups/#{group.id}/labels", user), params: { color: '#FFAABB' }

      expect(response).to have_gitlab_http_status(:bad_request)
    end

    it 'returns a 400 bad request if color is not given' do
      post api("/groups/#{group.id}/labels", user), params: { name: 'Foobar' }

      expect(response).to have_gitlab_http_status(:bad_request)
    end

    it 'returns 409 if label already exists' do
      post api("/groups/#{group.id}/labels", user),
           params: {
             name: group_label1.name,
             color: '#FFAABB'
           }

      expect(response).to have_gitlab_http_status(:conflict)
      expect(json_response['message']).to eq('Label already exists')
    end
  end

  describe 'DELETE /groups/:id/labels (deprecated)' do
    it 'returns 204 for existing label' do
      delete api("/groups/#{group.id}/labels", user), params: { name: group_label1.name }

      expect(response).to have_gitlab_http_status(:no_content)
    end

    it 'returns 404 for non existing label' do
      delete api("/groups/#{group.id}/labels", user), params: { name: 'not_exists' }

      expect(response).to have_gitlab_http_status(:not_found)
      expect(json_response['message']).to eq('404 Label Not Found')
    end

    it 'returns 400 for wrong parameters' do
      delete api("/groups/#{group.id}/labels", user)

      expect(response).to have_gitlab_http_status(:bad_request)
    end

    it "does not delete parent's group labels" do
      subgroup = create(:group, parent: group)
      subgroup_label = create(:group_label, title: 'feature', group: subgroup)

      delete api("/groups/#{subgroup.id}/labels", user), params: { name: subgroup_label.name }

      expect(response).to have_gitlab_http_status(:no_content)
      expect(subgroup.labels.size).to eq(0)
      expect(group.labels).to include(group_label1)
    end

    it_behaves_like '412 response' do
      let(:request) { api("/groups/#{group.id}/labels", user) }
      let(:params) { { name: group_label1.name } }
    end
  end

  describe 'DELETE /groups/:id/labels/:label_id' do
    it 'returns 204 for existing label' do
      delete api("/groups/#{group.id}/labels/#{group_label1.name}", user)

      expect(response).to have_gitlab_http_status(:no_content)
    end

    it 'returns 404 for non existing label' do
      delete api("/groups/#{group.id}/labels/not_exists", user)

      expect(response).to have_gitlab_http_status(:not_found)
      expect(json_response['message']).to eq('404 Label Not Found')
    end

    it "does not delete parent's group labels" do
      subgroup = create(:group, parent: group)
      subgroup_label = create(:group_label, title: 'feature', group: subgroup)

      delete api("/groups/#{subgroup.id}/labels/#{subgroup_label.name}", user)

      expect(response).to have_gitlab_http_status(:no_content)
      expect(subgroup.labels.size).to eq(0)
      expect(group.labels).to include(group_label1)
    end

    it_behaves_like '412 response' do
      let(:request) { api("/groups/#{group.id}/labels/#{group_label1.name}", user) }
    end
  end

  describe 'PUT /groups/:id/labels (deprecated)' do
    it 'returns 200 if name and colors and description are changed' do
      put api("/groups/#{group.id}/labels", user),
          params: {
            name: group_label1.name,
            new_name: 'New Label',
            color: '#FFFFFF',
            description: 'test'
          }

      expect(response).to have_gitlab_http_status(:ok)
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

      expect(response).to have_gitlab_http_status(:ok)
      expect(subgroup.labels[0].name).to eq('New Label')
      expect(group_label1.name).to eq('feature')
    end

    it 'returns 404 if label does not exist' do
      put api("/groups/#{group.id}/labels", user),
          params: {
            name: 'not_exists',
            new_name: 'label3'
          }

      expect(response).to have_gitlab_http_status(:not_found)
    end

    it 'returns 400 if no label name given' do
      put api("/groups/#{group.id}/labels", user), params: { new_name: group_label1.name }

      expect(response).to have_gitlab_http_status(:bad_request)
      expect(json_response['error']).to eq('label_id, name are missing, exactly one parameter must be provided')
    end

    it 'returns 400 if no new parameters given' do
      put api("/groups/#{group.id}/labels", user), params: { name: group_label1.name }

      expect(response).to have_gitlab_http_status(:bad_request)
      expect(json_response['error']).to eq('new_name, color, description are missing, '\
                                           'at least one parameter must be provided')
    end
  end

  describe 'PUT /groups/:id/labels/:label_id' do
    it 'returns 200 if name and colors and description are changed' do
      put api("/groups/#{group.id}/labels/#{group_label1.name}", user),
          params: {
            new_name: 'New Label',
            color: '#FFFFFF',
            description: 'test'
          }

      expect(response).to have_gitlab_http_status(:ok)
      expect(json_response['name']).to eq('New Label')
      expect(json_response['color']).to eq('#FFFFFF')
      expect(json_response['description']).to eq('test')
    end

    it "does not update parent's group label" do
      subgroup = create(:group, parent: group)
      subgroup_label = create(:group_label, title: 'feature', group: subgroup)

      put api("/groups/#{subgroup.id}/labels/#{subgroup_label.name}", user),
          params: {
            new_name: 'New Label'
          }

      expect(response).to have_gitlab_http_status(:ok)
      expect(subgroup.labels[0].name).to eq('New Label')
      expect(group_label1.name).to eq('feature')
    end

    it 'returns 404 if label does not exist' do
      put api("/groups/#{group.id}/labels/not_exists", user),
          params: {
            new_name: 'label3'
          }

      expect(response).to have_gitlab_http_status(:not_found)
    end

    it 'returns 400 if no new parameters given' do
      put api("/groups/#{group.id}/labels/#{group_label1.name}", user)

      expect(response).to have_gitlab_http_status(:bad_request)
      expect(json_response['error']).to eq('new_name, color, description are missing, '\
                                           'at least one parameter must be provided')
    end
  end

  describe 'POST /groups/:id/labels/:label_id/subscribe' do
    context 'when label_id is a label title' do
      it 'subscribes to the label' do
        post api("/groups/#{group.id}/labels/#{group_label1.title}/subscribe", user)

        expect(response).to have_gitlab_http_status(:created)
        expect(json_response['name']).to eq(group_label1.title)
        expect(json_response['subscribed']).to be_truthy
      end
    end

    context 'when label_id is a label ID' do
      it 'subscribes to the label' do
        post api("/groups/#{group.id}/labels/#{group_label1.id}/subscribe", user)

        expect(response).to have_gitlab_http_status(:created)
        expect(json_response['name']).to eq(group_label1.title)
        expect(json_response['subscribed']).to be_truthy
      end
    end

    context 'when user is already subscribed to label' do
      before do
        group_label1.subscribe(user)
      end

      it 'returns 304' do
        post api("/groups/#{group.id}/labels/#{group_label1.id}/subscribe", user)

        expect(response).to have_gitlab_http_status(:not_modified)
      end
    end

    context 'when label ID is not found' do
      it 'returns 404 error' do
        post api("/groups/#{group.id}/labels/#{non_existing_record_id}/subscribe", user)

        expect(response).to have_gitlab_http_status(:not_found)
      end
    end
  end

  describe 'POST /groups/:id/labels/:label_id/unsubscribe' do
    before do
      group_label1.subscribe(user)
    end

    context 'when label_id is a label title' do
      it 'unsubscribes from the label' do
        post api("/groups/#{group.id}/labels/#{group_label1.title}/unsubscribe", user)

        expect(response).to have_gitlab_http_status(:created)
        expect(json_response['name']).to eq(group_label1.title)
        expect(json_response['subscribed']).to be_falsey
      end
    end

    context 'when label_id is a label ID' do
      it 'unsubscribes from the label' do
        post api("/groups/#{group.id}/labels/#{group_label1.id}/unsubscribe", user)

        expect(response).to have_gitlab_http_status(:created)
        expect(json_response['name']).to eq(group_label1.title)
        expect(json_response['subscribed']).to be_falsey
      end
    end

    context 'when user is already unsubscribed from label' do
      before do
        group_label1.unsubscribe(user)
      end

      it 'returns 304' do
        post api("/groups/#{group.id}/labels/#{group_label1.id}/unsubscribe", user)

        expect(response).to have_gitlab_http_status(:not_modified)
      end
    end

    context 'when label ID is not found' do
      it 'returns 404 error' do
        post api("/groups/#{group.id}/labels/#{non_existing_record_id}/unsubscribe", user)

        expect(response).to have_gitlab_http_status(:not_found)
      end
    end
  end
end
