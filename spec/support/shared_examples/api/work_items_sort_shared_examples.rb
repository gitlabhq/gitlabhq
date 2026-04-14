# frozen_string_literal: true

RSpec.shared_examples 'returns work items in sort order' do
  it 'returns items in the correct order' do
    get api(api_request_path, user), params: { order_by: order_by, sort: sort }.merge(iids_param)

    expect(response).to have_gitlab_http_status(:ok)
    expect(json_response.pluck('id')).to eq(expected_order.map(&:id))
  end
end

RSpec.shared_examples 'work item listing sorting' do
  let_it_be_with_reload(:work_item_1) { create_namespace_work_item(namespace_record) }
  let_it_be_with_reload(:work_item_2) { create_namespace_work_item(namespace_record) }
  let_it_be_with_reload(:resource_project) do
    namespace_record.owner_entity if namespace_record.owner_entity_name == :project
  end

  let(:iids_param) { { iids: "#{work_item_1.iid},#{work_item_2.iid}" } }

  context 'with an invalid sort value' do
    it 'returns bad_request' do
      get api(api_request_path, user), params: { sort: 'not_a_valid_sort' }

      expect(response).to have_gitlab_http_status(:bad_request)
    end
  end

  describe 'keyset-compatible sorts' do
    before do
      work_item_1.update_columns(
        created_at: 2.days.ago,
        updated_at: 2.days.ago,
        title: 'B item',
        due_date: 2.days.from_now,
        relative_position: 100
      )
      work_item_2.update_columns(
        created_at: 1.day.ago,
        updated_at: 1.day.ago,
        title: 'A item',
        due_date: 1.day.from_now,
        relative_position: 200
      )
    end

    where(:order_by, :sort, :expected_order) do
      [
        ['created_at',        'asc',  lazy { [work_item_1, work_item_2] }],
        ['created_at',        'desc', lazy { [work_item_2, work_item_1] }],
        ['updated_at',        'asc',  lazy { [work_item_1, work_item_2] }],
        ['updated_at',        'desc', lazy { [work_item_2, work_item_1] }],
        ['title',             'asc',  lazy { [work_item_2, work_item_1] }],
        ['title',             'desc', lazy { [work_item_1, work_item_2] }],
        ['due_date',          'asc',  lazy { [work_item_2, work_item_1] }],
        ['due_date',          'desc', lazy { [work_item_1, work_item_2] }],
        ['relative_position', 'asc',  lazy { [work_item_1, work_item_2] }]
      ]
    end

    with_them do
      it 'returns 200 and items in the correct order' do
        get api(api_request_path, user), params: { order_by: order_by, sort: sort }.merge(iids_param)

        expect(response).to have_gitlab_http_status(:ok)
        expect(json_response.pluck('id')).to eq(expected_order.map(&:id))
      end
    end

    it 'defaults to created_at desc when no sort params are given' do
      get api(api_request_path, user), params: iids_param

      expect(response).to have_gitlab_http_status(:ok)
      expect(json_response.pick('id')).to eq(work_item_2.id)
    end

    it 'activates keyset pagination automatically for supported orderings' do
      get api(api_request_path, user), params: { order_by: 'created_at', sort: 'desc', per_page: 1 }

      expect(response).to have_gitlab_http_status(:ok)
      expect(response.headers['Link']).to include('cursor=')
    end
  end

  describe 'offset pagination fallback sorts' do
    context 'with closed_at sorts' do
      before do
        work_item_1.update_columns(closed_at: 2.days.ago)
        work_item_2.update_columns(closed_at: 1.day.ago)
      end

      where(:order_by, :sort, :expected_order) do
        [
          ['closed_at', 'asc',  lazy { [work_item_1, work_item_2] }],
          ['closed_at', 'desc', lazy { [work_item_2, work_item_1] }]
        ]
      end

      with_them do
        it_behaves_like 'returns work items in sort order'
      end
    end

    context 'with start_date sorts' do
      before do
        work_item_1.update_columns(start_date: 2.days.from_now)
        work_item_2.update_columns(start_date: 1.day.from_now)
      end

      where(:order_by, :sort, :expected_order) do
        [
          ['start_date', 'asc',  lazy { [work_item_2, work_item_1] }],
          ['start_date', 'desc', lazy { [work_item_1, work_item_2] }]
        ]
      end

      with_them do
        it_behaves_like 'returns work items in sort order'
      end
    end

    context 'with popularity sorts' do
      let_it_be(:upvote_1a) { create(:award_emoji, :upvote, awardable: work_item_1) }
      let_it_be(:upvote_1b) { create(:award_emoji, :upvote, awardable: work_item_1) }
      let_it_be(:upvote_2a) { create(:award_emoji, :upvote, awardable: work_item_2) }

      where(:order_by, :sort, :expected_order) do
        [
          ['popularity', 'asc',  lazy { [work_item_2, work_item_1] }],
          ['popularity', 'desc', lazy { [work_item_1, work_item_2] }]
        ]
      end

      with_them do
        it_behaves_like 'returns work items in sort order'
      end
    end

    context 'with milestone_due sorts' do
      let_it_be(:early_ms) do
        create_milestone_for_namespace(namespace_record).tap { |m| m.update!(due_date: 1.day.from_now) }
      end

      let_it_be(:late_ms) do
        create_milestone_for_namespace(namespace_record).tap { |m| m.update!(due_date: 2.days.from_now) }
      end

      before do
        work_item_1.update!(milestone: early_ms)
        work_item_2.update!(milestone: late_ms)
      end

      where(:order_by, :sort, :expected_order) do
        [
          ['milestone_due', 'asc',  lazy { [work_item_1, work_item_2] }],
          ['milestone_due', 'desc', lazy { [work_item_2, work_item_1] }]
        ]
      end

      with_them do
        it_behaves_like 'returns work items in sort order'
      end
    end

    context 'with priority sorts' do
      let_it_be(:early_ms) do
        create_milestone_for_namespace(namespace_record).tap { |m| m.update!(due_date: 1.day.from_now) }
      end

      let_it_be(:late_ms) do
        create_milestone_for_namespace(namespace_record).tap { |m| m.update!(due_date: 2.days.from_now) }
      end

      before do
        work_item_1.update!(milestone: early_ms)
        work_item_2.update!(milestone: late_ms)
      end

      where(:order_by, :sort, :expected_order) do
        [
          ['priority', 'asc',  lazy { [work_item_1, work_item_2] }],
          ['priority', 'desc', lazy { [work_item_2, work_item_1] }]
        ]
      end

      with_them do
        it_behaves_like 'returns work items in sort order'
      end
    end

    context 'with label_priority sorts' do
      let_it_be(:high_priority_label) { create(:label, project: resource_project, priority: 1) if resource_project }
      let_it_be(:low_priority_label) { create(:label, project: resource_project, priority: 10) if resource_project }

      before do
        skip 'label priority is project-scoped' unless resource_project

        work_item_1.labels = [high_priority_label]
        work_item_2.labels = [low_priority_label]
      end

      where(:order_by, :sort, :expected_order) do
        [
          ['label_priority', 'asc',  lazy { [work_item_1, work_item_2] }],
          ['label_priority', 'desc', lazy { [work_item_2, work_item_1] }]
        ]
      end

      with_them do
        it_behaves_like 'returns work items in sort order'
      end
    end

    context 'with severity sorts' do
      let_it_be(:severity_1) { create(:issuable_severity, issue: work_item_1, severity: :high) }
      let_it_be(:severity_2) { create(:issuable_severity, issue: work_item_2, severity: :low) }

      where(:order_by, :sort, :expected_order) do
        [
          ['severity', 'asc',  lazy { [work_item_2, work_item_1] }],
          ['severity', 'desc', lazy { [work_item_1, work_item_2] }]
        ]
      end

      with_them do
        it_behaves_like 'returns work items in sort order'
      end
    end

    context 'with escalation_status sorts' do
      let_it_be(:escalation_1) do
        create(:incident_management_issuable_escalation_status, :triggered, issue: work_item_1)
      end

      let_it_be(:escalation_2) do
        create(:incident_management_issuable_escalation_status, :resolved, issue: work_item_2)
      end

      where(:order_by, :sort, :expected_order) do
        [
          ['escalation_status', 'asc',  lazy { [work_item_1, work_item_2] }],
          ['escalation_status', 'desc', lazy { [work_item_2, work_item_1] }]
        ]
      end

      with_them do
        it_behaves_like 'returns work items in sort order'
      end
    end

    it 'falls back to offset pagination for unsupported keyset orderings' do
      get api(api_request_path, user), params: { order_by: 'severity', sort: 'desc', per_page: 1 }

      expect(response).to have_gitlab_http_status(:ok)
      expect(response.headers['Link']).not_to include('cursor=')
    end
  end
end
