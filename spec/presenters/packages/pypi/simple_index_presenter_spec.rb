# frozen_string_literal: true

require 'spec_helper'

RSpec.describe ::Packages::Pypi::SimpleIndexPresenter, :aggregate_failures, feature_category: :package_registry do
  using RSpec::Parameterized::TableSyntax

  let_it_be(:group) { create(:group) }
  let_it_be(:project) { create(:project, group: group) }
  let_it_be(:package_name) { 'sample-project' }
  let_it_be(:package1) { create(:pypi_package, project: project, name: package_name, version: '1.0.0') }
  let_it_be(:package2) { create(:pypi_package, project: project, name: package_name, version: '2.0.0') }

  let(:packages) { Packages::Pypi::Package.for_projects(project) }

  describe '#body' do
    subject(:presenter) { described_class.new(packages, project_or_group).body }

    shared_examples_for "pypi package presenter" do
      where(:version, :expected_version) do
        '>=2.7'                        | '&gt;=2.7'
        '"><script>alert(1)</script>'  | '&quot;&gt;&lt;script&gt;alert(1)&lt;/script&gt;'
        '>=2.7, !=3.0'                 | '&gt;=2.7, !=3.0'
      end

      with_them do
        let(:python_version) { version }
        let(:expected_python_version) { expected_version }

        before do
          package1.pypi_metadatum.update_column(:required_python, python_version)
          package2.pypi_metadatum.update_column(:required_python, '')
        end

        it 'contains links for all packages' do
          expect(presenter).to include(expected_link1)
          expect(presenter).to include(expected_link2)
        end
      end

      it 'strips leading whitespace from the output' do
        expect(presenter.first).not_to eq(' ')
      end

      it 'avoids n+1 database queries', :use_sql_query_cache do
        control = ActiveRecord::QueryRecorder.new(skip_cached: false) do
          described_class.new(Packages::Pypi::Package.for_projects(project).reload, project_or_group).body
        end

        create_list(:pypi_package, 5, project: project)

        expect { described_class.new(Packages::Pypi::Package.for_projects(project).reload, project_or_group).body }
          .to issue_same_number_of_queries_as(control)
      end
    end

    context 'for project' do
      let(:project_or_group) { project }
      let(:expected_link1) { "<a href=\"http://localhost/api/v4/projects/#{project.id}/packages/pypi/simple/#{package1.normalized_pypi_name}\" data-requires-python=\"#{expected_python_version}\">#{package1.name}</a>" }
      let(:expected_link2) { "<a href=\"http://localhost/api/v4/projects/#{project.id}/packages/pypi/simple/#{package2.normalized_pypi_name}\" data-requires-python=\"\">#{package2.name}</a>" }

      it_behaves_like 'pypi package presenter'
    end

    context 'for group' do
      let(:project_or_group) { group }
      let(:expected_link1) { "<a href=\"http://localhost/api/v4/groups/#{group.id}/-/packages/pypi/simple/#{package1.normalized_pypi_name}\" data-requires-python=\"#{expected_python_version}\">#{package1.name}</a>" }
      let(:expected_link2) { "<a href=\"http://localhost/api/v4/groups/#{group.id}/-/packages/pypi/simple/#{package2.normalized_pypi_name}\" data-requires-python=\"\">#{package2.name}</a>" }

      it_behaves_like 'pypi package presenter'
    end

    context 'with package files pending destruction' do
      let_it_be(:package_pending_destruction) do
        create(:pypi_package, :pending_destruction, project: project, name: 'package_pending_destruction')
      end

      let(:project_or_group) { project }

      it { is_expected.not_to include(package_pending_destruction.name) }
    end
  end
end
