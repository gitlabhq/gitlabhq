# frozen_string_literal: true

require 'spec_helper'

RSpec.describe ::Packages::Pypi::SimplePackageVersionsJsonPresenter, :aggregate_failures, feature_category: :package_registry do
  using RSpec::Parameterized::TableSyntax

  # Relations + associations require persisted records.
  # rubocop:disable RSpec/FactoryBot/AvoidCreate -- Presenter operates on AR relations and loads associated records.
  let_it_be(:group) { create(:group) }
  let_it_be(:project) { create(:project, group: group) }
  let_it_be(:package_name) { 'sample-project' }
  let_it_be(:package1) { create(:pypi_package, project: project, name: package_name, version: '1.0.0') }
  let_it_be(:package2) { create(:pypi_package, project: project, name: package_name, version: '2.0.0') }

  # Ensure we have at least one file to assert on (do not rely on factory side effects).
  let_it_be(:package_file1) { create(:package_file, package: package1) }
  # rubocop:enable RSpec/FactoryBot/AvoidCreate

  let(:packages) { Packages::Pypi::Package.for_projects(project).with_name(package_name) }

  describe '#body' do
    subject(:presenter) { described_class.new(packages, project_or_group, package_name: package_name).body }

    def parsed_json
      Gitlab::Json.safe_parse(presenter)
    end

    shared_examples_for "pypi package presenter" do
      where(:version, :expected_version, :with_package1) do
        '>=2.7'                        | '&gt;=2.7'                                        | true
        '"><script>alert(1)</script>'  | '&quot;&gt;&lt;script&gt;alert(1)&lt;/script&gt;' | true
        '>=2.7, !=3.0'                 | '&gt;=2.7, !=3.0'                                 | false
      end

      with_them do
        let(:python_version) { version }
        let(:expected_python_version) { expected_version }
        let(:package) { with_package1 ? package1 : package2 }

        before do
          package.pypi_metadatum.update_column(:required_python, python_version)
        end

        it 'returns PEP 691 JSON with file entries' do
          json = parsed_json

          expect(json['meta']).to include('api-version' => described_class::API_VERSION)
          expect(json['name']).to eq(package.normalized_pypi_name)

          expect(json['files']).to be_an(Array)
          expect(json['files']).not_to be_empty

          first = json['files'].first
          expect(first).to include('filename', 'url', 'hashes')
          expect(first['hashes']).to include('sha256')
          expect(first['url']).to include('#sha256=')
        end

        it 'builds URLs for the correct target (project/group)' do
          json = parsed_json
          url = json['files'].first['url']

          expected_prefix =
            if project_or_group.is_a?(Project)
              "/api/v4/projects/#{project.id}/packages/pypi/files/"
            else
              "/api/v4/groups/#{group.id}/-/packages/pypi/files/"
            end

          expect(url).to include(expected_prefix)
        end
      end

      it 'avoids N+1 database queries' do
        control = ActiveRecord::QueryRecorder.new do
          described_class.new(packages, project_or_group, package_name: package_name).body
        end

        # rubocop:disable RSpec/FactoryBot/AvoidCreate -- Creating records is required to validate query count.
        create(:pypi_package, project: project, name: package_name)
        # rubocop:enable RSpec/FactoryBot/AvoidCreate

        expect do
          described_class.new(Packages::Pypi::Package.for_projects(project).with_name(package_name), project_or_group,
            package_name: package_name).body
        end.not_to exceed_query_limit(control)
      end
    end

    context 'for project' do
      let(:project_or_group) { project }

      it_behaves_like 'pypi package presenter'
    end

    context 'for group' do
      let(:project_or_group) { group }

      it_behaves_like 'pypi package presenter'
    end

    context 'with package files pending destruction' do
      # rubocop:disable RSpec/FactoryBot/AvoidCreate -- Needs persisted file record with pending_destruction state.
      let_it_be(:package_file_pending_destruction) do
        create(:package_file, :pending_destruction, package: package1, file_name: 'package_file_pending_destruction')
      end
      # rubocop:enable RSpec/FactoryBot/AvoidCreate

      let(:project_or_group) { project }

      it 'does not include pending destruction files' do
        filenames = Gitlab::Json.safe_parse(presenter)['files'].pluck('filename')
        expect(filenames).not_to include(package_file_pending_destruction.file_name)
      end
    end
  end
end
