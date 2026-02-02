# frozen_string_literal: true

DEFAULT_UNSUPPORTED_SORT_OPTIONS = %w[title_asc title_desc priority_asc priority_desc].freeze

RSpec.shared_examples 'issues or work items finder with namespace_traversal_ids filtering' do |factory,
  include_subgroups_param:, unsupported_sort_options: DEFAULT_UNSUPPORTED_SORT_OPTIONS|
  include_context '{Issues|WorkItems}Finder#execute context', factory

  let(:params) { { group_id: group.id, include_subgroups_param => true } }
  let(:scope) { 'all' }
  let(:expected_items) { [item1, item4, item5] }
  let_it_be(:group_level_item) { create(factory, :group_level, namespace: group) }

  before_all do
    group.add_developer(user)
  end

  shared_examples 'generates query with namespace_traversal_id filtering' do
    it 'generates query with namespace_traversal_id filtering' do
      result_sql = items.to_sql

      expect(result_sql).to include("namespace_traversal_ids[1] = #{group.id}")
                            .or(
                              include('"issues"."namespace_traversal_ids" >=')
                              .and(include('"issues"."namespace_traversal_ids" <'))
                            )
    end
  end

  shared_examples 'generates query without namespace_traversal_id filtering' do
    it 'generates query without namespace_traversal_id filtering' do
      result_sql = items.to_sql

      expect(result_sql).not_to include("namespace_traversal_ids[1]")
      expect(result_sql).not_to include('"issues"."namespace_traversal_ids" >=')
    end
  end

  it 'returns items from group and subgroups' do
    expect(items).to match_array(expected_items)
  end

  it 'excludes group-level items' do
    expect(items).not_to include(group_level_item)
  end

  it_behaves_like 'generates query with namespace_traversal_id filtering'

  context 'with a search param and attempt_group_search_optimizations = true' do
    let(:params) do
      { group_id: group, include_subgroups_param => true, search: "test", attempt_group_search_optimizations: true }
    end

    it 'does not use CTE for search when namespace_traversal_ids filtering is enabled' do
      expect(finder.use_cte_for_search?).to be(false)
    end
  end

  context 'when no group is specified' do
    let(:params) { { project_id: project1.id } }

    it_behaves_like 'generates query without namespace_traversal_id filtering'
  end

  context 'when feature flag is disabled' do
    before do
      stub_feature_flags(use_namespace_traversal_ids_for_work_items_finder: false)
    end

    it_behaves_like 'generates query without namespace_traversal_id filtering'
  end

  context 'when include param is false' do
    let(:params) { { group_id: group } }

    it_behaves_like 'generates query without namespace_traversal_id filtering'
  end

  context 'when user is not a member of the group' do
    let(:search_user) { user2 }

    it_behaves_like 'generates query without namespace_traversal_id filtering'
  end

  context 'when group is public but user is not a direct member' do
    let(:search_user) { user2 }

    before do
      group.update!(visibility_level: Gitlab::VisibilityLevel::PUBLIC)
    end

    it_behaves_like 'generates query without namespace_traversal_id filtering'
  end

  context 'when user has read_all_resources ability (admin)' do
    let(:search_user) { create(:admin) }

    before do
      allow(Ability).to receive(:allowed?).and_call_original
      allow(Ability).to receive(:allowed?).with(search_user, :read_all_resources).and_return(true)
    end

    it_behaves_like 'generates query with namespace_traversal_id filtering'
  end

  context 'for a sub-group' do
    let(:params) { { group_id: subgroup, include_subgroups_param => true } }

    before_all do
      subgroup.add_developer(user)
    end

    it_behaves_like 'generates query with namespace_traversal_id filtering'

    context 'with title sorting' do
      let(:params) { { group_id: subgroup, include_subgroups_param => true, sort: 'title_asc' } }

      it_behaves_like 'generates query with namespace_traversal_id filtering'
    end

    context 'with updated sorting' do
      let(:params) { { group_id: subgroup, include_subgroups_param => true, sort: 'updated_desc' } }

      it_behaves_like 'generates query with namespace_traversal_id filtering'
    end
  end

  context 'for a root group' do
    context 'with updated/created sorting' do
      %w[
        updated_asc updated_desc created_asc created_desc
        updated_at_asc updated_at_desc created_at_asc created_at_desc
      ].each do |sort_value|
        context "with sort: #{sort_value}" do
          let(:params) { { group_id: group, include_subgroups_param => true, sort: sort_value } }

          it_behaves_like 'generates query with namespace_traversal_id filtering'
        end
      end
    end

    context 'with other sorting' do
      unsupported_sort_options.each do |sort_value|
        context "with sort: #{sort_value}" do
          let(:params) { { group_id: group, include_subgroups_param => true, sort: sort_value } }

          it_behaves_like 'generates query without namespace_traversal_id filtering'
        end
      end
    end

    context 'with no sort specified' do
      let(:params) { { group_id: group, include_subgroups_param => true } }

      it_behaves_like 'generates query with namespace_traversal_id filtering'
    end

    context 'with blank sort' do
      let(:params) { { group_id: group, include_subgroups_param => true, sort: '' } }

      it_behaves_like 'generates query with namespace_traversal_id filtering'
    end
  end

  describe '#ensure_state_filter_for_index' do
    let_it_be(:closed_item) { create(factory, project: project1, state: 'closed') }

    context 'when state filter is passed' do
      let(:params) { { group_id: group.id, include_subgroups_param => true, state: 'opened' } }

      it 'returns only items matching the specified state' do
        expect(items).to include(item1, item5)
        expect(items).not_to include(closed_item)
      end
    end

    context 'when state filter is not passed' do
      let(:finder) { described_class.new(search_user, group_id: group.id, include_subgroups_param => true) }

      it 'returns items in all states' do
        expect(items).to include(item1, item5, closed_item)
      end
    end

    context 'when state filter is "all"' do
      let(:params) { { group_id: group.id, include_subgroups_param => true, state: 'all' } }

      it 'returns items in all states' do
        expect(items).to include(item1, item5, closed_item)
      end
    end
  end

  describe 'filtering by projects' do
    context 'when projects filter is passed' do
      let(:params) { { group_id: group.id, include_subgroups_param => true, projects: [project3.id], state: 'opened' } }

      it 'returns only items from the specified projects' do
        expect(items).to contain_exactly(item4)
      end

      it_behaves_like 'generates query with namespace_traversal_id filtering'
    end
  end

  context 'with search param' do
    let(:scope) { 'all' }

    before do
      group.add_developer(user)
    end

    context 'when searching with namespace_traversal_ids filtering' do
      let(:params) { { group_id: group, include_subgroups_param => true, search: "test" } }

      it 'uses ILIKE search instead of full-text search' do
        result_sql = items.to_sql

        expect(result_sql).not_to include('issue_search_data')
        expect(result_sql).not_to include('search_vector')
        expect(result_sql).to include('ILIKE')
      end
    end

    context 'when searching within a project' do
      let(:params) { { project_id: project1.id, search: "test" } }

      it 'uses full-text search' do
        result_sql = items.to_sql

        expect(result_sql).to include('issue_search_data')
        expect(result_sql).to include('search_vector')
        expect(result_sql).not_to include('ILIKE')
      end
    end
  end
end
