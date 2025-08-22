# frozen_string_literal: true

RSpec.shared_examples 'getting a collection of projects' do
  using RSpec::Parameterized::TableSyntax

  include GraphqlHelpers

  let_it_be(:current_user) { create(:user) }
  let_it_be(:group) { create(:group, name: 'public-group', developers: current_user) }
  let_it_be(:aimed_for_deletion_project) { create(:project, :public, :aimed_for_deletion, group: group) }
  let_it_be(:projects) do
    (
      create_list(:project, 5, :public, group: group) << aimed_for_deletion_project
    ).each do |project|
      create(:ci_pipeline, project: project)
    end
  end

  let_it_be(:other_project) { create(:project, :public, group: group) }
  let_it_be(:archived_project) { create(:project, :archived, group: group) }

  let(:filters) { {} }

  let(:project_fields) { all_graphql_fields_for('Project', max_depth: 1, excluded: ['productAnalyticsState']) }

  let(:selection) do
    "nodes {
      #{project_fields}
      pipeline {
        detailedStatus {
          label
        }
      }
    }"
  end

  let(:field) { :projects }
  let(:query) do
    graphql_query_for(field, filters, selection)
  end

  let(:path) { [field.to_s.camelize(:lower).to_sym, :nodes] }

  context 'when archived argument is ONLY' do
    let(:filters) { { archived: :ONLY } }

    it 'returns only archived projects' do
      post_graphql(query, current_user: current_user)

      expect(graphql_data_at(field, :nodes))
        .to contain_exactly(a_graphql_entity_for(archived_project))
    end
  end

  context 'when archived argument is INCLUDE' do
    let(:filters) { { archived: :INCLUDE } }

    it 'returns archived and non-archived projects' do
      post_graphql(query, current_user: current_user)

      expect(graphql_data_at(field, :nodes))
      .to contain_exactly(
        *projects.map { |project| a_graphql_entity_for(project) },
        a_graphql_entity_for(other_project),
        a_graphql_entity_for(archived_project)
      )
    end
  end

  context 'when archived argument is EXCLUDE' do
    let(:filters) { { archived: :EXCLUDE } }

    it 'returns only non-archived projects' do
      post_graphql(query, current_user: current_user)

      expect(graphql_data_at(field, :nodes))
      .to contain_exactly(
        *projects.map { |project| a_graphql_entity_for(project) },
        a_graphql_entity_for(other_project)
      )
    end
  end

  describe 'min_access_level' do
    let_it_be(:project_with_owner_access) { create(:project, :private) }

    before_all do
      project_with_owner_access.add_owner(current_user)
    end

    context 'when min_access_level is OWNER' do
      let(:filters) { { min_access_level: :OWNER } }

      it 'returns only projects user has owner access to' do
        post_graphql(query, current_user: current_user)

        expect(graphql_data_at(field, :nodes))
          .to contain_exactly(a_graphql_entity_for(project_with_owner_access))
      end
    end

    context 'when min_access_level is DEVELOPER' do
      let(:filters) { { min_access_level: :DEVELOPER } }

      it 'returns only projects user has developer or higher access to' do
        post_graphql(query, current_user: current_user)

        expect(graphql_data_at(field, :nodes))
        .to contain_exactly(
          *projects.map { |project| a_graphql_entity_for(project) },
          a_graphql_entity_for(other_project),
          a_graphql_entity_for(project_with_owner_access),
          a_graphql_entity_for(archived_project)
        )
      end
    end
  end

  context 'when providing full_paths filter' do
    let(:project_full_paths) { projects.map(&:full_path) }
    let(:filters) { { full_paths: project_full_paths } }

    let(:single_project_query) do
      graphql_query_for(field, { full_paths: [project_full_paths.first] }, selection)
    end

    it_behaves_like 'a working graphql query that returns data' do
      before do
        post_graphql(query, current_user: current_user)
      end
    end

    it 'avoids N+1 queries', :use_sql_query_cache, :clean_gitlab_redis_cache do
      post_graphql(single_project_query, current_user: current_user)

      control = ActiveRecord::QueryRecorder.new(skip_cached: false, query_recorder_debug: true) do
        post_graphql(single_project_query, current_user: current_user)
      end

      # There is an N+1 query for duo_features_enabled cascading setting - https://gitlab.com/gitlab-org/gitlab/-/issues/442164
      # There is an N+1 query related to marked_for_deletion - https://gitlab.com/gitlab-org/gitlab/-/issues/548924
      expect do
        post_graphql(query, current_user: current_user)
      end.not_to exceed_all_query_limit(control).with_threshold(9)
    end

    it 'returns the expected projects' do
      post_graphql(query, current_user: current_user)
      returned_full_paths = graphql_data_at(field, :nodes).pluck('fullPath')

      expect(returned_full_paths).to match_array(project_full_paths)
    end

    context 'when users provides more than 50 full_paths' do
      let(:filters) { { full_paths: Array.new(51) { other_project.full_path } } }

      it 'returns an error' do
        post_graphql(query, current_user: current_user)

        expect(graphql_errors).to contain_exactly(
          hash_including('message' => _('You cannot provide more than 50 full_paths'))
        )
      end
    end
  end

  context 'when providing the programming_language_name argument' do
    let_it_be(:project) { projects.first }
    let_it_be(:ruby) { create(:programming_language, name: 'Ruby') }
    let_it_be(:repository_language) do
      create(:repository_language, project: project, programming_language: ruby, share: 1)
    end

    let(:filters) { { programming_language_name: 'ruby' } }

    it 'returns the expected projects' do
      post_graphql(query, current_user: current_user)

      expect(graphql_data_at(field, :nodes))
        .to contain_exactly(a_graphql_entity_for(project))
    end
  end

  context 'when providing the trending argument' do
    let_it_be(:trending_project1) { create(:project, :public, group: group) }
    let_it_be(:trending_project2) { create(:project, :public, group: group) }
    let_it_be(:test_project) { create(:project, :public, group: group) }

    let(:filters) { { trending: true } }

    before do
      create(:trending_project, project: trending_project1)
      create(:trending_project, project: trending_project2)

      post_graphql(query, current_user: current_user)
    end

    it 'returns only trending projects' do
      expect(graphql_data_at(field, :nodes))
        .to contain_exactly(
          a_graphql_entity_for(trending_project1),
          a_graphql_entity_for(trending_project2)
        )
    end

    it 'excludes non-trending projects' do
      expect(graphql_data_at(field, :nodes)).not_to include(
        a_graphql_entity_for(archived_project),
        a_graphql_entity_for(test_project),
        a_graphql_entity_for(other_project)
      )
    end
  end

  context 'when providing the not_aimed_for_deletion argument' do
    let(:filters) { { not_aimed_for_deletion: true, archived: :INCLUDE } }

    before do
      post_graphql(query, current_user: current_user)
    end

    it 'returns only projects not aimed for deletion' do
      expect(graphql_data_at(field, :nodes))
        .to contain_exactly(
          *(projects - [aimed_for_deletion_project]).map { |project| a_graphql_entity_for(project) },
          a_graphql_entity_for(other_project),
          a_graphql_entity_for(archived_project)
        )
    end

    it 'excludes projects marked for deletion' do
      expect(graphql_data_at(field, :nodes)).not_to include(
        a_graphql_entity_for(aimed_for_deletion_project)
      )
    end
  end

  context 'when providing marked_for_deletion_on filter', :freeze_time do
    let_it_be(:marked_for_deletion_on) { Date.yesterday }
    let_it_be(:project_marked_for_deletion) do
      create(:project, marked_for_deletion_at: marked_for_deletion_on, developers: current_user)
    end

    let_it_be(:second_project_marked_for_deletion) do
      create(:project, marked_for_deletion_at: marked_for_deletion_on - 1.day, developers: current_user)
    end

    let(:filters) { { marked_for_deletion_on: marked_for_deletion_on } }

    it 'returns the expected projects' do
      post_graphql(query, current_user: current_user)
      returned_projects = graphql_data_at(*path)

      returned_ids = returned_projects.pluck('id')
      returned_marked_for_deletion_on = returned_projects.pluck('markedForDeletionOn')

      expect(returned_ids).to contain_exactly(
        project_marked_for_deletion.to_global_id.to_s,
        aimed_for_deletion_project.to_global_id.to_s
      )
      expect(returned_marked_for_deletion_on).to contain_exactly(
        project_marked_for_deletion.marked_for_deletion_on.iso8601,
        aimed_for_deletion_project.marked_for_deletion_on.iso8601
      )
    end
  end

  context 'when providing visibility_level filter' do
    let_it_be(:public_project) { create(:project, :public, owners: [current_user]) }
    let_it_be(:private_project) { create(:project, :private, owners: [current_user]) }
    let_it_be(:internal_project) { create(:project, :internal, owners: [current_user]) }

    where :visibility_level, :included_projects, :excluded_projects do
      nil       | [ref(:public_project), ref(:private_project), ref(:internal_project)] | []
      :public   | [ref(:public_project)] | [ref(:private_project), ref(:internal_project)]
      :private  | [ref(:private_project)] | [ref(:public_project), ref(:internal_project)]
      :internal | [ref(:internal_project)] | [ref(:private_project), ref(:public_project)]
    end

    with_them do
      let(:filters) { { visibility_level: } }

      it 'filters projects by visibility level', :aggregate_failures do
        post_graphql(query, current_user: current_user)

        returned_projects = graphql_data_at(*path)
        returned_ids = returned_projects.pluck('id')

        included_project_ids = included_projects.map { |p| p.to_global_id.to_s }
        excluded_project_ids = excluded_projects.map { |p| p.to_global_id.to_s }

        expect(returned_ids).to include(*included_project_ids) if included_project_ids.any?
        expect(returned_ids).not_to include(*excluded_project_ids) if excluded_project_ids.any?
      end
    end
  end

  context 'when providing namespace_path filter' do
    let_it_be(:group) { create(:group, owners: [current_user]) }
    let_it_be(:project) { create(:project, group: group, owners: [current_user]) }

    before do
      post_graphql(query, current_user: current_user)
    end

    subject { graphql_data_at(*path).pluck('id') }

    context 'when `namespace_path` has match' do
      let(:filters) { { namespace_path: group.full_path } }

      it { is_expected.to contain_exactly(project.to_global_id.to_s) }
    end

    context 'when `namespace_path` has no match' do
      let(:filters) { { namespace_path: 'non_existent_path' } }

      it { is_expected.to be_empty }
    end
  end
end
