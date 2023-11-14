# frozen_string_literal: true

require "spec_helper"

RSpec.describe Sbom::PurlType::Converter, feature_category: :dependency_management do
  describe '.purl_type_for_pkg_manager' do
    using RSpec::Parameterized::TableSyntax

    subject(:actual_purl_type) { described_class.purl_type_for_pkg_manager(package_manager) }

    where(:given_package_manager, :expected_purl_type) do
      'bundler'             | 'gem'
      'yarn'                | 'npm'
      'npm'                 | 'npm'
      'pnpm'                | 'npm'
      'maven'               | 'maven'
      'sbt'                 | 'maven'
      'gradle'              | 'maven'
      'composer'            | 'composer'
      'conan'               | 'conan'
      'go'                  | 'golang'
      'nuget'               | 'nuget'
      'pip'                 | 'pypi'
      'pipenv'              | 'pypi'
      'poetry'              | 'pypi'
      'setuptools'          | 'pypi'
      'Python (python-pkg)' | 'pypi'
      'analyzer (gobinary)' | 'golang'
      'unknown-pkg-manager' | nil
      'Python (unknown)'    | nil
    end

    with_them do
      let(:package_manager) { given_package_manager }

      it 'returns the expected purl_type' do
        expect(actual_purl_type).to eql(expected_purl_type)
      end
    end
  end
end
