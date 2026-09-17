# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::Database::Aggregation::ClickHouse::DescendantsFilter, :click_house,
  feature_category: :database do
  include_context 'with agent_platform_sessions ClickHouse aggregation engine'

  let_it_be(:group) { create(:group) }
  let_it_be(:subgroup) { create(:group, parent: group) }
  let_it_be(:other_group) { create(:group) }

  let(:engine_definition) do
    Gitlab::Database::Aggregation::ClickHouse::Engine.build do
      self.table_name = 'agent_platform_sessions'

      metrics do
        count
      end

      filters do
        descendants :group_id, :string, -> { sql('namespace_path') }
        descendants :legacy_group_id, :string, -> { sql('namespace_path') }, with_organization: false
        descendants :merged_group_id, :string, -> { sql('any(namespace_path)') }, merge_column: true
        descendants :bounded_group_id, :string, -> { sql('namespace_path') }, max_size: 1
      end
    end
  end

  let(:all_data_rows) do
    [
      session(1, path_for(group)),
      session(2, path_for(subgroup)),
      session(3, path_for(other_group)),
      # A sibling whose id starts with the group's digits, `1/20/` next to `1/2/`.
      session(4, "#{path_for(group).chomp('/')}0/")
    ]
  end

  def session(id, namespace_path)
    created_at = DateTime.parse('2025-03-01 00:00:00 UTC') + id.days

    { session_id: id, user_id: id, project_id: 1, namespace_path: namespace_path, flow_type: 'chat',
      environment: 'prod', session_year: 2025, created_event_at: created_at, started_event_at: created_at + 1.second }
  end

  def path_for(namespace, with_organization: true)
    namespace.traversal_path(with_organization: with_organization)
  end

  def request_for(identifier, values)
    Gitlab::Database::Aggregation::Request.new(
      filters: [{ identifier: identifier, values: values }],
      metrics: [{ identifier: :total_count }]
    )
  end

  it 'matches the group together with all of its descendants, but not a namespace sharing its digits' do
    expect(engine).to execute_aggregation(request_for(:group_id, [group.to_global_id.to_s])).and_return([
      { total_count: 2 }
    ])
  end

  it 'matches rows under any of the given groups' do
    request = request_for(:group_id, [subgroup.to_global_id.to_s, other_group.to_global_id.to_s])

    expect(engine).to execute_aggregation(request).and_return([{ total_count: 2 }])
  end

  it 'applies the filter as a HAVING clause for merge columns' do
    expect(engine).to execute_aggregation(request_for(:merged_group_id, [group.to_global_id.to_s])).and_return([
      { total_count: 2 }
    ])
  end

  context 'with with_organization: false' do
    let(:all_data_rows) do
      [
        session(1, path_for(group, with_organization: false)),
        session(2, path_for(subgroup, with_organization: false)),
        session(3, path_for(other_group, with_organization: false))
      ]
    end

    it 'resolves the groups to traversal paths without the organization prefix' do
      expect(engine).to execute_aggregation(request_for(:legacy_group_id, [group.to_global_id.to_s])).and_return([
        { total_count: 2 }
      ])
    end
  end

  describe 'validation' do
    let(:invalid_groups_error) { 'Values must be Global IDs of existing groups for filter `group_id`' }

    it 'rejects an empty list of values' do
      expect(engine).to execute_aggregation(request_for(:group_id, [])).with_errors([invalid_groups_error])
    end

    it 'rejects blank values' do
      expect(engine).to execute_aggregation(request_for(:group_id, [group.to_global_id.to_s, '']))
        .with_errors([invalid_groups_error])
    end

    it 'rejects values that are not Global IDs' do
      expect(engine).to execute_aggregation(request_for(:group_id, [path_for(group)]))
        .with_errors([invalid_groups_error])
    end

    it 'rejects Global IDs of other models, even when the id collides with a group' do
      expect(engine).to execute_aggregation(request_for(:group_id, ["gid://gitlab/Project/#{group.id}"]))
        .with_errors([invalid_groups_error])
    end

    it 'rejects Global IDs of groups that do not exist' do
      request = request_for(:group_id, [group.to_global_id.to_s, "gid://gitlab/Group/#{non_existing_record_id}"])

      expect(engine).to execute_aggregation(request).with_errors([invalid_groups_error])
    end

    it 'reports only the size error and skips the lookup when the request exceeds max_size' do
      expect(::Group).not_to receive(:id_in)

      request = request_for(:bounded_group_id, [group.to_global_id.to_s, other_group.to_global_id.to_s])

      expect(engine).to execute_aggregation(request).with_errors(
        ['Values maximum size of 1 exceeded for filter `bounded_group_id`']
      )
    end

    it 'rejects a resolved path without a trailing slash, since `1/2` would also match `1/20/`' do
      allow_next_found_instance_of(Group) do |found_group|
        allow(found_group).to receive(:traversal_path).and_return(path_for(group).chomp('/'))
      end

      expect(engine).to execute_aggregation(request_for(:group_id, [group.to_global_id.to_s])).with_errors(
        ['Values must be traversal paths ending with `/` for filter `group_id`']
      )
    end
  end
end
