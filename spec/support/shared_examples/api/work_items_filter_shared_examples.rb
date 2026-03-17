# frozen_string_literal: true

RSpec.shared_examples 'work item listing filters' do
  let_it_be(:task_type) { WorkItems::Type.default_by_type(:task) }
  let_it_be_with_reload(:work_item_1) { create_namespace_work_item(namespace_record) }
  let_it_be_with_reload(:work_item_2) { create_namespace_work_item(namespace_record) }
  let_it_be(:namespace_label) { create_label_for_namespace(namespace_record) }
  let_it_be(:namespace_milestone) { create_milestone_for_namespace(namespace_record) }
  let_it_be_with_reload(:resource_project) do
    namespace_record.owner_entity if namespace_record.owner_entity_name == :project
  end

  shared_examples 'contains only matching work items' do
    it 'contains correct work items' do
      get api(api_request_path, user), params: params

      expect(response).to have_gitlab_http_status(:ok)
      expect(json_response.pluck('id')).to match_array(Array.wrap(matching).map(&:id))
    end
  end

  shared_examples 'does not contain matching work items' do
    it 'contains not a given work item' do
      get api(api_request_path, user), params: params

      expect(response).to have_gitlab_http_status(:ok)
      expect(json_response.pluck('id')).not_to include(Array.wrap(matching).map(&:id))
    end
  end

  describe 'filter parameters' do
    let(:matching) { work_item_1 }
    let(:params) { {} }

    context 'with state filter' do
      let(:params) { { state: 'closed' } }

      before do
        work_item_1.update!(state: 'closed')
      end

      it_behaves_like 'contains only matching work items'
    end

    context 'with ids filter' do
      let(:matching) { [work_item_1, work_item_2] }
      let(:params) { { ids: "#{work_item_1.id},#{work_item_2.id}" } }

      it_behaves_like 'contains only matching work items'
    end

    context 'with iids filter' do
      let(:params) { { iids: work_item_1.iid.to_s } }

      it_behaves_like 'contains only matching work items'
    end

    context 'with types filter' do
      let(:params) { { types: 'task' } }

      before do
        work_item_1.update!(work_item_type: task_type)
      end

      it_behaves_like 'contains only matching work items'
    end

    context 'with author_username filter' do
      let(:params) { { author_username: user.username } }

      before do
        work_item_1.update!(author: user)
        work_item_2.update!(author: editor)
      end

      it_behaves_like 'contains only matching work items'
    end

    context 'with assignee_usernames filter' do
      let(:params) { { assignee_usernames: user.username } }

      before do
        work_item_1.update!(assignees: [user])
      end

      it_behaves_like 'contains only matching work items'
    end

    context 'with assignee_wildcard filter' do
      let(:params) { { assignee_wildcard_id: 'None' } }

      before do
        work_item_1.update!(assignees: [user])
      end

      it_behaves_like 'does not contain matching work items'
    end

    context 'with label_name filter' do
      let(:params) { { label_name: namespace_label.title } }

      before do
        work_item_1.labels = [namespace_label]
      end

      it_behaves_like 'contains only matching work items'
    end

    context 'with milestone_title filter' do
      let(:params) { { milestone_title: namespace_milestone.title } }

      before do
        work_item_1.update!(milestone: namespace_milestone)
      end

      it_behaves_like 'contains only matching work items'
    end

    context 'with milestone_wildcard filter' do
      let(:params) { { milestone_wildcard_id: 'None' } }

      before do
        work_item_1.update!(milestone: nil)
        work_item_2.update!(milestone: namespace_milestone)
      end

      it_behaves_like 'does not contain matching work items'
    end

    context 'with release_tag filter' do
      let(:release_milestone) { create_milestone_for_namespace(namespace_record) }
      let(:release_tag) { 'v1.0.0' }
      let(:params) { { release_tag: release_tag } }

      before do
        skip 'Release filters are only supported for project namespaces' unless resource_project

        create(:release, project: resource_project, tag: release_tag, milestones: [release_milestone])
        work_item_1.update!(milestone: release_milestone)
      end

      it_behaves_like 'contains only matching work items'
    end

    context 'with release_tag_wildcard_id filter' do
      let(:release_milestone) { create_milestone_for_namespace(namespace_record) }
      let(:release_tag) { 'v2.0.0' }
      let(:params) { { release_tag_wildcard_id: 'None' } }

      before do
        skip 'Release filters are only supported for project namespaces' unless resource_project

        create(:release, project: resource_project, tag: release_tag, milestones: [release_milestone])

        resource_project.work_items.where.not(id: work_item_1.id).find_each do |item|
          item.update!(milestone: release_milestone)
        end

        work_item_1.update!(milestone: nil)
      end

      it_behaves_like 'contains only matching work items'
    end

    context 'with crm_contact_id filter' do
      let(:crm_group) { resource_project&.group }
      let(:crm_contact) { create(:contact, group: crm_group) }
      let(:other_contact) { create(:contact, group: crm_group) }
      let(:params) { { crm_contact_id: crm_contact.id.to_s } }

      before do
        skip 'CRM filters require a project belonging to a group' unless crm_group

        create(:issue_customer_relations_contact, issue: work_item_1, contact: crm_contact)
        create(:issue_customer_relations_contact, issue: work_item_2, contact: other_contact)
      end

      it_behaves_like 'contains only matching work items'
    end

    context 'with crm_organization_id filter' do
      let(:crm_group) { resource_project&.group }
      let(:crm_organization) { create(:crm_organization, group: crm_group) }
      let(:organization_contact) do
        create(:contact, group: crm_group, organization: crm_organization)
      end

      let(:other_contact) { create(:contact, group: crm_group) }
      let(:params) { { crm_organization_id: crm_organization.id.to_s } }

      before do
        skip 'CRM filters require a project belonging to a group' unless crm_group

        create(:issue_customer_relations_contact, issue: work_item_1, contact: organization_contact)
        create(:issue_customer_relations_contact, issue: work_item_2, contact: other_contact)
      end

      it_behaves_like 'contains only matching work items'
    end

    context 'with confidential filter' do
      let(:params) { { confidential: true } }

      before do
        work_item_1.update!(confidential: true)
      end

      it_behaves_like 'contains only matching work items'
    end

    context 'with subscribed filter' do
      let(:params) { { subscribed: 'EXPLICITLY_SUBSCRIBED' } }

      before do
        work_item_1.subscribe(user)
      end

      it_behaves_like 'contains only matching work items'
    end

    context 'with closed date filters' do
      let(:matching_time) { Time.zone.parse('2020-02-01T10:00:00Z') }
      let(:params) do
        {
          closed_after: (matching_time - 1.hour).iso8601,
          closed_before: (matching_time + 1.hour).iso8601
        }
      end

      before do
        work_item_1.update!(state: 'closed', closed_at: matching_time)
        work_item_2.update!(state: 'closed', closed_at: matching_time - 2.days)
      end

      it_behaves_like 'contains only matching work items'
    end

    context 'with due date filters' do
      let(:matching_time) { Time.zone.parse('2020-03-01T00:00:00Z') }
      let(:params) do
        {
          due_after: (matching_time - 1.day).iso8601,
          due_before: (matching_time + 1.day).iso8601
        }
      end

      before do
        work_item_1.update!(due_date: matching_time.to_date)
        work_item_2.update!(due_date: matching_time.to_date + 5.days)
      end

      it_behaves_like 'contains only matching work items'
    end

    context 'with creation and update date filters' do
      let(:matching_time) { Time.zone.parse('2020-01-01T00:00:00Z') }
      let(:params) do
        {
          created_after: (matching_time - 1.day).iso8601,
          created_before: (matching_time + 1.day).iso8601,
          updated_after: matching_time.iso8601,
          updated_before: (matching_time + 2.hours).iso8601
        }
      end

      before do
        work_item_1.update_columns(created_at: matching_time, updated_at: matching_time + 1.hour)
        work_item_2.update_columns(created_at: matching_time - 1.year, updated_at: matching_time - 1.year)
      end

      it_behaves_like 'contains only matching work items'
    end

    context 'with my_reaction_emoji filter' do
      let(:params) { { my_reaction_emoji: 'thumbsup' } }

      before do
        create(:award_emoji, awardable: work_item_1, user: user, name: 'thumbsup')
      end

      it_behaves_like 'contains only matching work items'
    end

    context 'with parent_ids filter' do
      let(:params) { { parent_ids: work_item_2.id.to_s } }

      before do
        work_item_1.update!(work_item_type: task_type)
        create(:parent_link, work_item_parent: work_item_2, work_item: work_item_1)
      end

      it_behaves_like 'contains only matching work items'
    end

    context 'with parent_wildcard filter' do
      let(:params) { { parent_wildcard_id: 'None' } }

      before do
        work_item_1.update!(work_item_type: task_type)
        create(:parent_link, work_item_parent: work_item_2, work_item: work_item_1)
      end

      it_behaves_like 'does not contain matching work items'
    end

    context 'with include_descendant_work_items filter' do
      let_it_be_with_reload(:ancestor_work_item) { create_namespace_work_item(namespace_record) }
      let(:params) do
        {
          parent_ids: ancestor_work_item.id.to_s,
          include_descendant_work_items: true
        }
      end

      before do
        work_item_1.update!(work_item_type: task_type)
        create(:parent_link, work_item_parent: ancestor_work_item, work_item: work_item_1)
      end

      it_behaves_like 'contains only matching work items'
    end

    context 'with negated filters' do
      let(:params) do
        {
          not: {
            author_username: user.username,
            label_name: namespace_label.title
          }
        }
      end

      before do
        work_item_1.update!(author: user)
        work_item_1.labels = [namespace_label]
      end

      it_behaves_like 'does not contain matching work items'
    end

    context 'with OR filters' do
      let(:params) do
        {
          or: {
            author_usernames: [user.username, editor.username],
            label_names: [namespace_label.title]
          }
        }
      end

      before do
        work_item_1.update!(author: user)
        work_item_2.update!(author: editor)

        work_item_1.labels = [namespace_label]
      end

      it_behaves_like 'contains only matching work items'
    end

    context 'when mutually exclusive params are passed' do
      where(:params) do
        [
          [lazy { { assignee_usernames: 'user1', assignee_wildcard_id: 'None' } }],
          [lazy { { milestone_title: 'v1.0', milestone_wildcard_id: 'None' } }],
          [lazy { { release_tag: 'v1.0', release_tag_wildcard_id: 'None' } }],
          [lazy { { parent_ids: '1', parent_wildcard_id: 'None' } }],
          [lazy { { not: { milestone_title: 'v1.0', milestone_wildcard_id: 'Started' } } }]
        ]
      end

      with_them do
        it 'returns a bad request error', :aggregate_failures do
          get api(api_request_path, user), params: params

          expect(response).to have_gitlab_http_status(:bad_request)
          expect(json_response['error']).to include('mutually exclusive')
        end
      end
    end

    context 'with multiple combined filters' do
      let(:params) do
        {
          state: 'opened',
          author_username: user.username,
          label_name: namespace_label.title,
          confidential: false
        }
      end

      before do
        work_item_1.update!(state: 'opened', author: user, confidential: false)
        work_item_2.update!(state: 'opened', author: editor, confidential: true)

        work_item_1.labels = [namespace_label]
      end

      it_behaves_like 'contains only matching work items'
    end
  end
end
