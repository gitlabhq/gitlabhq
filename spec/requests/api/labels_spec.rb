# frozen_string_literal: true

require 'spec_helper'

RSpec.describe API::Labels, feature_category: :team_planning do
  def put_labels_api(route_type, user, spec_params, request_params = {})
    if route_type == :deprecated
      put api("/projects/#{project.id}/labels", user),
        params: request_params.merge(spec_params)
    else
      label_id = spec_params[:name] || spec_params[:label_id]

      put api("/projects/#{project.id}/labels/#{ERB::Util.url_encode(label_id)}", user),
        params: request_params.merge(spec_params.except(:name, :id))
    end
  end

  let_it_be(:valid_label_title_1) { 'Label foo & bar:subgroup::v.1' }
  let_it_be(:valid_label_title_1_esc) { ERB::Util.url_encode(valid_label_title_1) }
  let_it_be(:valid_label_title_2) { 'Label bar & foo:subgroup::v.2' }
  let_it_be(:valid_group_label_title_1) { 'Group label foobar:sub::v.1' }

  let(:user) { create(:user) }
  let(:project) { create(:project, creator_id: user.id, namespace: user.namespace) }
  let!(:label1) { create(:label, description: 'the best label v.1', title: valid_label_title_1, project: project) }
  let!(:priority_label) { create(:label, title: 'bug', project: project, priority: 3) }

  route_types = [:deprecated, :rest]

  shared_examples 'label update API' do
    route_types.each do |route_type|
      it "returns 200 if name is changed (#{route_type} route)" do
        put_labels_api(route_type, user, spec_params, new_name: valid_label_title_2)

        expect(response).to have_gitlab_http_status(:ok)
        expect(json_response['name']).to eq(valid_label_title_2)
        expect(json_response['color']).to be_color(label1.color)
      end

      it "returns 200 if colors is changed (#{route_type} route)" do
        put_labels_api(route_type, user, spec_params, color: '#FFFFFF')

        expect(response).to have_gitlab_http_status(:ok)
        expect(json_response['name']).to eq(label1.name)
        expect(json_response['color']).to be_color('#FFFFFF')
      end

      it "returns 200 if a priority is added (#{route_type} route)" do
        put_labels_api(route_type, user, spec_params, priority: 3)

        expect(response).to have_gitlab_http_status(:ok)
        expect(json_response['name']).to eq(label1.name)
        expect(json_response['priority']).to eq(3)
      end

      it "returns 400 if no new parameters given (#{route_type} route)" do
        put_labels_api(route_type, user, spec_params)

        expect(response).to have_gitlab_http_status(:bad_request)
        expect(json_response['error']).to eq('new_name, color, description, priority are missing, '\
                                             'at least one parameter must be provided')
      end

      it "returns 400 when color code is too short (#{route_type} route)" do
        put_labels_api(route_type, user, spec_params, color: '#FF')

        expect(response).to have_gitlab_http_status(:bad_request)
        expect(json_response['message']['color']).to eq(['must be a valid color code'])
      end

      it "returns 400 for too long color code (#{route_type} route)" do
        put_labels_api(route_type, user, spec_params, color: '#FFAAFFFF')

        expect(response).to have_gitlab_http_status(:bad_request)
        expect(json_response['message']['color']).to eq(['must be a valid color code'])
      end

      it "returns 400 for invalid priority (#{route_type} route)" do
        put_labels_api(route_type, user, spec_params, priority: 'foo')

        expect(response).to have_gitlab_http_status(:bad_request)
      end

      it "returns 200 if name and colors and description are changed (#{route_type} route)" do
        put_labels_api(route_type, user, spec_params, new_name: valid_label_title_2, color: '#FFFFFF', description: 'test')

        expect(response).to have_gitlab_http_status(:ok)
        expect(json_response['name']).to eq(valid_label_title_2)
        expect(json_response['color']).to be_color('#FFFFFF')
        expect(json_response['description']).to eq('test')
      end

      it "returns 400 for invalid name (#{route_type} route)" do
        put_labels_api(route_type, user, spec_params, new_name: ',', color: '#FFFFFF')

        expect(response).to have_gitlab_http_status(:bad_request)
        expect(json_response['message']['title']).to eq(['is invalid'])
      end

      it "returns 200 if description is changed (#{route_type} route)" do
        put_labels_api(route_type, user, spec_params, description: 'test')

        expect(response).to have_gitlab_http_status(:ok)
        expect(json_response['id']).to eq(expected_response_label_id)
        expect(json_response['description']).to eq('test')
      end

      it "returns 200 if priority is changed (#{route_type} route)" do
        put_labels_api(route_type, user, spec_params, priority: 10)

        expect(response).to have_gitlab_http_status(:ok)
        expect(json_response['id']).to eq(expected_response_label_id)
        expect(json_response['priority']).to eq(10)
      end
    end

    it 'returns 200 if a priority is removed (deprecated route)' do
      label = find_by_spec_params(spec_params)

      expect(label).not_to be_nil

      label.priorities.create!(project: label.project, priority: 1)
      label.save!

      request_params = {
        priority: nil
      }.merge(spec_params)

      put api("/projects/#{project.id}/labels", user),
        params: request_params

      expect(response).to have_gitlab_http_status(:ok)
      expect(json_response['id']).to eq(expected_response_label_id)
      expect(json_response['priority']).to be_nil
    end

    it 'returns 200 if a priority is removed (rest route)' do
      label = find_by_spec_params(spec_params)
      expect(label).not_to be_nil
      label_id = spec_params[:name] || spec_params[:label_id]

      label.priorities.create!(project: label.project, priority: 1)
      label.save!

      request_params = {
        priority: nil
      }.merge(spec_params.except(:name, :id))

      put api("/projects/#{project.id}/labels/#{ERB::Util.url_encode(label_id)}", user),
        params: request_params

      expect(response).to have_gitlab_http_status(:ok)
      expect(json_response['id']).to eq(expected_response_label_id)
      expect(json_response['priority']).to be_nil
    end

    def find_by_spec_params(params)
      if params.key?(:label_id)
        Label.find(params[:label_id])
      else
        Label.find_by(name: params[:name])
      end
    end
  end

  shared_examples 'label delete API' do
    it 'returns 204 for existing label (deprecated route)' do
      delete api("/projects/#{project.id}/labels", user), params: spec_params

      expect(response).to have_gitlab_http_status(:no_content)
    end

    it 'returns 204 for existing label (rest route)' do
      label_id = spec_params[:name] || spec_params[:label_id]
      delete api("/projects/#{project.id}/labels/#{ERB::Util.url_encode(label_id)}", user), params: spec_params.except(:name, :label_id)

      expect(response).to have_gitlab_http_status(:no_content)
    end
  end

  before do
    project.add_maintainer(user)
  end

  describe 'GET /projects/:id/labels' do
    let_it_be(:group) { create(:group) }
    let_it_be(:group_label) { create(:group_label, title: valid_group_label_title_1, group: group) }

    before do
      project.update!(group: group)
    end

    it 'returns all available labels to the project' do
      get api("/projects/#{project.id}/labels", user)

      expect(response).to have_gitlab_http_status(:ok)
      expect(response).to include_pagination_headers
      expect(json_response).to all(match_schema('public_api/v4/labels/project_label'))
      expect(json_response.size).to eq(3)
      expect(json_response.map { |l| l['name'] }).to match_array([group_label.name, priority_label.name, label1.name])
    end

    context 'when search param is provided' do
      context 'and user is subscribed' do
        before do
          priority_label.subscribe(user)
        end

        it 'returns subscribed true' do
          get api("/projects/#{project.id}/labels?search=#{priority_label.name}", user)

          expect(response).to have_gitlab_http_status(:ok)
          expect(json_response[0]['name']).to eq(priority_label.name)
          expect(json_response[0]['subscribed']).to be true
        end
      end

      context 'and user is not subscribed' do
        before do
          priority_label.unsubscribe(user)
        end

        it 'returns subscribed false' do
          get api("/projects/#{project.id}/labels?search=#{priority_label.name}", user)

          expect(response).to have_gitlab_http_status(:ok)
          expect(json_response[0]['name']).to eq(priority_label.name)
          expect(json_response[0]['subscribed']).to be false
        end
      end
    end

    context 'when the with_counts parameter is set' do
      before do
        create(:labeled_issue, project: project, labels: [group_label], author: user)
        create(:labeled_issue, project: project, labels: [label1], author: user, state: :closed)
        create(:labeled_merge_request, labels: [priority_label], author: user, source_project: project)
      end

      it 'includes counts in the response' do
        get api("/projects/#{project.id}/labels", user), params: { with_counts: true }

        expect(response).to have_gitlab_http_status(:ok)
        expect(response).to include_pagination_headers
        expect(json_response).to all(match_schema('public_api/v4/labels/project_label_with_counts'))
        expect(json_response.size).to eq(3)
        expect(json_response.map { |l| l['name'] }).to match_array([group_label.name, priority_label.name, label1.name])

        label1_response = json_response.find { |l| l['name'] == label1.title }
        group_label_response = json_response.find { |l| l['name'] == group_label.title }
        priority_label_response = json_response.find { |l| l['name'] == priority_label.title }

        expect(label1_response).to include(
          'open_issues_count' => 0,
          'closed_issues_count' => 1,
          'open_merge_requests_count' => 0,
          'name' => label1.name,
          'description' => label1.description,
          'color' => a_string_matching(/^#\h{6}$/),
          'text_color' => a_string_matching(/^#\h{6}$/),
          'priority' => nil,
          'subscribed' => false,
          'is_project_label' => true
        )

        expect(group_label_response).to include(
          'open_issues_count' => 1,
          'closed_issues_count' => 0,
          'open_merge_requests_count' => 0,
          'name' => group_label.name,
          'description' => nil,
          'color' => a_valid_color,
          'text_color' => a_valid_color,
          'priority' => nil,
          'subscribed' => false,
          'is_project_label' => false
        )

        expect(priority_label_response).to include(
          'open_issues_count' => 0,
          'closed_issues_count' => 0,
          'open_merge_requests_count' => 1,
          'name' => priority_label.name,
          'description' => nil,
          'color' => a_valid_color,
          'text_color' => a_valid_color,
          'priority' => 3,
          'subscribed' => false,
          'is_project_label' => true
        )
      end
    end

    context 'with subgroups' do
      let_it_be(:subgroup) { create(:group, parent: group) }
      let_it_be(:subgroup_label) { create(:group_label, title: 'support label', group: subgroup) }

      before do
        subgroup.add_owner(user)
        project.update!(group: subgroup)
      end

      context 'when the include_ancestor_groups parameter is not set' do
        let(:request) { get api("/projects/#{project.id}/labels", user) }
        let(:expected_labels) { [priority_label.name, group_label.name, subgroup_label.name, label1.name] }

        it_behaves_like 'fetches labels'

        context 'when search param is provided' do
          let(:request) { get api("/projects/#{project.id}/labels?search=lab", user) }
          let(:expected_labels) { [group_label.name, subgroup_label.name, label1.name] }

          it_behaves_like 'fetches labels'
        end
      end

      context 'when the include_ancestor_groups parameter is set to false' do
        let(:request) { get api("/projects/#{project.id}/labels", user), params: { include_ancestor_groups: false } }
        let(:expected_labels) { [subgroup_label.name, priority_label.name, label1.name] }

        it_behaves_like 'fetches labels'

        context 'when search param is provided' do
          let(:request) { get api("/projects/#{project.id}/labels?search=lab", user), params: { include_ancestor_groups: false } }
          let(:expected_labels) { [subgroup_label.name, label1.name] }

          it_behaves_like 'fetches labels'
        end
      end
    end
  end

  describe 'POST /projects/:id/labels' do
    it 'returns created label when all params' do
      post api("/projects/#{project.id}/labels", user),
        params: {
          name: valid_label_title_2,
          color: '#FFAABB',
          description: 'test',
          priority: 2
        }

      expect(response).to have_gitlab_http_status(:created)
      expect(json_response['name']).to eq(valid_label_title_2)
      expect(json_response['color']).to be_color('#FFAABB')
      expect(json_response['description']).to eq('test')
      expect(json_response['priority']).to eq(2)
    end

    it 'returns created label when only required params' do
      post api("/projects/#{project.id}/labels", user),
        params: {
          name: valid_label_title_2,
          color: '#FFAABB'
        }

      expect(response).to have_gitlab_http_status(:created)
      expect(json_response['name']).to eq(valid_label_title_2)
      expect(json_response['color']).to be_color('#FFAABB')
      expect(json_response['description']).to be_nil
      expect(json_response['priority']).to be_nil
    end

    it 'creates a prioritized label' do
      post api("/projects/#{project.id}/labels", user),
        params: {
          name: valid_label_title_2,
          color: '#FFAABB',
          priority: 3
        }

      expect(response).to have_gitlab_http_status(:created)
      expect(json_response['name']).to eq(valid_label_title_2)
      expect(json_response['color']).to be_color('#FFAABB')
      expect(json_response['description']).to be_nil
      expect(json_response['priority']).to eq(3)
    end

    it 'returns a 400 bad request if name not given' do
      post api("/projects/#{project.id}/labels", user), params: { color: '#FFAABB' }
      expect(response).to have_gitlab_http_status(:bad_request)
    end

    it 'returns a 400 bad request if color not given' do
      post api("/projects/#{project.id}/labels", user), params: { name: 'Foobar' }
      expect(response).to have_gitlab_http_status(:bad_request)
    end

    it 'returns 400 for invalid color' do
      post api("/projects/#{project.id}/labels", user),
        params: { name: valid_label_title_2, color: '#FFAA' }

      expect(response).to have_gitlab_http_status(:bad_request)
      expect(json_response['message']['color']).to eq(['must be a valid color code'])
    end

    it 'returns 400 for too long color code' do
      post api("/projects/#{project.id}/labels", user),
        params: { name: valid_label_title_2, color: '#FFAAFFFF' }

      expect(response).to have_gitlab_http_status(:bad_request)
      expect(json_response['message']['color']).to eq(['must be a valid color code'])
    end

    it 'returns 400 for invalid name' do
      post api("/projects/#{project.id}/labels", user),
        params: { name: ',', color: '#FFAABB' }

      expect(response).to have_gitlab_http_status(:bad_request)
      expect(json_response['message']['title']).to eq(['is invalid'])
    end

    it 'returns 409 if label already exists in group' do
      group = create(:group)
      group_label = create(:group_label, group: group)
      project.update!(group: group)

      post api("/projects/#{project.id}/labels", user),
        params: { name: group_label.name, color: '#FFAABB' }

      expect(response).to have_gitlab_http_status(:conflict)
      expect(json_response['message']).to eq('Label already exists')
    end

    it 'returns 400 for invalid priority' do
      post api("/projects/#{project.id}/labels", user),
        params: { name: valid_label_title_2, color: '#FFAAFFFF', priority: 'foo' }

      expect(response).to have_gitlab_http_status(:bad_request)
    end

    it 'returns 409 if label already exists in project' do
      post api("/projects/#{project.id}/labels", user),
        params: { name: valid_label_title_1, color: '#FFAABB' }

      expect(response).to have_gitlab_http_status(:conflict)
      expect(json_response['message']).to eq('Label already exists')
    end
  end

  describe 'DELETE /projects/:id/labels' do
    it_behaves_like 'label delete API' do
      let(:spec_params) { { name: valid_label_title_1 } }
    end

    it_behaves_like 'label delete API' do
      let(:spec_params) { { label_id: label1.id } }
    end

    it 'returns 404 for non existing label' do
      delete api("/projects/#{project.id}/labels", user), params: { name: 'unknown' }

      expect(response).to have_gitlab_http_status(:not_found)
      expect(json_response['message']).to eq('404 Label Not Found')
    end

    it 'returns 400 for wrong parameters' do
      delete api("/projects/#{project.id}/labels", user)

      expect(response).to have_gitlab_http_status(:bad_request)
    end

    it 'fails if label_id and name are given in params' do
      delete api("/projects/#{project.id}/labels", user),
        params: { label_id: label1.id, name: priority_label.name }

      expect(response).to have_gitlab_http_status(:bad_request)
    end

    it_behaves_like '412 response' do
      let(:request) { api("/projects/#{project.id}/labels", user) }
      let(:params) { { name: valid_label_title_1 } }
    end

    context 'when lock_on_merge' do
      let(:label_locked) { create(:label, title: 'Locked label', project: project, lock_on_merge: true) }

      it 'returns 400 because label could not be deleted' do
        delete api("/projects/#{project.id}/labels", user), params: { label_id: label_locked.id }

        expect(response).to have_gitlab_http_status(:bad_request)
        expect(json_response['message']).to eq('Label is locked and was not removed')
        expect(project.labels).to include(label_locked)
      end
    end

    context 'with group label' do
      let_it_be(:group) { create(:group) }
      let_it_be(:group_label) { create(:group_label, title: valid_group_label_title_1, group: group) }

      before do
        project.update!(group: group)
      end

      it 'returns 401 if user does not have access' do
        delete api("/projects/#{project.id}/labels/#{group_label.id}", user)

        expect(response).to have_gitlab_http_status(:forbidden)
      end

      it 'returns 204 if user has access' do
        group.add_developer(user)

        delete api("/projects/#{project.id}/labels/#{group_label.id}", user)

        expect(response).to have_gitlab_http_status(:no_content)
      end
    end
  end

  describe 'PUT /projects/:id/labels' do
    context 'when using name' do
      it_behaves_like 'label update API' do
        let(:spec_params) { { name: valid_label_title_1 } }
        let(:expected_response_label_id) { label1.id }
      end
    end

    context 'when using label_id' do
      it_behaves_like 'label update API' do
        let(:spec_params) { { label_id: label1.id } }
        let(:expected_response_label_id) { label1.id }
      end
    end

    it 'returns 404 if label does not exist' do
      put api("/projects/#{project.id}/labels", user),
        params: { name: valid_label_title_2, new_name: 'label3' }

      expect(response).to have_gitlab_http_status(:not_found)
    end

    it 'returns 404 if label by id does not exist' do
      put api("/projects/#{project.id}/labels", user),
        params: { label_id: 0, new_name: 'label3' }

      expect(response).to have_gitlab_http_status(:not_found)
    end

    it 'returns 400 if no label name and id is given' do
      put api("/projects/#{project.id}/labels", user), params: { new_name: 'label2' }

      expect(response).to have_gitlab_http_status(:bad_request)
      expect(json_response['error']).to eq('label_id, name are missing, exactly one parameter must be provided')
    end

    it 'fails if label_id and name are given in params' do
      put api("/projects/#{project.id}/labels", user),
        params: { label_id: label1.id, name: priority_label.name, new_name: 'New Label' }

      expect(response).to have_gitlab_http_status(:bad_request)
    end

    context 'with group label' do
      let_it_be(:group) { create(:group) }
      let_it_be(:group_label) { create(:group_label, title: valid_group_label_title_1, group: group) }

      before do
        project.update!(group: group)
      end

      it 'allows updating of group label priority' do
        put api("/projects/#{project.id}/labels/#{group_label.id}", user), params: { priority: 5 }

        expect(response).to have_gitlab_http_status(:ok)
        expect(json_response['priority']).to eq(5)
      end

      it 'returns 401 when updating other fields' do
        put api("/projects/#{project.id}/labels/#{group_label.id}", user), params: {
          priority: 5,
          new_name: 'new label name'
        }

        expect(response).to have_gitlab_http_status(:forbidden)
      end

      it 'returns 200 when user has access to the group label' do
        group.add_developer(user)

        put api("/projects/#{project.id}/labels/#{group_label.id}", user), params: {
          priority: 5,
          new_name: 'new label name'
        }

        expect(response).to have_gitlab_http_status(:ok)
        expect(json_response['priority']).to eq(5)
        expect(json_response['name']).to eq('new label name')
      end
    end
  end

  describe 'PUT /projects/:id/labels/promote' do
    let_it_be(:group) { create(:group) }

    before do
      group.add_owner(user)
      project.update!(group: group)
    end

    it 'returns 200 if label is promoted' do
      put api("/projects/#{project.id}/labels/promote", user), params: { name: label1.name }

      expect(response).to have_gitlab_http_status(:ok)
      expect(json_response['name']).to eq(label1.name)
      expect(json_response['color']).to be_color(label1.color.to_s)
    end

    context 'if group label already exists' do
      let!(:group_label) { create(:group_label, title: label1.name, group: group) }

      it 'returns a status of 200' do
        put api("/projects/#{project.id}/labels/promote", user), params: { name: label1.name }

        expect(response).to have_gitlab_http_status(:ok)
      end

      it 'does not change the group label count' do
        expect { put api("/projects/#{project.id}/labels/promote", user), params: { name: label1.name } }
            .not_to change(group.labels, :count)
      end

      it 'does not change the group label max (reuses the same ID)' do
        expect { put api("/projects/#{project.id}/labels/promote", user), params: { name: label1.name } }
            .not_to change(group.labels, :max)
      end

      it 'changes the project label count' do
        expect { put api("/projects/#{project.id}/labels/promote", user), params: { name: label1.name } }
            .to change(project.labels, :count).by(-1)
      end
    end

    it 'returns 403 if guest promotes label' do
      guest = create(:user)
      project.add_guest(guest)

      put api("/projects/#{project.id}/labels/promote", guest), params: { name: label1.name }

      expect(response).to have_gitlab_http_status(:forbidden)
    end

    it 'returns 403 if reporter promotes label' do
      reporter = create(:user)
      project.add_reporter(reporter)

      put api("/projects/#{project.id}/labels/promote", reporter), params: { name: label1.name }

      expect(response).to have_gitlab_http_status(:forbidden)
    end

    it 'returns 404 if label does not exist' do
      put api("/projects/#{project.id}/labels/promote", user), params: { name: 'unknown' }

      expect(response).to have_gitlab_http_status(:not_found)
    end

    it 'returns 400 if no label name given' do
      put api("/projects/#{project.id}/labels/promote", user)

      expect(response).to have_gitlab_http_status(:bad_request)
      expect(json_response['error']).to eq('name is missing')
    end

    it 'returns 400 if project does not have a group' do
      project = create(:project, creator_id: user.id, namespace: user.namespace)
      put api("/projects/#{project.id}/labels/promote", user), params: { name: label1.name }

      expect(response).to have_gitlab_http_status(:bad_request)
    end
  end

  describe "POST /projects/:id/labels/:label_id/subscribe" do
    context "when label_id is a label title" do
      it "subscribes to the label" do
        post api("/projects/#{project.id}/labels/#{valid_label_title_1_esc}/subscribe", user)

        expect(response).to have_gitlab_http_status(:created)
        expect(json_response["name"]).to eq(label1.title)
        expect(json_response["subscribed"]).to be_truthy
      end
    end

    context "when label_id is a label ID" do
      it "subscribes to the label" do
        post api("/projects/#{project.id}/labels/#{label1.id}/subscribe", user)

        expect(response).to have_gitlab_http_status(:created)
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

        expect(response).to have_gitlab_http_status(:not_modified)
      end
    end

    context "when label ID is not found" do
      it "returns 404 error" do
        post api("/projects/#{project.id}/labels/#{non_existing_record_id}/subscribe", user)

        expect(response).to have_gitlab_http_status(:not_found)
      end
    end
  end

  describe "POST /projects/:id/labels/:label_id/unsubscribe" do
    before do
      label1.subscribe(user, project)
    end

    context "when label_id is a label title" do
      it "unsubscribes from the label" do
        post api("/projects/#{project.id}/labels/#{valid_label_title_1_esc}/unsubscribe", user)

        expect(response).to have_gitlab_http_status(:created)
        expect(json_response["name"]).to eq(label1.title)
        expect(json_response["subscribed"]).to be_falsey
      end
    end

    context "when label_id is a label ID" do
      it "unsubscribes from the label" do
        post api("/projects/#{project.id}/labels/#{label1.id}/unsubscribe", user)

        expect(response).to have_gitlab_http_status(:created)
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

        expect(response).to have_gitlab_http_status(:not_modified)
      end
    end

    context "when label ID is not found" do
      it "returns 404 error" do
        post api("/projects/#{project.id}/labels/#{non_existing_record_id}/unsubscribe", user)

        expect(response).to have_gitlab_http_status(:not_found)
      end
    end
  end
end
