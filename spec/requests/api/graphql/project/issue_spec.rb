# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Query.project(fullPath).issue(iid)', feature_category: :team_planning do
  include GraphqlHelpers

  let_it_be(:project) { create(:project) }
  let_it_be(:issue) { create(:issue, project: project) }
  let_it_be(:issue_b) { create(:issue, project: project) }
  let_it_be(:developer) { create(:user, developer_of: project) }
  let(:current_user) { developer }

  let_it_be(:project_params) { { 'fullPath' => project.full_path } }
  let_it_be(:issue_params) { { 'iid' => issue.iid.to_s } }
  let_it_be(:issue_fields) { 'title' }

  let(:query) do
    graphql_query_for('project', project_params, project_fields)
  end

  let(:project_fields) do
    query_graphql_field(:issue, issue_params, issue_fields)
  end

  shared_examples 'being able to fetch a design-like object by ID' do
    let(:design) { design_a }
    let(:path) { %w[project issue designCollection] + [GraphqlHelpers.fieldnamerize(object_field_name)] }

    let(:design_fields) do
      [
        :filename,
        query_graphql_field(:project, :id)
      ]
    end

    let(:design_collection_fields) do
      query_graphql_field(object_field_name, object_params, object_fields)
    end

    let(:object_fields) { design_fields }

    context 'the ID is passed' do
      let(:object_params) { { id: global_id_of(object) } }
      let(:result_fields) { {} }

      let(:expected_fields) do
        result_fields.merge({ 'filename' => design.filename, 'project' => id_hash(project) })
      end

      it 'retrieves the object' do
        post_query

        data = graphql_data.dig(*path)

        expect(data).to match(a_hash_including(expected_fields))
      end

      context 'the user is unauthorized' do
        let(:current_user) { create(:user) }

        it_behaves_like 'a failure to find anything'
      end
    end

    context 'without parameters' do
      let(:object_params) { nil }

      it 'raises an error' do
        post_query

        expect(graphql_errors).to include(no_argument_error)
      end
    end

    context 'attempting to retrieve an object from a different issue' do
      let(:object_params) { { id: global_id_of(object_on_other_issue) } }

      it_behaves_like 'a failure to find anything'
    end
  end

  let(:post_query) { post_graphql(query, current_user: current_user) }

  describe '.designCollection' do
    include DesignManagementTestHelpers

    let_it_be(:design_a) { create(:design, issue: issue) }
    let_it_be(:version_a) { create(:design_version, issue: issue, created_designs: [design_a]) }

    let(:issue_fields) do
      query_graphql_field(:design_collection, dc_params, design_collection_fields)
    end

    let(:dc_params) { nil }
    let(:design_collection_fields) { nil }

    before do
      enable_design_management
    end

    describe '.design' do
      let(:object) { design }
      let(:object_field_name) { :design }

      let(:no_argument_error) do
        custom_graphql_error(path, a_string_matching(%r{id or filename}))
      end

      let_it_be(:object_on_other_issue) { create(:design, issue: issue_b) }

      it_behaves_like 'being able to fetch a design-like object by ID'

      it_behaves_like 'being able to fetch a design-like object by ID' do
        let(:object_params) { { filename: design.filename } }
      end
    end

    describe '.version' do
      let(:version) { version_a }
      let(:path) { %w[project issue designCollection version] }

      let(:design_collection_fields) do
        query_graphql_field(:version, version_params, 'id sha')
      end

      context 'no parameters' do
        let(:version_params) { nil }

        it 'raises an error' do
          post_query

          expect(graphql_errors).to include(custom_graphql_error(path, a_string_matching(%r{id or sha})))
        end
      end

      shared_examples 'a successful query for a version' do
        it 'finds the version' do
          post_query

          data = graphql_data.dig(*path)

          expect(data).to match a_graphql_entity_for(version, :sha)
        end
      end

      context '(sha: STRING_TYPE)' do
        let(:version_params) { { sha: version.sha } }

        it_behaves_like 'a successful query for a version'
      end

      context '(id: ID_TYPE)' do
        let(:version_params) { { id: global_id_of(version) } }

        it_behaves_like 'a successful query for a version'
      end
    end

    describe '.designAtVersion' do
      it_behaves_like 'being able to fetch a design-like object by ID' do
        let(:object) { build(:design_at_version, design: design, version: version) }
        let(:object_field_name) { :design_at_version }

        let(:version) { version_a }

        let(:result_fields) { { 'version' => id_hash(version) } }
        let(:object_fields) do
          design_fields + [query_graphql_field(:version, :id)]
        end

        let(:no_argument_error) { missing_required_argument(path, :id) }

        let(:object_on_other_issue) { build(:design_at_version, issue: issue_b) }
      end
    end
  end

  def id_hash(object)
    a_graphql_entity_for(object)
  end
end
