# frozen_string_literal: true
require 'spec_helper'

RSpec.describe 'package details', feature_category: :package_registry do
  include GraphqlHelpers

  let_it_be_with_reload(:group) { create(:group) }
  let_it_be_with_reload(:project) { create(:project, group: group) }
  let_it_be_with_reload(:composer_package) { create(:composer_package, :last_downloaded_at, project: project) }
  let_it_be(:user) { create(:user) }
  let_it_be(:composer_json) { { name: 'name', type: 'type', license: 'license', version: 1 } }
  let_it_be(:composer_metadatum) do
    # we are forced to manually create the metadatum, without using the factory to force the sha to be a string
    # and avoid an error where gitaly can't find the repository
    create(:composer_metadatum, package: composer_package, target_sha: 'foo_sha', composer_json: composer_json)
  end

  let(:depth) { 3 }
  let(:excluded) do
    %w[metadata apiFuzzingCiConfiguration pipeline packageFiles
      runners inboundAllowlistCount groupsAllowlistCount mergeTrains ciJobTokenAuthLogs
      groupAllowlistAutopopulatedIds inboundAllowlistAutopopulatedIds]
  end

  let(:metadata) { query_graphql_fragment('ComposerMetadata') }
  let(:package_files) { all_graphql_fields_for('PackageFile') }
  let(:package_global_id) { global_id_of(composer_package) }
  let(:package_details) { graphql_data_at(:package) }

  let(:query) do
    graphql_query_for(:package, { id: package_global_id }, <<~FIELDS)
    #{all_graphql_fields_for('PackageDetailsType', max_depth: depth, excluded: excluded)}
    metadata {
      #{metadata}
    }
    packageFiles {
      nodes {
        #{package_files}
      }
    }
    FIELDS
  end

  subject { post_graphql(query, current_user: user) }

  context 'when allow_guest_plus_roles_to_pull_packages is disabled' do
    before do
      stub_feature_flags(allow_guest_plus_roles_to_pull_packages: false)
    end

    context 'with unauthorized user' do
      before do
        project.update!(visibility_level: Gitlab::VisibilityLevel::PRIVATE)
        project.add_guest(user)
      end

      it 'returns no packages' do
        subject

        expect(graphql_data_at(:package)).to be_nil
      end

      context 'with access to package registry for everyone' do
        before do
          project.project_feature.update!(package_registry_access_level: ProjectFeature::PUBLIC)
          subject
        end

        it_behaves_like 'a working graphql query' do
          it 'matches the JSON schema' do
            expect(package_details).to match_schema('graphql/packages/package_details')
          end
        end

        it '`public_package` returns true' do
          expect(graphql_data_at(:package, :public_package)).to eq(true)
        end
      end
    end
  end

  context 'when project is public' do
    let_it_be(:public_project) { create(:project, :public, group: group) }
    let_it_be(:composer_package) { create(:composer_package, project: public_project) }
    let(:package_global_id) { global_id_of(composer_package) }

    before do
      subject
    end

    it_behaves_like 'a working graphql query' do
      before do
        subject
      end

      it 'matches the JSON schema' do
        expect(package_details).to match_schema('graphql/packages/package_details')
      end
    end

    it '`public_package` returns true' do
      expect(graphql_data_at(:package, :public_package)).to eq(true)
    end
  end

  context 'with authorized user' do
    before do
      project.add_developer(user)
    end

    it_behaves_like 'a working graphql query' do
      before do
        subject
      end

      it 'matches the JSON schema' do
        expect(package_details).to match_schema('graphql/packages/package_details')
      end
    end

    context 'with package without last_downloaded_at' do
      before do
        composer_package.update!(last_downloaded_at: nil)
        subject
      end

      it 'matches the JSON schema' do
        expect(package_details).to match_schema('graphql/packages/package_details')
      end
    end

    context 'with package files pending destruction' do
      let_it_be(:package_file) { create(:package_file, package: composer_package) }
      let_it_be(:package_file_pending_destruction) { create(:package_file, :pending_destruction, package: composer_package) }

      let(:package_file_ids) { graphql_data_at(:package, :package_files, :nodes).map { |node| node["id"] } }

      it 'does not return them' do
        subject

        expect(package_file_ids).to contain_exactly(package_file.to_global_id.to_s)
      end
    end

    context 'with a batched query' do
      let_it_be(:conan_package) { create(:conan_package, project: project) }

      let(:batch_query) do
        <<~QUERY
        {
          a: package(id: "#{global_id_of(composer_package)}") { name }
          b: package(id: "#{global_id_of(conan_package)}") { name }
        }
        QUERY
      end

      let(:a_packages_names) { graphql_data_at(:a, :packages, :nodes, :name) }

      it 'returns an error for the second package and data for the first' do
        post_graphql(batch_query, current_user: user)

        expect(graphql_data_at(:a, :name)).to eq(composer_package.name)

        expect_graphql_errors_to_include [/"package" field can be requested only for 1 Query\(s\) at a time./]
        expect(graphql_data_at(:b)).to be_nil
      end
    end

    context 'versions field', :aggregate_failures do
      let_it_be(:composer_package2) { create(:composer_package, project: project, name: composer_package.name) }
      let_it_be(:composer_package3) { create(:composer_package, :error, project: project, name: composer_package.name) }
      let_it_be(:pending_destruction) { create(:composer_package, :pending_destruction, project: project, name: composer_package.name) }

      def run_query
        versions_nodes = <<~QUERY
        nodes { id }
        QUERY

        query = graphql_query_for(:package, { id: package_global_id }, query_graphql_field("versions", {}, versions_nodes))
        post_graphql(query, current_user: user)
      end

      it 'returns other versions' do
        run_query
        versions_ids = graphql_data.dig('package', 'versions', 'nodes').pluck('id')
        expected_ids = [composer_package2, composer_package3].map(&:to_gid).map(&:to_s)

        expect(versions_ids).to contain_exactly(*expected_ids)
      end
    end

    context 'pipelines field', :aggregate_failures do
      let(:pipelines) { create_list(:ci_pipeline, 6, project: project) }
      let(:pipeline_gids) { pipelines.sort_by(&:id).map(&:to_gid).map(&:to_s).reverse }

      before do
        pipelines.each do |pipeline|
          create(:package_build_info, package: composer_package, pipeline: pipeline)
        end
      end

      def run_query(args)
        pipelines_nodes = <<~QUERY
        nodes {
          id
        }
        pageInfo {
          startCursor
          endCursor
        }
        QUERY

        query = graphql_query_for(:package, { id: package_global_id }, query_graphql_field("pipelines", args, pipelines_nodes))
        post_graphql(query, current_user: user)
      end

      it 'loads the second page with pagination first correctly' do
        run_query(first: 2)
        pipeline_ids = graphql_data.dig('package', 'pipelines', 'nodes').pluck('id')

        expect(pipeline_ids).to eq(pipeline_gids[0..1])

        cursor = graphql_data.dig('package', 'pipelines', 'pageInfo', 'endCursor')

        run_query(first: 2, after: cursor)

        pipeline_ids = graphql_data.dig('package', 'pipelines', 'nodes').pluck('id')

        expect(pipeline_ids).to eq(pipeline_gids[2..3])
      end

      it 'loads the second page with pagination last correctly' do
        run_query(last: 2)
        pipeline_ids = graphql_data.dig('package', 'pipelines', 'nodes').pluck('id')

        expect(pipeline_ids).to eq(pipeline_gids[4..5])

        cursor = graphql_data.dig('package', 'pipelines', 'pageInfo', 'startCursor')

        run_query(last: 2, before: cursor)

        pipeline_ids = graphql_data.dig('package', 'pipelines', 'nodes').pluck('id')

        expect(pipeline_ids).to eq(pipeline_gids[2..3])
      end
    end

    context 'package managers paths' do
      before do
        subject
      end

      it 'returns npm_url correctly' do
        expect(graphql_data_at(:package, :npm_url)).to eq("http://localhost/api/v4/projects/#{project.id}/packages/npm")
      end

      it 'returns maven_url correctly' do
        expect(graphql_data_at(:package, :maven_url)).to eq("http://localhost/api/v4/projects/#{project.id}/packages/maven")
      end

      it 'returns conan_url correctly' do
        expect(graphql_data_at(:package, :conan_url)).to eq("http://localhost/api/v4/projects/#{project.id}/packages/conan")
      end

      it 'returns nuget_url correctly' do
        expect(graphql_data_at(:package, :nuget_url)).to eq("http://localhost/api/v4/projects/#{project.id}/packages/nuget/index.json")
      end

      it 'returns pypi_url correctly' do
        expect(graphql_data_at(:package, :pypi_url)).to eq("http://__token__:<your_personal_token>@localhost/api/v4/projects/#{project.id}/packages/pypi/simple")
      end

      it 'returns pypi_setup_url correctly' do
        expect(graphql_data_at(:package, :pypi_setup_url)).to eq("http://localhost/api/v4/projects/#{project.id}/packages/pypi")
      end

      it 'returns composer_url correctly' do
        expect(graphql_data_at(:package, :composer_url)).to eq("http://localhost/api/v4/group/#{group.id}/-/packages/composer/packages.json")
      end

      it 'returns composer_config_repository_url correctly' do
        expect(graphql_data_at(:package, :composer_config_repository_url)).to eq("localhost/#{group.id}")
      end

      context 'with access to package registry for everyone' do
        before do
          project.project_feature.update!(package_registry_access_level: ProjectFeature::PUBLIC)
          subject
        end

        it 'returns pypi_url correctly' do
          expect(graphql_data_at(:package, :pypi_url)).to eq("http://__token__:<your_personal_token>@localhost/api/v4/projects/#{project.id}/packages/pypi/simple")
        end
      end

      context 'when project is public' do
        let_it_be(:public_project) { create(:project, :public, group: group) }
        let_it_be(:composer_package) { create(:composer_package, project: public_project) }
        let(:package_global_id) { global_id_of(composer_package) }

        before do
          subject
        end

        it 'returns pypi_url correctly' do
          expect(graphql_data_at(:package, :pypi_url)).to eq("http://localhost/api/v4/projects/#{public_project.id}/packages/pypi/simple")
        end
      end
    end

    context 'web_path' do
      shared_examples 'return web_path correctly' do
        it 'returns web_path correctly' do
          expect(graphql_data_at(:package, :_links, :web_path)).to eq("/#{project.full_path}/-/packages/#{composer_package.id}")
        end
      end

      context 'with status default' do
        before do
          subject
        end

        it_behaves_like 'return web_path correctly'

        context 'with terraform module' do
          let_it_be(:terraform_package) { create(:terraform_module_package, project: project) }

          let(:package_global_id) { global_id_of(terraform_package) }

          it 'returns web_path correctly' do
            expect(graphql_data_at(:package, :_links, :web_path)).to eq("/#{project.full_path}/-/terraform_module_registry/#{terraform_package.id}")
          end
        end
      end

      context 'with status deprecated' do
        before do
          composer_package.deprecated!

          subject
        end

        it_behaves_like 'return web_path correctly'
      end
    end

    context 'public_package' do
      context 'when project is private' do
        let_it_be(:private_project) { create(:project, :private, group: group) }
        let_it_be(:composer_package) { create(:composer_package, project: private_project) }
        let(:package_global_id) { global_id_of(composer_package) }

        before do
          private_project.add_developer(user)
        end

        it 'returns false' do
          subject

          expect(graphql_data_at(:package, :public_package)).to eq(false)
        end

        context 'with access to package registry for everyone' do
          before do
            private_project.project_feature.update!(package_registry_access_level: ProjectFeature::PUBLIC)
            subject
          end

          it 'returns true' do
            expect(graphql_data_at(:package, :public_package)).to eq(true)
          end
        end
      end

      context 'when project is public' do
        let_it_be(:public_project) { create(:project, :public, group: group) }
        let_it_be(:composer_package) { create(:composer_package, project: public_project) }
        let(:package_global_id) { global_id_of(composer_package) }

        before do
          subject
        end

        it 'returns true' do
          expect(graphql_data_at(:package, :public_package)).to eq(true)
        end
      end
    end

    context 'with package that has no default status' do
      before do
        composer_package.update!(status: :error)
        subject
      end

      it "does not return package's details" do
        expect(package_details).to be_nil
      end
    end
  end
end
