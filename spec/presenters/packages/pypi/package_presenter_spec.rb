# frozen_string_literal: true

require 'spec_helper'

RSpec.describe ::Packages::Pypi::PackagePresenter do
  using RSpec::Parameterized::TableSyntax

  let_it_be(:group) { create(:group) }
  let_it_be(:project) { create(:project, group: group) }
  let_it_be(:package_name) { 'sample-project' }
  let_it_be(:package1) { create(:pypi_package, project: project, name: package_name, version: '1.0.0') }
  let_it_be(:package2) { create(:pypi_package, project: project, name: package_name, version: '2.0.0') }

  let(:packages) { [package1, package2] }

  let(:file) { package.package_files.first }
  let(:filename) { file.file_name }

  subject(:presenter) { described_class.new(packages, project_or_group).body}

  describe '#body' do
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
          package.pypi_metadatum.required_python = python_version
        end

        it { is_expected.to include expected_file }
      end
    end

    context 'for project' do
      let(:project_or_group) { project }
      let(:expected_file) { "<a href=\"http://localhost/api/v4/projects/#{project.id}/packages/pypi/files/#{file.file_sha256}/#{filename}#sha256=#{file.file_sha256}\" data-requires-python=\"#{expected_python_version}\">#{filename}</a><br>" }

      it_behaves_like 'pypi package presenter'
    end

    context 'for group' do
      let(:project_or_group) { group }
      let(:expected_file) { "<a href=\"http://localhost/api/v4/groups/#{group.id}/-/packages/pypi/files/#{file.file_sha256}/#{filename}#sha256=#{file.file_sha256}\" data-requires-python=\"#{expected_python_version}\">#{filename}</a><br>" }

      it_behaves_like 'pypi package presenter'
    end
  end
end
