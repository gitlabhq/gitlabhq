# frozen_string_literal: true

require "spec_helper"

RSpec.describe Enums::Sbom, feature_category: :dependency_management do
  using RSpec::Parameterized::TableSyntax

  describe '.purl_types' do
    subject(:actual_purl_type) { described_class.purl_types[package_manager] }

    where(:given_package_manager, :expected_purl_type) do
      :composer             | 1
      'composer'            | 1
      :conan                | 2
      'conan'               | 2
      :gem                  | 3
      :golang               | 4
      :maven                | 5
      :npm                  | 6
      :nuget                | 7
      :pypi                 | 8
      :cargo                | 14
      :apk                  | 9
      :rpm                  | 10
      :deb                  | 11
      'cbl-mariner'         | 12
      :wolfi                | 13
      'unknown-pkg-manager' | 0
      'Python (unknown)'    | 0
      :swift                | 15
      :conda                | 16
    end

    with_them do
      let(:package_manager) { given_package_manager }

      it 'returns the expected purl_type' do
        expect(actual_purl_type).to eql(expected_purl_type)
      end
    end

    it 'contains all of the dependency scanning and container scanning purl types' do
      expect((described_class::DEPENDENCY_SCANNING_PURL_TYPES + described_class::CONTAINER_SCANNING_PURL_TYPES).sort)
        .to eql(described_class::PURL_TYPES.keys.sort)
    end
  end

  describe '.dependency_scanning_purl_type?' do
    where(:purl_type, :expected) do
      :composer  | false
      'composer' | true
      'conan'    | true
      'gem'      | true
      'golang'   | true
      'maven'    | true
      'npm'      | true
      'nuget'    | true
      'pypi'     | true
      'cargo'    | true
      'unknown'  | false
      'apk'      | false
      'rpm'      | false
      'deb'      | false
      'wolfi'    | false
      'swift'    | true
      'conda'    | true
    end

    with_them do
      it 'returns true if the purl_type is for dependency_scanning' do
        actual = described_class.dependency_scanning_purl_type?(purl_type)
        expect(actual).to eql(expected)
      end
    end
  end

  describe '.container_scanning_purl_type?' do
    where(:purl_type, :expected) do
      'composer'    | false
      'conan'       | false
      'gem'         | false
      'golang'      | false
      'maven'       | false
      'npm'         | false
      'nuget'       | false
      'pypi'        | false
      'cargo'       | false
      'unknown'     | false
      :apk          | false
      'apk'         | true
      'rpm'         | true
      'deb'         | true
      'cbl-mariner' | true
      'wolfi'       | true
      :swift        | false
      :conda        | false
    end

    with_them do
      it 'returns true if the purl_type is for container_scanning' do
        actual = described_class.container_scanning_purl_type?(purl_type)
        expect(actual).to eql(expected)
      end
    end
  end
end
