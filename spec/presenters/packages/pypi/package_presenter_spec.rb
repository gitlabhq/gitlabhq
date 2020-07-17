# frozen_string_literal: true

require 'spec_helper'

RSpec.describe ::Packages::Pypi::PackagePresenter do
  using RSpec::Parameterized::TableSyntax

  let_it_be(:project) { create(:project) }
  let_it_be(:package_name) { 'sample-project' }
  let_it_be(:package1) { create(:pypi_package, project: project, name: package_name, version: '1.0.0') }
  let_it_be(:package2) { create(:pypi_package, project: project, name: package_name, version: '2.0.0') }

  let(:packages) { [package1, package2] }
  let(:presenter) { described_class.new(packages, project) }

  describe '#body' do
    subject { presenter.body}

    shared_examples_for "pypi package presenter" do
      let(:file) { package.package_files.first }
      let(:filename) { file.file_name }
      let(:expected_file) { "<a href=\"http://localhost/api/v4/projects/#{project.id}/packages/pypi/files/#{file.file_sha256}/#{filename}#sha256=#{file.file_sha256}\" data-requires-python=\"#{expected_python_version}\">#{filename}</a><br>" }

      before do
        package.pypi_metadatum.required_python = python_version
      end

      it { is_expected.to include expected_file }
    end

    it_behaves_like "pypi package presenter" do
      let(:python_version) { '>=2.7' }
      let(:expected_python_version) { '&gt;=2.7' }
      let(:package) { package1 }
    end

    it_behaves_like "pypi package presenter" do
      let(:python_version) { '"><script>alert(1)</script>' }
      let(:expected_python_version) { '&quot;&gt;&lt;script&gt;alert(1)&lt;/script&gt;' }
      let(:package) { package1 }
    end

    it_behaves_like "pypi package presenter" do
      let(:python_version) { '>=2.7, !=3.0' }
      let(:expected_python_version) { '&gt;=2.7, !=3.0' }
      let(:package) { package2 }
    end
  end
end
