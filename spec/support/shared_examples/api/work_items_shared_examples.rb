# frozen_string_literal: true

RSpec.shared_context 'with API work items shared helpers' do
  def work_item_json_for(work_item)
    json_response.find { |item| item['id'] == work_item.id }
  end

  def features_json_for(work_item)
    work_item_json_for(work_item)&.fetch('features', {}) || {}
  end

  def create_namespace_work_item(namespace, **attributes)
    if namespace.respond_to?(:project) && namespace.project
      create(:work_item, { project: namespace.project }.merge(attributes))
    elsif namespace.is_a?(Group)
      create(:work_item, :group_level, { namespace: namespace }.merge(attributes))
    elsif namespace.is_a?(Project)
      create(:work_item, { project: namespace }.merge(attributes))
    else
      raise ArgumentError, "Unsupported namespace: #{namespace.inspect}"
    end
  end

  def create_label_for_namespace(namespace)
    case namespace.owner_entity_name
    when :group
      create(:group_label, group: namespace)
    when :project
      create(:label, project: namespace.owner_entity)
    else
      raise ArgumentError, "Unsupported namespace: #{namespace.inspect}"
    end
  end

  def create_milestone_for_namespace(namespace)
    case namespace.owner_entity_name
    when :group
      create(:milestone, group: namespace)
    when :project
      create(:milestone, project: namespace.owner_entity)
    else
      raise ArgumentError, "Unsupported namespace: #{namespace.inspect}"
    end
  end
end

RSpec.shared_examples 'work item pagination' do
  it_behaves_like 'an endpoint with keyset pagination', invalid_order: nil do
    let(:api_call) { api(api_request_path, user) }
    let(:first_record) { secondary_work_item }
    let(:second_record) { primary_work_item }
    let(:additional_params) { {} }
  end

  it 'rejects offset-based pagination' do
    get api(api_request_path, user), params: { pagination: 'offset' }

    expect(response).to have_gitlab_http_status(:method_not_allowed)
    expect(json_response['error']).to eq('Only keyset pagination is supported for work items endpoints.')
  end
end

RSpec.shared_examples 'work item authorization' do
  it 'returns forbidden when feature flag is disabled' do
    stub_feature_flags(work_item_rest_api: false)

    get api(api_request_path, user)

    expect(response).to have_gitlab_http_status(:forbidden)
  end
end

RSpec.shared_examples 'work item field and feature selection' do
  describe 'field selection' do
    context 'without a fields parameter' do
      before do
        get api(api_request_path, user)
      end

      it 'returns the default base fields' do
        expect(response).to have_gitlab_http_status(:ok)
        expect(json_response).to be_an(Array)
        expect(json_response.pluck('id')).to match_array(expected_work_item_ids)
        expect(json_response).to all(include('id', 'iid', 'global_id', 'title'))
      end
    end

    context 'with a fields parameter' do
      before do
        get api(api_request_path, user), params: { fields: 'iid,reference' }
      end

      it 'returns only the requested base fields' do
        expect(response).to have_gitlab_http_status(:ok)
        expect(json_response).to all(include('id', 'iid', 'global_id', 'title', 'reference'))

        expect(work_item_json_for(primary_work_item)).to include(
          'iid' => primary_work_item.iid,
          'global_id' => primary_work_item.to_gid.to_s,
          'reference' => primary_work_item.to_reference(full: true)
        )
      end
    end
  end

  describe 'feature selection' do
    context 'without a features parameter' do
      it 'returns no feature response' do
        get api(api_request_path, user)

        expect(features_json_for(primary_work_item).keys).to be_empty
      end
    end

    context 'with a features parameter' do
      it 'returns only the requested features' do
        get api(api_request_path, user), params: { fields: 'features', features: 'labels,unknown' }

        primary_features = features_json_for(primary_work_item)

        expect(primary_features.keys).to contain_exactly('labels')
        expect(primary_features).to include(
          'labels' => a_hash_including('labels' => contain_exactly(a_hash_including('title' => label.title)))
        )
      end
    end
  end
end

RSpec.shared_examples 'work item listing payload' do
  let(:start_date) { Date.current }
  let(:due_date) { start_date + 1.day }

  before do
    create(:issue_assignee, issue: primary_work_item, assignee: user)
    create(:work_items_dates_source, :fixed, work_item: primary_work_item, start_date: start_date, due_date: due_date)
    primary_work_item.update_columns(last_edited_by_id: editor.id, last_edited_at: 2.days.ago)
  end

  it 'returns the full payload when requesting all fields and features' do
    get api(api_request_path, user), params: { fields: all_fields_param, features: all_features_param }

    work_item_response = work_item_json_for(primary_work_item)

    expect(work_item_response).to include(
      'id' => primary_work_item.id,
      'iid' => primary_work_item.iid,
      'global_id' => primary_work_item.to_gid.to_s,
      'title' => primary_work_item.title,
      'title_html' => primary_work_item.title_html,
      'state' => primary_work_item.state,
      'confidential' => primary_work_item.confidential?,
      'imported' => primary_work_item.imported?,
      'lock_version' => primary_work_item.lock_version,
      'hidden' => primary_work_item.hidden?,
      'create_note_email' => nil,
      'duplicated_to_work_item_url' => nil,
      'moved_to_work_item_url' => nil,
      'user_permissions' => a_hash_including('create_note' => true, 'read_work_item' => true),
      'author' => a_hash_including('id' => primary_work_item.author_id,
        'username' => primary_work_item.author.username, 'name' => primary_work_item.author.name
      ),
      'work_item_type' => a_hash_including(
        'name' => primary_work_item.work_item_type.name,
        'icon_name' => primary_work_item.work_item_type.icon_name)
    )

    expect(features_json_for(primary_work_item)).to include(
      'assignees' => contain_exactly(a_hash_including('id' => user.id)),
      'labels' => a_hash_including('labels' => contain_exactly(a_hash_including('title' => label.title))),
      'milestone' => a_hash_including('title' => milestone.title),
      'start_and_due_date' => a_hash_including('start_date' => start_date.to_s, 'due_date' => due_date.to_s),
      'description' => a_hash_including(
        'description' => primary_work_item.description,
        'description_html' => primary_work_item.description_html,
        'edited' => true,
        'last_edited_at' => be_present,
        'last_edited_by' => a_hash_including('id' => editor.id),
        'task_completion_status' => a_hash_including('count' => 0, 'completed_count' => 0)
      )
    )
  end
end

RSpec.shared_examples 'avoids N+1 queries' do
  before do
    create(:issue_assignee, issue: primary_work_item, assignee: user)
    create(:discussion_note_on_work_item, noteable: primary_work_item, project: project)
    create(:work_items_dates_source, :fixed, work_item: primary_work_item)

    primary_work_item.update_columns(last_edited_by_id: editor.id, last_edited_at: 2.days.ago)
  end

  it 'avoids N+1 queries when requesting feature-only and full payload responses' do
    # Warmup
    get api(api_request_path, user), params: { fields: all_fields_param, features: all_features_param }

    baseline = ActiveRecord::QueryRecorder.new(skip_cached: false) do
      get api(api_request_path, user), params: { fields: all_fields_param, features: all_features_param }
    end

    extra_work_item = create_namespace_work_item(
      namespace_record, labels: [label], milestone: milestone, author: user
    )

    create(:issue_assignee, issue: extra_work_item, assignee: user)
    create(:discussion_note_on_work_item, noteable: extra_work_item, project: project)
    create(:work_items_dates_source, :fixed, work_item: extra_work_item)
    extra_work_item.update_columns(last_edited_by_id: editor.id, last_edited_at: 1.day.ago)

    expect do
      get api(api_request_path, user), params: { fields: all_fields_param, features: all_features_param }
    end.to issue_same_number_of_queries_as(baseline).with_threshold(1)

    expect(response).to have_gitlab_http_status(:ok)
    expect(json_response.size).to eq(expected_work_item_ids.size + 1)
  end
end

RSpec.shared_examples 'work item N+1 query prevention' do
  let(:request_params) { { fields: 'reference,web_url', features: 'labels,milestone' } }

  before do
    2.times do
      work_item_label = create_label_for_namespace(namespace_record)
      ms = create_milestone_for_namespace(namespace_record)
      create_namespace_work_item(namespace_record, labels: [work_item_label], milestone: ms)
    end

    get api(api_request_path, user), params: request_params
  end

  it 'does not cause excessive N+1 queries when adding work items with labels, milestones, and URL fields' do
    baseline = ActiveRecord::QueryRecorder.new(skip_cached: false) do
      get api(api_request_path, user), params: request_params
    end

    2.times do
      new_label = create_label_for_namespace(namespace_record)
      new_milestone = create_milestone_for_namespace(namespace_record)
      create_namespace_work_item(namespace_record, labels: [new_label], milestone: new_milestone)
    end

    expect do
      get api(api_request_path, user), params: request_params
    end.to issue_same_number_of_queries_as(baseline).with_threshold(1)

    expect(response).to have_gitlab_http_status(:ok)
    expect(json_response.first).to include('reference', 'web_url')

    work_item_with_milestone = json_response.find { |wi| wi.dig('features', 'milestone') }
    expect(work_item_with_milestone.dig('features', 'milestone', 'web_url')).to be_present

    work_item_with_labels = json_response.find { |wi| wi.dig('features', 'labels') }
    expect(work_item_with_labels.dig('features', 'labels')).to have_key('allows_scoped_labels')
  end
end

RSpec.shared_examples 'work item listing endpoint' do
  let(:api_request_path) { "/namespaces/#{CGI.escape(namespace_record.full_path)}/-/work_items" }

  let(:all_fields_param) { ::API::WorkItems::ALL_FIELDS.join(',') }
  let(:all_features_param) { ::API::WorkItems::FEATURE_SUPPORTED_VALUES.join(',') }
  let(:expected_work_item_ids) { [primary_work_item.id, secondary_work_item.id].uniq }

  it_behaves_like 'work item pagination'
  it_behaves_like 'work item authorization'
  it_behaves_like 'work item field and feature selection'
  it_behaves_like 'avoids N+1 queries'
  it_behaves_like 'work item listing payload'
end
