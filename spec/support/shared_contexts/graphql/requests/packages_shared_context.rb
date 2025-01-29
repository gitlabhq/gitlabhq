# frozen_string_literal: true

RSpec.shared_context 'package details setup' do
  let_it_be(:project) { create(:project) }
  let_it_be(:package) { create(:generic_package, project: project) }

  let(:package_global_id) { global_id_of(package) }

  let(:depth) { 3 }
  let(:excluded) { %w[metadata apiFuzzingCiConfiguration pipeline packageFiles mergeTrains] }
  let(:package_files) { all_graphql_fields_for('PackageFile') }
  let(:dependency_links) { all_graphql_fields_for('PackageDependencyLink') }
  let(:pipelines) { all_graphql_fields_for('Pipeline', max_depth: 1) }
  let(:user) { project.first_owner }
  let(:package_details) { graphql_data_at(:package) }
  let(:metadata_response) { graphql_data_at(:package, :metadata) }
  let(:first_file) { package.package_files.find { |f| a_graphql_entity_for(f).matches?(first_file_response) } }
  let(:package_files_response) { graphql_data_at(:package, :package_files, :nodes) }
  let(:first_file_response) { graphql_data_at(:package, :package_files, :nodes, 0) }
  let(:first_file_response_metadata) { graphql_data_at(:package, :package_files, :nodes, 0, :file_metadata) }

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
    dependencyLinks {
      nodes {
        #{dependency_links}
      }
    }
    pipelines {
      nodes {
        #{pipelines}
      }
    }
    FIELDS
  end
end
